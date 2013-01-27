{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit file13;

interface

uses crt, dos, overlay, myio, common;

procedure sort;

implementation

uses file0, file1, file2;

var totfils,totbases:longint;
    pl:integer;
    sortt:char;

procedure sortdir;
var S,I,J,Gap:integer;
    f1,f2:ulfrec;
begin
  Gap := pl;
  repeat;
    Gap := Gap div 2;
    if Gap = 0 then Gap := 1;
    s := 0;
    For I := 1 to (pl-Gap) do begin
      J := I + Gap;
      seek(DirFile,i-1); read(DirFile,f1);
      seek(DirFile,j-1); read(DirFile,f2);
      If f1.filename > f2.filename then begin
         seek(DirFile,i-1); write(DirFile,f2);
         seek(DirFile,j-1); write(DirFile,f1);
         inc(s);
      end;
    end;
  until (s = 0) and (Gap = 1);
  if (IOResult <> 0) then
    sysoplog('error sorting files!');
end;

procedure sortfiles(b:integer);
var
  oldboard:integer;
begin
  oldboard:=fileboard;
  if (fileboard<>b) then changefileboard(b);
  if (fileboard=b) then begin
    initfileboard;
    pl:=filesize(DirFile);
    prompt('^1Sorting ^5'+memuboard.name+'^5 #'+cstr(fileboard)+
           '^1 ('+cstr(pl)+' files)');
    abort:=FALSE; next:=FALSE;
    sortdir;
    wkey;
    close(DirFile);
    inc(totbases); inc(totfils,pl);
    nl;
  end;
  fileboard:=oldboard;
end;

procedure sort;
var
  i:integer;
  global,oldconf:boolean;
begin
  nl;
  if not sortfilesonly then
      global:=pynq('Sort all directories? ')
  else
   begin
    global:=TRUE;
    clrscr;
   end;
  nl;

  totfils:=0; totbases:=0;

  abort:=FALSE; next:=FALSE;
  if (not global) then
    sortfiles(fileboard)
  else begin
    i:=0;
    oldconf:=confsystem;
    confsystem := FALSE;
    if (oldconf = TRUE) then
      newcomptables;
    TempPause := FALSE;
    while ((not abort) and (i<=MaxFBases) and (not hangup)) do begin
      if fbaseac(i) or sortfilesonly then sortfiles(i);
      inc(i);
      wkey;
    end;
    confsystem:=oldconf;
    if (oldconf = TRUE) then
      newcomptables;
  end;
  
  print(^M^J'Sorted '+cstr(totfils)+' file'+aonoff(totfils<>1,'s','')+
        ' in '+cstr(totbases)+' base'+aonoff(totbases<>1,'s',''));
  sysoplog('Sorted file areas');

end;

end.
