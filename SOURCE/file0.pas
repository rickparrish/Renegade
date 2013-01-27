{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit file0;

interface

uses crt,dos,overlay, myio, common;

procedure countdown;
function align(const fn:astr):astr;
function baddlpath:boolean;
function badulpath:boolean;
function existdir(fn:astr):boolean;
procedure fileinfo(var f:ulfrec; editing:boolean);
procedure initfileboard;
function fit(const f1,f2:astr):boolean;
procedure gfn(var fn:astr);
function isgifdesc(const d:astr):boolean;
function isgifext(const fn:astr):boolean;
function isul(const s:astr):boolean;
function iswildcard(const s:astr):boolean;
procedure nrecno(const fn:astr; var rn:integer);
procedure lrecno(const fn:astr; var rn:integer);
procedure recno(fn:astr; var rn:integer);
function tcheck(s:longint; i:integer):boolean;
procedure verbfileinfo(var pt:longint; editing:boolean);

implementation

function align(const fn:astr):astr;
var f,e:astr; c,c1:integer;
begin
  c:=pos('.',fn);
  if (c=0) then begin
    f:=fn; e:='   ';
  end else begin
    f:=copy(fn,1,c-1); e:=copy(fn,c+1,3);
  end;
  f:=mln(f,8);
  e:=mln(e,3);
  c:=pos('*',f); if (c<>0) then for c1:=c to 8 do f[c1]:='?';
  c:=pos('*',e); if (c<>0) then for c1:=c to 3 do e[c1]:='?';
  c:=pos(' ',f); if (c<>0) then for c1:=c to 8 do f[c1]:=' ';
  c:=pos(' ',e); if (c<>0) then for c1:=c to 3 do e[c1]:=' ';
  align:=f+'.'+e;
end;

function baddlpath:boolean;
begin
  if (badfpath) and aacs(memuboard.acs) then begin
    print(^M^J'^7File base #'+cstr(fileboard)+': Unable to perform command.');
    sysoplog('^5Bad DL file path: "'+memuboard.dlpath+'".');
    print('^5Please inform the SysOp.');
    sysoplog('Invalid DL path (file base #'+cstr(fileboard)+'): "'+
             memuboard.dlpath+'"');
  end;
  baddlpath:=badfpath;
end;

function badulpath:boolean;
begin
  if (badufpath) then begin
    print(^M^J'^7File base #'+cstr(fileboard)+': Unable to perform command.');
    sysoplog('^5Bad UL file path: "'+memuboard.ulpath+'".');
    print('^5Please inform the SysOp.');
    sysoplog('Invalid UL path (file base #'+cstr(fileboard)+'): "'+
             memuboard.ulpath+'"');
  end;
  badulpath:=badufpath;
end;

function existdir(fn:astr):boolean;
var dirinfo:searchrec;
begin
  while (fn[length(fn)] = '\') do
    dec(fn[0]);
  if (length(fn) = 2) and (fn[2] = ':') then
    existdir := TRUE
  else
    begin
      findfirst(fn,anyfile,dirinfo);
      existdir:=(doserror=0) and (dirinfo.attr and $10=$10);
    end;
end;

procedure initfileboard; { loads in memuboard ... }
var
  s:astr;
  Index:integer;
begin
  loadfileboard(fileboard);
  s:=memuboard.dlpath;
  dec(s[0]);
  if ((length(s)=2) and (s[2]=':')) then
    badfpath := FALSE
  else
    if not (fbcdrom in memuboard.fbstat) then
      badfpath := not existdir(s)
    else
      badfpath := FALSE;

  s:=memuboard.ulpath;
  dec(s[0]);

  if ((length(s)=2) and (s[2]=':')) then
    badufpath:=FALSE
  else
    if not (fbcdrom in memuboard.fbstat) then
      badufpath := not existdir(s)
    else
      badufpath := FALSE;

  if (not DirFileopen1) then
    if (filerec(DirFile).mode<>fmclosed) then
      close(DirFile);

  DirFileopen1:=FALSE;

  if (fbdirdlpath in memuboard.fbstat) then
    assign(DirFile,memuboard.dlpath+memuboard.filename+'.DIR')
  else
    assign(DirFile,general.datapath+memuboard.filename+'.DIR');
  reset(DirFile);

  if (ioresult = 2) then
    rewrite(DirFile);

  if (ioresult <> 0) then
    begin
      sysoplog('error opening '+memuboard.filename+'.DIR');
      exit;
    end;

  if (fbdirdlpath in memuboard.fbstat) then
    assign(ScnFile,memuboard.dlpath+memuboard.filename+'.SCN')
  else
    assign(ScnFile,general.datapath+memuboard.filename+'.SCN');
  reset(ScnFile);

  if (ioresult = 2) then
    rewrite(ScnFile);

  if (ioresult <> 0) then
    begin
      sysoplog('error opening '+memuboard.filename+'.DIR');
      exit;
    end;

  if (Usernum - 1 >= filesize(ScnFile)) then
    begin
      seek(ScnFile, filesize(ScnFile));
      NewScanFBase := TRUE;
      for Index := filesize(ScnFile) to Usernum - 1 do
        write(ScnFile, NewScanFBase);
    end
  else
    begin
      seek(ScnFile, Usernum - 1);
      read(ScnFile, NewScanFBase);
    end;

  close(ScnFile);

  Lasterror := IOResult;

  bnp:=FALSE;
end;

procedure fileinfo(var f:ulfrec; editing:boolean);
var
  s:astr;
  s2:string[5];
  x:longint;
  i,j:integer;
begin
  j := 0;
  with f do
    begin
      if (editing) then
        s2 := '1. '
      else
        s2 := '';
      printacr('^1' + s2 + 'Filename         : ^0'+sqoutsp(filename));
      if (editing) then
        s2 := '2. ';
      printacr('^1' + s2 + 'File size        : ^2'+FormatNumber(longint(blocks) * 128 + sizemod)+' bytes');
      if (editing) then
        s2 := '3. ';
      printacr('^1' + s2 + 'Description      : ^9' + description);
      if (f.vpointer <> -1) then
        verbfileinfo(f.vpointer, editing);
      if (editing) then
        s2 := '4. ';
      printacr('^1' + s2 + 'Uploaded by      : ^4' + caps(stowner));
      if (editing) then
        s2 := '5. ';
      printacr('^1' + s2 + 'Uploaded on      : ^5' + date);
      if (editing) then
        s2 := '6. ';
      printacr('^1' + s2 + 'Times downloaded : ^5' + FormatNumber(Downloaded));
      if (not editing) then
        printacr('^1Time to download : ^5' + ctim(128 * longint(blocks) div rate));
      if (editing) then
        s2 := '7. ';
      s := '^1' + s2 + 'Credit cost      : ^4';
      if (credits > 0) then
        s := s + FormatNumber(credits)
      else
        s := s + 'FREE';
      if (notval in filestat) then s:=s+' ^8'+'<NV>';
      if (isrequest in filestat) then s:=s+' ^9'+'Ask (Request File)';
      if (resumelater in filestat) then s:=s+' ^7'+'Resume later';
      if (hatched in filestat) then s:=s+' ^7'+'Hatched';
      printacr(s);
    end;
end;

function fit(const f1,f2:astr):boolean;
var tf:boolean; c:byte;
begin
  tf:=TRUE;
  for c:=1 to 12 do
    if (f1[c]<>f2[c]) and (f1[c]<>'?') then tf:=FALSE;
  if f2='' then tf:=FALSE;
  fit:=tf;
end;

procedure gfn(var fn:astr);
begin
  print(fstring.gfnline1);
  prt(fstring.gfnline2); input(fn,12);
  if (pos('.',fn)=0) then fn:=fn+'*.*';
  fn:=align(fn);
end;

function isgifdesc(const d:astr):boolean;
begin
  isgifdesc:=((d[1] = '(') and (pos('x',d) in [1..7]) and
              (pos('c)',d)<>0));
end;

function isgifext(const fn:astr):boolean;
begin
  isgifext:=(allcaps(copy(sqoutsp(stripname(fn)),length(fn)-2,3))='GIF');
end;

function isul(const s:astr):boolean;
begin
  isul:=((pos('/',s)<>0) or (pos('\',s)<>0) or (pos(':',s)<>0) or (pos('|',s)<>0));
end;

function iswildcard(const s:astr):boolean;
begin
  iswildcard:=((pos('*',s)<>0) or (pos('?',s)<>0));
end;

procedure lrecno(const fn:astr; var rn:integer);
var
  c:integer;
  f:ulfrec;
begin
  rn := 0;
  if (lrn <= filesize(DirFile)) and (lrn >= 0) then
    begin
      c := lrn - 1;
      while (c >= 0) and (rn = 0) do
        begin
          seek(DirFile,c);
          read(DirFile,f);
          if fit(lfn,f.filename) then
            rn := c;
          dec(c);
        end;
      lrn := rn;
    end
  else
    rn := -1;
  Lasterror := IOResult;
end;

procedure nrecno(const fn:astr; var rn:integer);
var
  c:integer;
  f:ulfrec;
begin
  rn := 0;
  if (lrn < filesize(DirFile)) and (lrn >= -1) then
    begin
      c := lrn + 1;
      while (c < filesize(DirFile)) and (rn = 0) do
        begin
          seek(DirFile,c);
          read(DirFile,f);
          if fit(lfn,f.filename) then
            rn := c + 1;
          inc(c);
        end;
      dec(rn);
      lrn := rn;
    end
  else
    rn := -1;
  Lasterror := IOResult;
end;

procedure recno(fn:astr; var rn:integer);
var f:ulfrec;
    c:integer;
begin
  fn:=align(fn);
  initfileboard;
  rn:=0; c:=0;
  while (c < filesize(DirFile)) and (rn=0) do begin
    seek(DirFile,c); read(DirFile,f);
    if fit(fn,f.filename) then rn:=c+1;
    inc(c);
  end;
  dec(rn);
  lrn:=rn;
  lfn:=fn;
  Lasterror := IOResult;
end;

function tcheck(s:longint; i:integer):boolean;
var
  r:longint;
begin
  r := timer - s;
  if (r < 0) then
    r := r + 86400;

  if (r > i) then
    tcheck := FALSE
  else
    tcheck := TRUE;
end;

procedure verbfileinfo(var pt:longint; editing:boolean);
var v:verbrec;
    i:integer;
    s:astr;
    vfo:boolean;
begin
  v.descr[1]:='';
  if (pt <> -1) then begin
    vfo:=(filerec(verbf).mode<>fmclosed);
    if not vfo then
      reset(verbf);
    if (ioresult = 0) then begin
      seek(verbf,pt); read(verbf,v);
      if (ioresult = 0) then
        with v do
          for i:=1 to MAXEXTDESC do
            if (descr[i]='') then
              break
            else
              begin
                s:='^1';
                if (editing) then s := s + '   ';
                if (i=1) then s:=s+'Extended         : ' else s:=s+'                 : ';
                s:=s+'^9'+descr[i];
                printacr(s);
              end
         else
          pt := -1;
      if (not vfo) then close(verbf);
    end;
  end;
  if (editing) then
    if (pt = -1) then
      printacr('^5   No extended description.')
    else
      if (v.descr[1]='') then
        printacr('^7   No extended description.^2 ('+cstr(pt)+')');
end;

procedure countdown;
var
  i:word;
  c:char;
  st:longint;
begin
  print(^M^J'Hit [Enter] to logoff now.');
  print('Hit [Esc] to abort logoff.'^M^J);
  prompt('|12Hanging up in : ^99');
  st:=timer; i := 9;
  c:=#0;
  while (i > 0) and not (c in [#13,#27]) and not (hangup) do
    begin
      if not empty then
        c := char(inkey);
      if (timer <> st) then
        begin
          dec(i);
          prompt(^H+cstr(i));
          st := timer;
        end
      else
        asm
          int 28h
        end;
    end;
  if (c <> #27) then
    begin
      hangup := TRUE;
      outcom := FALSE;
    end;
end;

end.
