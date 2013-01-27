{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit file9;

interface

uses crt, dos, overlay, myio, common;

function info:astr;
procedure dir(cd:astr; const x:astr; expanded:boolean);
procedure dirf(expanded:boolean);
procedure deleteff(rn:integer; killextended:boolean);
procedure setdirs;
procedure pointdate;

implementation

uses file0, file1, file2;

function align2(const s:astr):astr;
begin
  if pos('.',s)=0 then
    align2 := mln(s,12)
  else
    align2 := mln(copy(s,1,pos('.',s)-1),8)+' '+mln(copy(s,pos('.',s)+1,3),3);
end;

function info:astr;
var pm:char;
    s:astr;
    dt:datetime;

  function ti(i:integer):astr;
  begin
    ti:=Zeropad(cstr(i));
  end;

begin
  s:=dirinfo.name;
  if (dirinfo.attr and directory)=directory then s:=mln(s,13)+'<DIR>   '
    else s:=align2(s)+'  '+mrn(cstr(dirinfo.size),7);
  unpacktime(dirinfo.time,dt);
  with dt do begin
    if hour<13 then pm:='a' else begin pm:='p'; hour:=hour-12; end;
    s:=s+'  '+mrn(cstr(month),2)+'-'+ti(day)+'-'+ti(year-1900)+
             '  '+mrn(cstr(hour),2)+':'+ti(min)+pm;
  end;
  info:=s;
end;

procedure dir(cd:astr; const x:astr; expanded:boolean);
var
    s:astr;
    onlin:integer;
    dfs:longint;
    numfiles:integer;
begin
  if cd[length(cd)] <> '\' then
    cd := cd + '\';
  abort:=FALSE;
  findfirst(cd[1] + ':\*.*', volumeid, dirinfo);
  if (doserror > 0) then
    s := 'has no label'
  else
    s := 'is ' + dirinfo.name;
  printacr(' Volume in drive ' + cd[1] + ' ' + s);
  printacr(' Directory of ' + cd + ^M^J);
  s:=''; onlin:=0; numfiles:=0;
  cd:=cd+x;
  findfirst(cd, anyfile, dirinfo);
  dfs := 0;
  while (Doserror = 0) and (not abort) do
    begin
      if (not (dirinfo.attr and directory=directory)) or (FileSysOp) then
        if (not (dirinfo.attr and volumeid=volumeid)) then
          if ((not (dirinfo.attr and dos.hidden=dos.hidden)) or (usernum = 1)) then
            if ((dirinfo.attr and dos.hidden=dos.hidden) and
               (not (dirinfo.attr and directory=directory))) or
               (not (dirinfo.attr and dos.hidden=dos.hidden)) then begin
              if (expanded) then printacr(info)
              else begin
                inc(onlin);
                s:=s+align2(dirinfo.name);
                if onlin<>5 then s:=s+'    ' else begin
                  printacr(s);
                  s:=''; onlin:=0;
                end;
              end;
              inc(numfiles);
              inc(dfs, dirinfo.size);
            end;
      findnext(dirinfo);
    end;
  if (Doserror <> 0) and (onlin in [1..5]) then printacr(s);
  if (NumFiles = 0) then
    printacr('File not found')
  else
    printacr(mrn(cstr(numfiles) + ' file(s)', 17) + mrn(cstr(dfs) + ' bytes', 22));
  printacr(mrn(cstr(diskfree(ExtractDriveNumber(cd))),28)+' bytes free');
end;

procedure dirf(expanded:boolean);
var
  fspec:astr;
begin
  print(^M^J'Raw directory.');
  gfn(fspec); abort:=FALSE; next:=FALSE;
  nl;
  if (novice in thisuser.flags) then pausescr(FALSE);
  loadfileboard(fileboard);
  dir(memuboard.dlpath,fspec,expanded);
end;

procedure deleteff(rn:integer; killextended:boolean);
var i:integer;
    f:ulfrec;
    v:verbrec;
begin
  if (rn<=filesize(DirFile)) and (rn>-1) then begin
    seek(DirFile,rn); read(DirFile,f);
    if (f.vpointer<>-1) and (killextended) then begin
      reset(verbf);
      seek(verbf,f.vpointer); read(verbf,v);
      if (ioresult=0) then
        begin
          fillchar(v, sizeof(v), 0);
          seek(verbf,f.vpointer);
          write(verbf,v);
        end;
      close(verbf);
    end;
    if rn<>filesize(DirFile)-1 then
    for i:=rn to filesize(DirFile)-2 do begin
      seek(DirFile,i+1); read(DirFile,f);
      seek(DirFile,i); write(DirFile,f);
    end;
    seek(DirFile,filesize(DirFile)-1); truncate(DirFile);
  end;
  Lasterror := IOResult;
end;

procedure setdirs;
var
  s:string[15];
  Temp,
  First,
  Last,
  oldboard:word;
  oldconf:boolean;
begin
  nl;
  oldconf := confsystem;
  oldboard := fileboard;
  confsystem := FALSE;
  if (oldconf) then
    newcomptables;
  if (novice in thisuser.flags) then
    fbaselist(TRUE)
  else
    nl;
  repeat
    prt('Range to toggle (^5x^4-^5y^4), [F]lag or [U]nflag all, [Q]uit (^5?^4=^5List^4): ');
    scaninput(s,'FUQ-?'^M);
    if (s = '?') then
      fbaselist(TRUE)
    else
      if (s = 'F') then
        begin
          print(^M^J'You are now scanning all file bases.'^M^J);
          next := TRUE;
          for fileboard := 1 to MaxFBases do
            begin
              initfileboard;
              reset(ScnFile);
              seek(ScnFile, Usernum - 1);
              write(ScnFile, next);
              close(ScnFile);
            end;
        end
      else
        if (s = 'U') then
          begin
            print(^M^J'You are now not scanning any file bases.'^M^J);
            next := FALSE;
            for fileboard := 1 to MaxFBases do
              begin
                initfileboard;
                reset(ScnFile);
                seek(ScnFile, Usernum - 1);
                write(ScnFile, next);
                close(ScnFile);
              end;
          end
        else
          if (value(s) > 0) then
            begin
              First := afbase(value(s));
              if (pos('-', s) > 0) then
                begin
                  Last := afbase(value(copy(s, pos('-', s) + 1, 255)));
                  if (First > Last) then
                    begin
                      Temp := First;
                      First := Last;
                      Last := Temp;
                    end;
                end
              else
                Last := First;
              if (First >= 1) and (Last <= MaxFBases) then
                begin
                  for FileBoard := First to Last do
                    begin
                      initfileboard;
                      reset(ScnFile);
                      seek(ScnFile, Usernum - 1);
                      next := not NewScanFBase;
                      write(ScnFile, next);
                      close(ScnFile);
                    end;
                  if (First = Last) then
                    print(^M^J'^5' + memuboard.name + '^3 will ' + aonoff(next, '','not ') + 'be scanned.'^M^J);
                end
              else
                print(^M^J'Invalid range.'^M^J);
            end;
  until (s = 'Q') or (hangup);
  confsystem := oldconf;
  if (oldconf) then
    newcomptables;
  fileboard := oldboard;
  Lasterror := IOResult;
  lastcommandovr := TRUE;
end;

procedure pointdate;
var s:astr;
    c:char;
    b:byte;
begin
  prt(^M^J'Scan for new files since MM/DD/YYYY: ');
  mpl(8);
  prompt(newdate);
  c := char(getkey);
  if c<>#13 then begin
     buf:=c;
     for b:=1 to 10 do backspace;
     inputformatted(s,'##/##/####',TRUE);
     if s='' then s:=newdate;
  end else s:=newdate;
  if (daynum(s)=0) then print('Illegal date.')
     else newdate:=s;
  nl;
end;

end.
