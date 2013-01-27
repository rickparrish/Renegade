{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit mail7;

interface

uses crt, dos, overlay, common, timefunc;

procedure mbaselist(ShowScan:boolean);
procedure mbasechange(var done:boolean; var mstr:astr);

implementation

uses mail0, Mail1, Email;

procedure mbaselist(ShowScan:boolean);
var s:astr;
    b,onlin,nd:integer;
    oldboard:word;

begin
  abort:=FALSE;
  onlin:=0; b:=1; nd:=0;
  oldboard:=board;
  cls;
  printacr('7ÚÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
  printacr('7³8 Num 7³9 Name                           7³8 Num 7³9 Name                          7³');
  printacr('7ÀÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
  reset(MBasesFile);
  AllowContinue := TRUE;  AllowAbort := TRUE;
  while ((b <= MaxMBases) and (not abort)) do begin
    if ShowScan then
      initboard(b)
    else
      loadboard(b);

    if (aacs(memboard.acs)) or (mbunhidden in memboard.mbstat) then begin
      s:=';'+cstr(cmbase(b));
      s:=mrn(s,5);
      if (ShowScan and NewScanMBase) then
        s := s + ': ş '
      else
        s := s + '   ';
      s:=s+'<'+memboard.name;
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
  close(MBasesFile);
  if (onlin=1) then nl;
  nl;
  if (nd=0) and (not abort) then prompt(^M^J'^7No message bases.');
  board := oldboard;
  {initboard(board);}
end;

procedure mbasechange(var done:boolean; var mstr:astr);
var s:astr;
    i:integer;
begin
  if (mstr <> '') then
    case upcase(mstr[1]) of
      '+':begin
            i:=board;
            if (board>=MaxMBases) then i:=0 else
              repeat
                inc(i);
                changeboard(i);
              until (board=i) or (i>MaxMBases);
            if (board<>i) then print(^M^J'Highest accessible message base.')
              else lastcommandovr:=TRUE;
            exit;
          end;
      '-':begin
            i:=board;
            if board<=0 then i:=MaxMBases else
              repeat
                dec(i);
                changeboard(i);
              until (board=i) or (i<=0);
            if (board<>i) then print(^M^J'Lowest accessible message base.')
              else lastcommandovr:=TRUE;
            exit;
          end;
      'L':begin
            mbaselist(FALSE);
            if (novice in thisuser.flags) then pausescr(FALSE);
            exit;
          end;
    else
      if (value(mstr) > 0) then
        begin
          i:=value(mstr);
          changeboard(i);
          if pos(';',mstr)>0 then begin
            s:=copy(mstr,pos(';',mstr)+1,length(mstr));
            curmenu:=general.menupath+s+'.mnu';
            newmenutoload:=TRUE;
            done:=TRUE;
          end;
          lastcommandovr:=TRUE;
          exit;
        end;
    end;
  if not (upcase(mstr[1]) = 'N') then
    mbaselist(FALSE)
  else
    nl;
  repeat
    prompt('^1Change message base (^5?^1=^5List^1) : ^3');
    scaninput(s,'Q?'^M);
    i:=ambase(value(s));
    if s='?' then
      mbaselist(FALSE)
    else
      if (i>=1) and (i<=MaxMBases) and (i<>board) then
        changeboard(i);
  until (s<>'?') or (hangup);
  lastcommandovr:=TRUE;
end;

end.
