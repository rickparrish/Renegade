{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}
Unit Rg_Idx;
{
Code: 1106
Data: 8
}
INTERFACE
uses
  dos, overlay, rg_obj, CommDec, rg_ofile;

TYPE
  IdxRec=Record
    Position:LongInt;   { Where in data file the user/item is }
  end;

TYPE
  IndexObject=Object(RgObj)
    F:RgShareFileObj;
    Data:IdxRec;

    Constructor Init(PathName:Str40);
    Destructor  Done;

    Procedure NewFile;
              { Makes a new file with record 0 }
    Function  WhereIs(Who:Word):word;
              { returns position in data file of user/item indexed }
    Function  FindUser(Where:Word):word;
              { Returns user/item number from index position }
    Procedure AddUser;
              { Adds user to end of file }
    Procedure DeleteUser(Which:Word);
              { Deletes user/item from position and moves others down }
    Procedure SetUser(Which, ToWhat:Word);
  end;
  pIndexObject=^IndexObject;

IMPLEMENTATION
uses Common;

Constructor IndexObject.Init(PathName:Str40);
begin
  inherited init;
  FillChar(Data, SizeOf(Data), #0);
  F.Init(SizeOf(IdxRec));
  F.Assign(PathName);
  if not exist (PathName) then
    NewFile;
  F.Reset;
end;

Destructor  IndexObject.Done;
begin
  F.Close;
end;

Procedure IndexObject.NewFile;
begin
  F.Rewrite;
  F.Close;
  AddUser;
end;

Function  IndexObject.WhereIs(Who:Word):word;
          { returns position in data file of user indexed }
begin
  F.Seek(Who);
  F.Read(Data);
  WhereIs := Data.Position;
end;

Procedure IndexObject.AddUser;
          { Adds user to end of file }
begin
  F.Extend(1);
end;

Procedure IndexObject.DeleteUser(Which:Word);
          { Deletes user from position and moves others down }
Var
  Loop:Word;
  T:IdxRec;
begin
  F.Reset;
  if Which > F.FileSize-1 then
  begin
    Exit;
  end;
  if Which = F.FileSize-1 then
  begin
    F.Seek(Which);
    F.Truncate;
  end
  else
  begin
    F.Seek(Which+1);
    For Loop := Which to F.FileSize-1 do
    begin
      F.Seek(Loop);
      F.Read(T);
      F.Seek(Loop-1);
      F.Write(T);
    end;
    F.Seek(F.FileSize);
    F.truncate;
  end;
end;

Procedure IndexObject.SetUser(Which, ToWhat:Word);
begin
  if Which >= F.FileSize then
    F.Extend(Which-F.FileSize);
  F.Seek(Which);
  Data.Position := ToWhat;
  F.Write(Data);
end;

Function  IndexObject.FindUser(Where:Word):word;
          { Returns user number from index position }
Var
  Found:Boolean;
begin
  Found := False;
  While not(F.Eof) and not(Found) do
  begin
    F.Read(Data);
    if Data.Position = Where then
      Found := True;
  end;
  if Found then
    FindUser := Data.Position
  else
    FindUser := 0;
end;


Begin
End.
