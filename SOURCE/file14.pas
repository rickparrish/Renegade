{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit file14;

interface

uses crt,dos,overlay, myio, common;

procedure getgifspecs(const fn:astr; var sig:astr; var x,y,c:word);
procedure dogifspecs(const fn:astr);
procedure addgifspecs;

implementation

uses file0, file11;

procedure getgifspecs(const fn:astr; var sig:astr; var x,y,c:word);
var f:file;
    rec:array[1..11] of byte;
    c1,i,numread:word;
begin
  assign(f,fn);
  reset(f,1);
  if (ioresult<>0) then begin
    sig:='NOTFOUND';
    exit;
  end;

  blockread(f,rec,11,numread);
  close(f);

  if (numread<>11) then begin
    sig:='BADGIF';
    exit;
  end;

  if (rec[1] <> ord('G')) or (rec[2] <> ord('I')) or (rec[3] <> ord('F')) then
    begin
      sig := 'NOTFOUND';
      exit;
    end;

  sig:='';
  for i:=1 to 6 do sig:=sig+chr(rec[i]);

  x:=rec[7]+rec[8]*256;
  y:=rec[9]+rec[10]*256;
  c1:=(rec[11] and 7)+1;
  c:=1;
  for i:=1 to c1 do c:=c*2;
end;

procedure dogifspecs(const fn:astr);
var s,sig:astr;
    x,y,c:word;
begin
  getgifspecs(fn,sig,x,y,c);
  s:='^3'+align(stripname(fn));
  if (sig='NOTFOUND') then
    s:=s+'   ^7NOT FOUND'
  else
    s:=s+'   ^5'+mln(cstr(x)+'x'+cstr(y),10)+'   '+
         mln(cstr(c)+' colors',10)+'   ^7'+sig;
  printacr(s);
end;

procedure addgifspecs;
var f:ulfrec;
    s,sig:astr;
    totfils:longint;
    x,y,c:word;
    rn:integer;
begin
  print(^M^J'Adding GifSpecs to files -'^M^J);
  recno('*.*',rn);
  if (baddlpath) then exit;

  totfils:=0; abort:=FALSE; next:=FALSE;

  while (rn<>-1) and (filesize(DirFile)<>0) and (rn<filesize(DirFile)) and
        (not abort) and (not hangup) do begin
    seek(DirFile,rn); read(DirFile,f);
    if ((isgifext(f.filename)) and (not isgifdesc(f.description))) then begin
      getgifspecs(memuboard.dlpath+sqoutsp(f.filename),sig,x,y,c);
      if (sig<>'NOTFOUND') then begin
        s:='('+cstr(x)+'x'+cstr(y)+','+cstr(c)+'c) ';
        f.description:=copy(s+f.description,1,54);
        seek(DirFile,rn); write(DirFile,f);
        display_file('',f, FALSE);
        inc(totfils);
      end;
    end;
    nrecno('*.*',rn);
    wkey;
  end;

  nl;
  s:='Added GifSpecs to '+cstr(totfils)+' file';
  if (totfils<>1) then s:=s+'s';
  print(s);

  close(DirFile);
end;

end.
