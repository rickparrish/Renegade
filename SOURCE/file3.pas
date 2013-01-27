{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit file3;

interface

uses crt, dos, overlay, myio, common;

procedure recheck;

implementation

uses file0, file1;

procedure CheckFiles(x:integer; checkdiz:boolean);
var
  rn:integer;
  f:ulfrec;
  v:verbrec;
  f2:file;
  s:astr;
begin
  TempPause := FALSE;
  changefileboard(x);
  if (fileboard = x) then
    begin
      initfileboard;
      rn := 0;
      while (rn < filesize(DirFile)) and (not abort) do
        begin
          wkey;
          Lasterror := ioresult;
          read(DirFile, f);
          if exist(memuboard.ulpath + f.filename) then
            s := memuboard.ulpath + f.filename
          else
            s := memuboard.dlpath + f.filename;
          assign(f2, s);
          reset(f2,1);
          if (IOResult <> 0) then
            f.filestat := f.filestat + [isrequest]
          else
            begin
              f.filestat := f.filestat - [isrequest];
              f.blocks := filesize(f2) div 128;
              f.sizemod := filesize(f2) mod 128;
              close(f2);
            end;
          if (CheckDiz) and (DizExists(s)) then
            begin
              GetDiz(f, v);
              if (v.descr[1] <> '') then
                begin
                  if (f.vpointer = -1) then
                    f.vpointer := NewVPointer;
                end;
              writefv(rn, f, v);
            end;
          seek(DirFile, rn);
          write(DirFile, f);
          inc(rn);
         end;
       close(DirFile);
    end;
end;

procedure grecheck;
var
  oldboard:integer;
  checkdiz, oldconf:boolean;
  x:integer;
begin
  oldboard := fileboard;
  oldconf := confsystem;
  if (oldconf = TRUE) then
    newcomptables;
  x := 1;
  CheckDiz := pynq(^M^J'Reimport descriptions? ');
  nl;
  abort:=FALSE; next:=FALSE; TempPause := FALSE;
  while (not abort) and (x <= MaxFBases) and (not hangup) do
    begin
      if (cfbase(x) > 0) then
        begin
          loadfileboard(x);
          if aacs(memuboard.acs) then
            begin
              print('^1Checking ^5'+memuboard.name+' #'+cstr(cfbase(x))+'^1...');
              Checkfiles(x, CheckDiz);
            end;
          wkey;
          next:=FALSE;
        end;
        inc(x);
    end;
  confsystem := oldconf;
  if (oldconf = TRUE) then
    newcomptables;
  fileboard := oldboard;
  initfileboard;
end;

procedure recheck;
begin
  abort := FALSE;
  if pynq(^M^J'Recheck all directories? ') then
    grecheck
  else
    CheckFiles(fileboard, pynq(^M^J'Reimport descriptions? '));
end;

end.
