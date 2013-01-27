{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}
Unit RG_Mbase;
INTERFACE
uses
  dos, overlay, CommDec, common, Rg_Obj, Rg_oFile;
{$Define Beta}
{
Code: 3097
Data: 8
}
{

 !!! All base operations are normalized.  When you send a number to them,
     use the base number as the user sees it, the -1 is done internally
     in all cases.

}


{
ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Message Base Object ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
}

TYPE
  MsgBaseObj=Object(RgObj)
    { This object modifies message base configs, not messages }
    BaseFile:pRgShareFileObj;
    CurrentBase:word;   { Current message base }
    Data:BoardRec;      { Current Data }
    BaseCount:word;     { Number of bases we have }
    HiQwk:Word;         { Scratch variable }

    Constructor Init;
    Destructor  Done;

    Procedure DataToDefault;
              { Sets DATA to default record }
    Procedure FindHiQwk;
              { Finds highest QWK indice and sets HiQwk to it }
    Procedure ListBases(ShowScan:Boolean);
              { Lists message bases }
    Procedure ChangeBase(Opt:Str1);
              { Changes current base }
              { Opt=L=Lst, +, - }

    Function  HasFlag(Which:MBFlags):Boolean;
              { Does it have this flag? }
    Procedure ToggleMBStat(Which:MbFlags);
              { Toggles specified MBStat }

    Procedure IncBase;
              { Moves to next base }
    Procedure DecBase;
              { Moves back a base }
    Procedure LoadBase;
              { Loads current base }
    Procedure GoToBase(Which:Word);


    Procedure UpdateCount;
              { Updates count of message bases }

    Procedure UpdateBase;
              { writes current data record into CurrentBase slot }
    Procedure DeleteBase(Which:Word);
              { Removes a specified base }
    Procedure CopyBase(FromWhere, BeforeWhere:Word);
              { Obvious }
    Procedure InsertBase(BeforeWhere:Word);
              { Inserts a blank base }
    Procedure InsertBases(BeforeWhere,Quantity:Word);
              { Inserts Quantity number of blank bases }
    Procedure AppendBase;
              { Inserts a blank base at the end of the file }
    Procedure SwapBases(Base1, Base2:Word);
              { Swaps the data of two bases }

  end;
  pMsgBaseObj=^MsgBaseObj;

IMPLEMENTATION
USES
  Rg_Scan;

Constructor MsgBaseObj.Init;
begin
  inherited init;
  CurrentBase := 1;

  New(BaseFile, Init(SizeOf(BoardRec)));
  if BaseFile = NIL then
  begin
    Fail;
  end;

  BaseFile^.Assign(general.datapath+'MBASES.DAT');

  BaseFile^.ResetMake;
  if Not(BaseFile^.Ok) then
  begin
    dispose(BaseFile, Done);
    Fail;
  end;

  BaseCount := BaseFile^.FileSize;
end;

Destructor  MsgBaseObj.Done;
begin
  inherited done;
  Dispose(BaseFile, Done);
end;

Procedure MsgBaseObj.DataToDefault;
begin
  with Data do
    begin
      name:='<< Not used >>';
      filename:='NEWBOARD';
      QWKIndex:=HiQwk;
      sysopacs:='s255';
      maxmsgs:=100;
      anonymous:=atno;
      if (General.origin<>'') then origin:=General.origin;
      text_color:=General.text_color;
      quote_color:=General.quote_color;
      tear_color:=General.tear_color;
      origin_color:=General.origin_color;
      if (General.skludge) then mbstat:=mbstat+[mbskludge];
      if (General.sseenby) then mbstat:=mbstat+[mbsseenby];
      if (General.sorigin) then mbstat:=mbstat+[mbsorigin];
      if (General.addtear) then mbstat:=mbstat+[mbaddtear];
    end;
end;

Procedure MsgBaseObj.FindHiQwk;
  VAR
    CB:Word;
    Loop:Word;
begin
    Cb := CurrentBase;
    HiQwk := 0;
    For Loop := 0 to BaseFile^.FileSize-1 do
    begin
      GoToBase(Loop);
      if (Data.QwkIndex > HiQwk) then
        HiQwk := Data.QwkIndex;
    end;
    CurrentBase := CB;
    LoadBase;
end;


Procedure MsgBaseObj.ListBases(ShowScan:Boolean);
          { Lists message bases }
var
  s:astr;
  b,onlin,nd:integer;
  oldboard:word;
  Scan:MsgScanListObj;

begin
  abort:=FALSE;
  onlin:=0; b:=1; nd:=0;
  oldboard:=CurrentBase;
  cls;
  if ShowScan then
  begin
    Scan.Init;
    Scan.SelectBase(general.datapath+Data.filename+'.SCN');
  end;

  PrintF('mbaselh');

  AllowContinue := TRUE;  AllowAbort := TRUE;
  while ((b <= MaxMBases) and (not abort)) do
  begin
    LoadBase;
    if ShowScan then
      Scan.SelectUser(UserNum);

    if (aacs(memboard.acs)) or (mbunhidden in memboard.mbstat) then begin
      s:=';'+cstr(cmbase(b));
      s:=mrn(s,5);
      if (ShowScan and Scan.HasFlag) then
        s := s + ': ş '
      else
        s := s + '   ';
      S := S+'<'+data.name;

      inc(onlin);
      inc(nd);
      if (onlin = 1) then
        prompt(mln(s,39))
      else
        begin
          if (lennmci(s) > 39) then
            print(mln(s,39))
          else
            print(s);
          onlin:=0;
        end;
      wkey;
    end;
    inc(b);
  end;
  AllowContinue := FALSE;
  if (onlin=1) then nl;
  nl;
  if (nd=0) and (not abort) then prompt(^M^J'^7No message bases.');
  CurrentBase := OldBoard;
end;

Procedure MsgBaseObj.IncBase;
begin
  Inc(CurrentBase);
  if CurrentBase > BaseCount then
    CurrentBase := BaseCount;
  LoadBase;
end;

Procedure MsgBaseObj.Decbase;
begin
  Dec(CurrentBase);
  if CurrentBase < 1 then
    CurrentBase := 1;
  LoadBase;
end;

Procedure MsgBaseObj.GoToBase(Which:Word);
begin
  CurrentBase := Which;
  if CurrentBase > BaseCount then
    CurrentBase := BaseCount;
  if CurrentBase < 1 then
    CurrentBase := 1;
  LoadBase;
end;

Procedure MsgBaseObj.LoadBase;
begin
  While (CurrentBase-1 > BaseFile^.FileSize-1) do
    Dec(CurrentBase);
  BaseFile^.Seek(CurrentBase-1);
  BaseFile^.Read(Data);
end;

Procedure MsgBaseObj.ChangeBase(Opt:Str1);
          { Changes current base }
          { Opt=L=Lst, +, - }
begin
  Case Opt[1] of
    '+'     : IncBase;
    '-'     : DecBase;
    'L', 'l': ListBases(FALSE);
    ' '     : ;
    else;
  end;
end;

Function  MsgBaseObj.HasFlag(Which:MBFlags):Boolean;
begin
  HasFlag := Which in data.MbStat;
end;

Procedure MsgBaseObj.ToggleMBStat(Which:MbFlags);
begin
  if HasFlag(Which) then
    Data.MbStat := Data.MbStat - [Which]
  else
    Data.MbStat := Data.MbStat + [Which];
end;

Procedure MsgBaseObj.UpdateCount;
begin
  BaseCount := BaseFile^.FileSize;
end;

Procedure MsgBaseObj.UpdateBase;
begin
  BaseFile^.Seek(CurrentBase);
  BaseFile^.write(Data);
end;

Procedure MsgBaseObj.DeleteBase(Which:Word);
begin
  if (Which = 0) or (which > BaseCount) then Exit;

  print(^M^J'Message base: ^5' + memboard.name);
  if pynq('Delete this? ') then
  begin
    BaseFile^.DeleteRecord(Which-1);
    sysoplog('* Deleted message base: '+data.name);
    if (pynq('Delete message files? ')) then
    begin
      Kill(General.DataPath+Data.Filename+'.JHR');
      Kill(General.DataPath+Data.Filename+'.JDT');
      Kill(General.DataPath+Data.Filename+'.JDX');
      Kill(General.DataPath+Data.Filename+'.JLR');
      SysopLog('* Deleted message files');
    end;
  end;
  CurrentBase := 1;
end;

Procedure MsgBaseObj.CopyBase(FromWhere, BeforeWhere:Word);
begin
  BaseFile^.CopyInsertRecord(FromWhere, BeforeWhere);
  LoadBase;
end;

Procedure MsgBaseObj.InsertBase(BeforeWhere:Word);
begin
  InsertBases(BeforeWhere, 1);
  LoadBase;
end;

Procedure MsgBaseObj.InsertBases(BeforeWhere,Quantity:Word);
VAR
  Loop : Word;
begin
  BaseFile^.InsertRecords(BeforeWhere-1, Quantity);
  FindHiQwk;
  For Loop := BeforeWhere-1 to (BeforeWhere-1+Quantity) do
  begin
    Inc(HiQwk);
    DataToDefault;
    Data.QwkIndex := HiQwk;
    BaseFile^.Seek(Loop);
    BaseFile^.Write(data);
  end;
  LoadBase;
end;

Procedure MsgBaseObj.AppendBase;
VAR
  Loop:Word;
begin
  If Ok then
  begin
    FindHiQwk;
    Fillchar(Data, SizeOf(Data), #0);

    DataToDefault;
    inc(HiQwk);
    Data.QwkIndex := HiQwk;

    BaseFile^.Seek(BaseFile^.FileSize);
    BaseFile^.Write(Data);
  end;
end;

Procedure MsgBaseObj.SwapBases(Base1, Base2:Word);
begin
  With BaseFile^ do
  begin
    SwapRecord(Base1, Base2);
  end;
  LoadBase;
end;


begin
end.

