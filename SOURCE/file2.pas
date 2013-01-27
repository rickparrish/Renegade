{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit file2;

interface

uses crt, dos, overlay, common, dffix;

procedure copyfile(var ok,nospace:boolean; showprog:boolean;
                   const srcname,destname:astr);
procedure movefile(var ok,nospace:boolean; showprog:boolean;
                   const srcname,destname:astr);

implementation

uses file0;

procedure copyfile(var ok,nospace:boolean; showprog:boolean;
                   const srcname,destname:astr);
var buffer:array[1..8192] of byte;
    i,filedate:longint;
    s:string[5];
    nrec:integer;
    src,dest:file;
    r:real;

begin
  ok:=TRUE; nospace:=FALSE;
  assign(src,srcname);
  getftime(src,filedate);
  reset(src,1);
  if (ioresult <> 0) then
    begin
      ok:=FALSE;
      exit;
    end;

  r := filesize(src) div 1024;
  if (r >= diskkbfree(ExtractDriveNumber(destname))) then
    begin
      close(src);
      nospace:=TRUE;
      ok:=FALSE;
      exit;
    end
  else begin
    assign(dest,destname);
    rewrite(dest,1);
    if (ioresult <> 0) then
      begin
        ok:=FALSE;
        exit;
      end;
      if (showprog) then
        prompt('  0%');
    i := 0;
    repeat
      blockread(src,buffer,sizeof(buffer),nrec);
      blockwrite(dest,buffer,nrec);
      inc(i, nrec);
      if (showprog) and (filesize(src) > 0) then
        begin
          str(trunc(i / filesize(src) * 100):3,s);
          prompt(^H^H^H^H + s + '%');
        end;
    until (nrec < sizeof(buffer));
    if (showprog) then nl;
    close(dest); close(src);
    setftime(dest,filedate);
  end;
  Lasterror := IOResult;
end;

procedure movefile(var ok,nospace:boolean; showprog:boolean;
                   const srcname,destname:astr);
var f:file;
    opath:astr;
begin
  ok:=TRUE; nospace:=FALSE;
  getdir(0,opath);
  assign(f,srcname);
  rename(f,destname);

  if (ioresult = 0) then
    if (showprog) then
      print('100%')
    else
  else
    begin
      copyfile(ok,nospace,showprog,srcname,destname);
      if ((ok) and (not nospace)) then
        kill(srcname);
    end;
  chdir(opath);
end;

end.
