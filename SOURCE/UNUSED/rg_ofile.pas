{$A-,B-,D-,E-,F+,G+,I-,L-,N-,O+,P+,Q-,R-,S-,T-,V-,X+}
unit Rg_OFile;
{
Code: 2759
Data: 52
}
INTERFACE
uses
  dos, Objects,
  Rg_Obj,
  CommDec,
  BCShare;


Type
  BufType=array[1..65535] of char;
  pBuf = ^BufType;

TYPE
  RgFileObj=object(rgobj)
    blocksize:word;           { Block Size of data, Must pass at least 1 }
    FSize:LongInt;            { Size of file after FileSize call }
    Result:word;              { Amount actually read }
    IoRes:Word;               { IoResult Value }
    IsOpen:Boolean;           { is file open? }
    Attr:Word;                { File attributes - retrieved auto }

    FileName:Str120;          { Name of current file }
    Fil:File;                 { Generic File }
    Accesserror:Boolean;      { TRUE if CheckIo is what sets Not OK }
    Data:pBuf;                { Scratch variable }

    Constructor Init(L:LongInt);
    Destructor  Done;
    Procedure   CheckIo;      { Checks IoResult, Sets IoRes }

    Procedure ExpandFile(Quantity:LongInt);
              { Extends size of fil by Quantity amount of records }
              { Returns Not OK if not able to allocate memory or if error }
    Procedure Contract(Quantity:LongInt);
              { Shrinks file by Quantity amount of records }
              { will not do any operations if Quantity is > filesize }
    Procedure Assign(const FilName:Str255);
    Procedure BlockRead(Var Buf; Amt:Word);   Virtual;
              { Reads Amt from Fil into Buf }
    Procedure BlockWrite(Var Buf; Amt:Word);  Virtual;
              { Writes Amt from Buf into Fil }
    Procedure Read(Var Buf);
              { Reads blocksize into Buf from Fil }
    Procedure Write(Var buf);
              { Writes blocksize into Fil from Buf }

    Procedure Close;
    Function  EOF:Boolean;
    Procedure Erase;
    Function  FilePos:LongInt;
    Function  RealFilePos:LongInt;
    Function  FileSize:LongInt;
    Function  RealFileSize:LongInt;
    Procedure Reset; virtual;
    Procedure Rewrite; virtual;
    Procedure ResetMake;
              { Resets file if it exists, else rewrites file }

    Procedure Seek(Where:LongInt);
              { Goes to Where in Fil, Units of blocksize}
    Procedure RealSeek(Where:LongInt);
              { Goes to Where if Fil, Absolute coords }
    procedure Truncate;
              { Truncates file at current pos (at begining of data block) }

    Procedure GetFAttr(Atr:word);
    Procedure SetFAttr(Atr:word);
              { Sets File attribute, WILL CLOSE FILE! }
    Procedure GetFTime(Time:LongInt);
    Procedure SetFTime(Time:LongInt);
              { Sets file time, File MUST BE OPEN! }
    Function  HasfAttr(Which:Word):boolean;
    Function  FileOpen:Boolean;
              { TRUE if File is open }

    Procedure MoveRecord(FromWhere, ToWhere:LongInt);
              { Moves record to pos, overwriting dest and deleting orig }
    Procedure MoveInsertRecord(FromWhere, BeforeWhere:LongInt);
              { Moves FromWhere to BeforeWhere and dels orig }
    Procedure CopyRecord(FromWhere, ToWhere:LongInt);
              { Copies from orig to dest, leave orig }
    Procedure CopyInsertRecord(FromWhere, BeforeWhere:LongInt);
              { inserts blank and copies to pos }
    Procedure SwapRecord(R1, R2:LongInt);
              { Swaps two records }
    Procedure DeleteRecord(FromWhere:LongInt);
              { Deletes record and packs file }
              { at later date can override and add free list pointers }
    Procedure ClearRecord(Where:LongInt);
              { Blanks record }
    Procedure InsertRecord(BeforeWhere:LongInt);
              { Insert blank record before specified record }
    Procedure InsertRecords(BeforeWhere:LongInt; Quantity:Word);
              { Inserts n amount of blank records before specified record }

  end;
  pRgFileObj=^RgFileObj;


TYPE
  pRgShareFileObj=^RgShareFileObj;
  RgShareFileObj=Object(RgFileObj)
    ShareMode      { Set to FALSE to NOT lock file }
      :boolean;
    FilMode:Byte;
    LoopCount:Word;
    DelayAmt:word;  { How long to wait before next access attempt }

    Constructor Init(L:LongInt);
    Destructor  Done; virtual;

    Procedure Reset; virtual;
    Procedure Rewrite; virtual;

    Procedure SetFileMode(Mde:Byte);
              { Actually sets file mode }
    Procedure DefaultFileMode(Mde:Byte);
    Procedure BlockWrite(Var Buf; Count:Word); Virtual;

    Procedure SetLoopCount(ToWhat:Word); { Defaults to 5 }
              { Sets the looping retry on  }
    Procedure SetDelayAmt(ToWhat:Word);  { Defaults to 20 }
              { Sets the delay for the delay() loop on file lock/write }
  end;


IMPLEMENTATION

Uses Crt, Common;

(*
function exist(const fn:str255):boolean;
var srec:searchrec;
begin
	findfirst(fn,anyfile,srec);
	exist:=(doserror=0);
end;
*)


{
-----------------------------------------------------
-----------------------------------------------------[RgFileObject]---
-----------------------------------------------------
}
Constructor RgFileObj.Init(L:LongInt);
begin
  inherited init;
  blocksize := L;
  if blocksize = 0 then
    blocksize := 1;
  FSize := 0;
  Result := 0;
  IoRes := 0;
  IsOpen := FALSE;
  Attr := 0;
  FileName := '';
  Accesserror := FALSE;
  GetMem(Data, blocksize);
  if Data=NIL then
    fail;
end;

Destructor  RgFileObj.Done;
begin
  FreeMem(Data,blocksize);
  If (IsOpen) and (Ok) then Close;
end;

Procedure RgFileObj.ExpandFile(Quantity:LongInt);
          { Extends size of fil by Quantity amount of records }
VAR
  Loop:LongInt;
  Loop2:word;
begin
  If Ok then
  begin
    Fillchar(Data^, blocksize, #0);
    Seek(FileSize);
    For Loop := 1 to Quantity do
    begin
      Write(Data^);
    end;
  end;
end;

Procedure RgFileObj.Contract(Quantity:LongInt);
          { Shrinks file by Quantity amount of records }
          { will not do any operations if Quantity is > filesize }
begin
  if Quantity > FileSize then
    exit;
  Seek(FileSize-quantity);
  truncate;
end;

Procedure RgFileObj.Assign(const FilName:Str255);
begin
  system.assign(Fil, FilName);
  GetFAttr(Attr);
end;

Procedure RgFileObj.CheckIo;      { Checks IoResult, Sets IoRes }
begin
  IoRes := IoResult;
  if (IoRes <> 0) then
  begin
    SetOk(FALSE);
    Accesserror := FALSE;
  end;
end;

Procedure RgFileObj.BlockRead(Var Buf; Amt:Word);          { Reads Amt from Fil into Buf }
begin
  System.BlockRead(Fil, Buf, Amt, Result);
  CheckIo;
end;

Procedure RgFileObj.BlockWrite(Var Buf; Amt:Word);          { Writes Amt from Buf into Fil }
begin
  System.BlockWrite(Fil, Buf, Amt, Result);
  CheckIo;
end;

Procedure RgFileObj.Read(Var Buf);          { Reads blocksize into Buf from Fil }
begin
  BlockRead(Buf, blocksize);
end;

Procedure RgFileObj.Write(Var buf);          { Writes blocksize into Fil from Buf }
begin
  BlockWrite(Buf, blocksize);
end;

Procedure RgFileObj.Close;
begin
  If IsOpen then
  begin
    IsOpen := FALSE;
    System.Close(Fil);
    CheckIo;
  end;
end;

Function  RgFileObj.EOF:Boolean;
begin
  Eof := System.Eof(Fil);
  CheckIo;
end;

Procedure RgFileObj.Erase;
VAR
  F:File;
begin
  Close;
  if Exist(FileName) then
  begin
    assign(FileName);
    System.Erase(Fil);
  end;
  CheckIo;
end;

Function  RgFileObj.FilePos:LongInt;
Var T:LongInt;
begin
  T := System.FilePos(Fil);
  CheckIo;
  FilePos := T div blocksize;
end;

Function  RgFileObj.RealFilePos:LongInt;
var T:LongInt;
begin
  RealFilePos := System.FilePos(Fil);
  CheckIo;
end;

Function  RgFileObj.FileSize:LongInt;
begin
  FSize := System.FileSize(Fil);
  CheckIo;
  FileSize := FSize div blocksize;
end;

Function  RgFileObj.RealFileSize:LongInt;
begin
  RealFileSize := System.FileSize(Fil);
end;

Procedure RgFileObj.Reset;
begin
  System.Reset(Fil, 1);
  CheckIo;
end;

Procedure RgFileObj.Rewrite;
begin
  System.Rewrite(Fil, 1);
  CheckIo;
end;

Procedure RgFileObj.ResetMake;
begin
  if Exist(FileName) then
    Reset
  else
    Rewrite;
end;

Procedure RgFileObj.Seek(Where:LongInt);          { Goes to Where in Fil, Units of blocksize}
begin
  System.Seek(Fil, (Where*blocksize));
  CheckIo;
end;

Procedure RgFileObj.RealSeek(Where:LongInt);
begin
  System.Seek(Fil, Where);
  CheckIo;
end;

procedure RgFileObj.Truncate;          { Truncates file at current pos (at begining of data block) }
begin
  System.Truncate(Fil);
  CheckIo;
end;


Procedure RgFileObj.GetFAttr(Atr:word);
begin
  Dos.GetFAttr(Fil, Atr);
  CheckIo;
end;

Procedure RgFileObj.SetFAttr(Atr:word);          { Sets File attribute, WILL CLOSE FILE! }
begin
  Close;
  Dos.SetFAttr(Fil, Atr);
  CheckIo;
end;

Procedure RgFileObj.GetFTime(Time:LongInt);
begin
  Dos.GetFTime(Fil, Time);
  CheckIo;
end;

Procedure RgFileObj.SetFTime(Time:LongInt);          { Sets file time, File MUST BE OPEN! }
begin
  Dos.SetFTime(Fil, Time);
  CheckIo;
end;

Function  RgFileObj.HasfAttr(Which:Word):boolean;
  begin
    HasfAttr := ((Which AND Attr) <> 0);
  end;


Function  RgFileObj.FileOpen:Boolean;
  Begin
    if (FileRec(Fil).Mode = fmClosed) then
      FileOpen := FALSE
    else
      FileOpen := TRUE;
  End;

Procedure RgFileObj.MoveRecord(FromWhere, ToWhere:LongInt);
              { Moves record to pos, overwriting dest and deleting orig }
begin
  CopyRecord(FromWhere, ToWhere);
  DeleteRecord(FromWhere);
end;

Procedure RgFileObj.MoveInsertRecord(FromWhere, BeforeWhere:LongInt);
Begin
  InsertRecord(BeforeWhere);
  MoveRecord(FromWhere, BeforeWhere-1);
End;

Procedure RgFileObj.CopyRecord(FromWhere, ToWhere:LongInt);
              { Copies from orig to dest, leave orig }
begin
  Seek(FromWhere);
  read(data^);
  Seek(ToWhere);
  Write(Data^);
end;

Procedure RgFileObj.CopyInsertRecord(FromWhere, BeforeWhere:LongInt);
begin
  InsertRecord(BeforeWhere);
  CopyRecord(FromWhere, BeforeWhere-1);
end;

Procedure RgFileObj.SwapRecord(R1, R2:LongInt);
              { Swaps two records }
VAR
  t:pbuf;
begin
  GetMem(T, blocksize);
  if (T=NIL) then
  begin
    SetOk(FALSE);
    Exit;
  end;
  Seek(R1);  Read(Data);
  Seek(R2);  Read(T);
  Seek(R2);  Write(Data);
  Seek(R1);  Write(T);

  FreeMem(T, blocksize);
end;

Procedure RgFileObj.DeleteRecord(FromWhere:LongInt);
              { Deletes record and packs file }
              { at later date can override and add free list pointers }
VAR
  FS:LongInt;
  Loop:LongInt;
begin
  FS := FileSize;
  if (FromWhere < FS) then
  begin
    For loop := FromWhere to FS-1 do
      CopyRecord(Loop+1, Loop);
  end;
  Contract(1);
end;

Procedure RgFileObj.ClearRecord(Where:LongInt);
              { Blanks record }
begin
  FillChar(Data^, blocksize, #0);
  Seek(Where);
  Write(Data^);
end;

Procedure RgFileObj.InsertRecord(BeforeWhere:LongInt);
              { Insert blank record before specified record }
VAR
  Loop, Fs:LongInt;
begin
  InsertRecords(BeforeWhere, 1);
end;

Procedure RgFileObj.InsertRecords(BeforeWhere:LongInt; Quantity:Word);
              { Inserts n amount of blank records before specified record }
VAR
  Fs, Loop :LongInt;
begin
  ExpandFile(Quantity);
  Fs := FileSize;
  For Loop := Fs downto BeforeWhere+Quantity-1 do
  begin
    SwapRecord(Loop, Loop-Quantity);
  end;
end;

{
-----------------------------------------------------
-----------------------------------------------------[RgFileObject]---
-----------------------------------------------------
}

{
-----------------------------------------------------
-----------------------------------------------------[RgShareFileObj]---
-----------------------------------------------------
}

Constructor RgShareFileObj.Init(L:LongInt);
begin
  Inherited Init(L);
  ShareMode := Shared;
  FileMode := 66;
(*  FilMode := WriteDenyNone;*)
  SetLoopCount(5);
  SetDelayAmt(20);
end;

Destructor  RgShareFileObj.Done;
begin
  Inherited Done;
end;

procedure RgShareFileObj.Reset;
begin
(*  SetFileMode(FilMode);*)
  Inherited Reset;
end;

procedure RgShareFileObj.Rewrite;
begin
(*  SetFileMode(FilMode);*)
  Inherited Rewrite;
end;

procedure RgShareFileObj.DefaultfileMode(Mde:Byte);
begin
  filmode := mde;
end;

Procedure RgShareFileObj.SetFileMode(Mde:byte);
  Begin
    bcShare.SetFileMode(mde);
  End;

Procedure RgShareFileObj.BlockWrite(Var Buf; Count:Word);
  VAR
    Fs, Fp : Longint;
    TempCount:Word;
  Begin
    Fs := RealFileSize;
    Fp := RealFilePos;
    TempCount := 0;

    Repeat
      if (ShareMode) and (FS <> FP) then
        begin
          With FileRec(Fil) Do
            LockFile(Handle,Lock,FP,blocksize);
        end;

      System.BlockWrite(Fil, Buf, Count, Result);

      if (ShareMode) and (FS <> FP) then
        begin
          With FileRec(Fil) do
            LockFile(Handle, UnLock, FP, blocksize);
        end;
      CheckIo;
      if IoRes = 5 then
      begin
        Delay(DelayAmt);
      end;
      Inc(TempCount);
    until (IoRes <> 5) and (TempCount <= LoopCount);
  End;

Procedure RgShareFileobj.SetLoopCount(ToWhat:Word);
begin
  LoopCount := ToWhat;
end;

Procedure RgShareFileObj.SetDelayAmt(ToWhat:Word);
begin
  DelayAmt := ToWhat;
end;

{
-----------------------------------------------------
-----------------------------------------------------[RgShareFileObj]---
-----------------------------------------------------
}


begin
end.
