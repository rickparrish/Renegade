{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}
Unit Rg_Scan;
INTERFACE
{
Code: 759
Data: 8
}
uses
  dos, overlay, commdec, Common, Rg_Obj, Rg_Ofile;
{$DEFINE Beta}

TYPE
  MsgScanListObj=Object(Rgobj)
    ScanFile:pRgFileObj;
    fName:aStr;

    CurrentData:Boolean;  { holds data read from base }
    CurrentUser:Word;     { Where are we at }
    CurrentBase:Word;     { Current base }
    UserCount:Word;       { number of users in file MINUS the dummy at 0 }

    Constructor Init;
    Destructor  Done;

    Procedure SelectUser(Which:Word);
              { Picks em out of thousands! }
    Procedure SelectBase(const Which:aStr);
              { Which actual base }
    Procedure ExpandFile;
              { Expands file one user }
    Procedure ContractFile;
              { Truncates one user from END of file }
    Procedure ResetFile;
              { Performs a RESET of file, JIC is needed }
    Procedure ClearUser;
              { Cleans current user to defaults }

    Procedure ToggleBase;
              { Toggles state of base for current user }

    Function  HasFlag:Boolean;
    Procedure SetFlag(State:Boolean);
              { Set flag state }

    Procedure GetUserCount;
  end;
  pMsgScanListObj=^MsgScanListObj;

IMPLEMENTATION

Constructor MsgScanListObj.Init;
Begin
  Inherited Init;

  New(ScanFile, Init(1));
  if ScanFile=NIL then Fail;

  CurrentData := TRUE;
  CurrentBase := 0;
  SelectUser(1);
End;

Destructor  MsgScanListObj.Done;
Begin
  Dispose(ScanFile, Done);
End;

Procedure MsgScanListObj.GetUserCount;
begin
  UserCount := ScanFile^.FileSize;
  if UserCount > 0 then
    Dec(UserCount);
end;

Procedure MsgScanListObj.SelectUser(Which:Word);
Begin
  { slot 0 is empty }
  CurrentUser := Which;
End;

Procedure MsgScanListObj.SelectBase(const Which:aStr);
begin
  fName := Which;
  ScanFile^.Assign(FName);

  if Exist(fName) then
    ScanFile^.Reset
  else
    ScanFile^.Rewrite;

  GetUserCount;
  If UserCount = 0 then
    ExpandFile;
end;

Procedure MsgScanListObj.ExpandFile;
Begin
  ScanFile^.ExpandFile(1);
  GetUserCount;
End;

Procedure MsgScanListObj.ContractFile;
Begin
  ScanFile^.Contract(1);
  GetUserCount;
End;

Procedure MsgScanListObj.ResetFile;
begin
  ScanFile^.Reset;
end;

Procedure MsgScanListObj.ClearUser;
Var T:Boolean;
Begin
  T := TRUE;
  ScanFile^.seek(CurrentUser);
  ScanFile^.Write(T);
End;

Procedure MsgScanListObj.ToggleBase;
Begin
  if HasFlag then
    SetFlag(FALSE)
  else
    SetFlag(TRUE);
End;

Function  MsgScanListObj.HasFlag:Boolean;
Begin
  with ScanFile^ do
  begin
    Seek(CurrentUser);
    Read(CurrentData);
  end;
  HasFlag := CurrentData;
End;

Procedure MsgScanListObj.SetFlag(State:Boolean);
Begin
  with ScanFile^ do
  begin
    Seek(CurrentUser);
    write(State);
  end;
End;

begin
end.
