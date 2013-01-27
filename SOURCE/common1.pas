{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S-,V-}

unit common1;

interface

uses crt, dos, myio, common, timefunc;

function checkpw:boolean;
procedure newcomptables;
procedure wait(b:boolean);
procedure inittrapfile;
procedure local_input1(var i:string; ml:integer; tf:boolean);
procedure local_input(var i:string; ml:integer);
procedure local_inputl(var i:string; ml:integer);
procedure local_onek(var c:char; ch:string);
procedure sysopshell;
procedure redrawforansi;

implementation

function checkpw:boolean;
var s:string[20];
begin
  if not general.sysoppword or inwfcmenu then
    begin
      checkpw:=TRUE;
      exit;
    end;

  checkpw:=FALSE;

  prompt('SysOp Password: ');
  echo:=FALSE;
  input(s,20);
  echo:=TRUE;

  if (s=general.sysoppw) then
    checkpw:=TRUE
  else
    if (incom) and (s<>'') then
      sysoplog('--> SysOp Password Failure = '+s+' ***');
end;

procedure newcomptables;
var
  i:integer;
  xreadboard,xreaduboard:integer;
begin
  fillchar(ccboards[0], sizeof(ccboards), 0);
  fillchar(ccuboards[0], sizeof(ccuboards), 0);

  xreadboard := readboard;
  xreaduboard := readuboard;

  reset(MBasesFile);
  if (IOResult <> 0) then
    begin
      sysoplog('error opening MBASES.DAT');
      exit;
    end;
  reset(FBasesFile);
  if (IOResult <> 0) then
    begin
      sysoplog('error opening FBASES.DAT');
      exit;
    end;

  MaxMBases := filesize(MBasesFile);
  MaxFBases := filesize(FBasesFile);

  if (general.compressbases) then
    begin
      for i := 0 to filesize(FBasesFile) - 1 do
        begin
          read(FBasesFile, memuboard);

          if (i < MAXBASES) and aacs(memuboard.acs) then
            ccuboards[i div 8] := ccuboards[i div 8] + [i mod 8];
        end;

      for i := 0 to filesize(MBasesFile) - 1  do
        begin
          read(MBasesFile, memboard);
          if (i < MAXBASES) and aacs(memboard.acs) then
            ccboards[i div 8] := ccboards[i div 8] + [i mod 8];
        end;
    end;

  close(MBasesFile);
  close(FBasesFile);
  Lasterror := IOResult;

  readboard := 0;
  readuboard := 0;

  if not fbaseac(fileboard) then changefileboard(afbase(1));
  if not mbaseac(board) then changeboard(ambase(1));

  loadboard(xreadboard);
  loadfileboard(xreaduboard);
end;

procedure wait(b:boolean);
const lastc:byte=0;
begin
  if (b) then
    begin
      lastc:=curco;
      prompt(fstring.wait)
    end
  else
    begin
      BackErase(LennMCI(fstring.wait));
      setc(lastc);
    end;
end;

procedure inittrapfile;
begin
  if (general.globaltrap) or (trapactivity in thisuser.sflags) then trapping:=TRUE
    else trapping:=FALSE;
  if (trapping) then begin
    if (trapseparate in thisuser.sflags) then
      assign(trapfile,general.logspath+'trap'+cstr(usernum)+'.log')
    else
      assign(trapfile,general.logspath+'trap.log');
    append(trapfile);
    if (ioresult = 2) then begin
      rewrite(trapfile);
      writeln(trapfile);
    end;
    writeln(trapfile,'***** Renegade User Audit - '+caps(thisuser.name)+' on at '+date+' '+time+' *****');
  end;
end;


procedure local_input1(var i:string; ml:integer; tf:boolean);
var
  cp:integer;
  cc:char;
begin
  cp:=1;
  repeat
    cc:=readkey;
    if (not tf) then cc:=upcase(cc);
    if (cc in [#32..#255]) then
      if (cp<=ml) then begin
        i[cp]:=cc;
        inc(cp);
        write(cc);
      end
      else
    else
      case cc of
        ^H:if (cp>1) then begin
            cc:=^H;
            write(^H' '^H);
            dec(cp);
          end;
    ^U,^X:while (cp<>1) do begin
            dec(cp);
            write(^H' '^H);
          end;
      end;
  until (cc in [^M,^N]);
  i[0]:=chr(cp-1);
  if (wherey<=hi(windmax)-hi(windmin)) then writeln;
end;

procedure local_input(var i:string; ml:integer);  (* Input uppercase only *)
begin
  local_input1(i,ml,FALSE);
end;

procedure local_inputl(var i:string; ml:integer);   (* Input lower & upper case *)
begin
  local_input1(i,ml,TRUE);
end;

procedure local_onek(var c:char; ch:string);                    (* 1 key input *)
begin
  repeat c:=upcase(readkey) until (pos(c,ch)>0);
  writeln(c);
end;

procedure sysopshell;
var
  opath:string[80];
  t:longint;
  sx,sy,ret,bb:byte;
begin
  bb:=curco;
  getdir(0,opath);
  t:=timer;
  if (useron) then
    begin
      prompt(fstring.shelldos1);
      com_flush_tx;
      delay(100);
    end;
  sx:=wherex; sy:=wherey;
  window(1,1,80,25);
  clrscr;
  textcolor(11);
  writeln('Type EXIT to return to Renegade.');
  TimeLock := TRUE;
  shelldos(FALSE,'',ret);
  TimeLock := FALSE;
  if (useron) then com_flush_rx;
  chdir(opath);
  clrscr;
  textattr:=bb;
  gotoxy(sx,sy);
  if (useron) then
    begin
      if (not ch) then
        freetime:=freetime+timer-t;
      update_screen;
      for bb := 1 to lennmci(fstring.shelldos1) do backspace;
    end;
end;

procedure redrawforansi;
begin
  if (dosansion) then begin dosansion:=FALSE; update_screen; end;
  textattr:=7; curco:=7;
  if (outcom) then
    if (okavatar) then
      SerialOut(^V^A^G)
    else
      if (okansi) then
        SerialOut(#27+'[0m');
end;

end.

