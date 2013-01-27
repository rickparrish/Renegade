{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{  SysOp functions: change user, history, show logs, showmenu cmds }

unit sysop11;

interface

uses crt, dos, overlay, common;

procedure chuser;
procedure history;
procedure showlogs;

implementation

uses User, menus2, timefunc;

procedure chuser;
var
    i:integer;
begin
  prt('Change to which user? ');
  finduser(i);
  if (i>=1) then begin
    saveurec(thisuser,usernum);
    loadurec(thisuser,i);

    usernum:=i;
    choptime:=0; extratime:=0; freetime:=0;

    if (Speed > 0) then sysoplog('---> ^7Switched accounts to: ^5'+caps(thisuser.name));
    update_screen;
    newcomptables;
    loadnode(node);
    noder.user := usernum;
    noder.username := thisuser.name;
    savenode(node);
  end;
end;

procedure history;
var zf:file of historyrec;
    d1:historyrec;
    s:astr;
    i:integer;

  function mrnn(i:longint; l:integer):astr;
  begin
    mrnn:=mrn(cstr(i),l);
  end;

begin
  nl;
  assign(zf,general.datapath+'history.dat');
  reset(zf);
  if (ioresult<>0) then print('HISTORY.DAT not found.')
  else begin
    abort:=FALSE;
    AllowContinue := TRUE;
    d1.date:='a';

    printacr('^3        '+seperator+'Mins '+seperator+'    '+seperator+'      '+
             seperator+'#New'+seperator+'Tim/'+seperator+'Pub '+seperator+'Priv'+
             seperator+'Feed'+seperator+'    '+seperator+'    '+seperator+'     '+
             seperator+'    '+seperator+'');
    printacr('^3  Date  '+seperator+'Activ'+seperator+'Call'+seperator+'%Activ'+
             seperator+'User'+seperator+'User'+seperator+'Post'+seperator+'Post'+
             seperator+'Back'+seperator+'Errs'+seperator+'#ULs'+seperator+'UL-k '+
             seperator+'#DLs'+seperator+'DL-k');
    printacr('^4========:=====:====:======:====:====:====:====:====:====:====:=====:====:=====');
    i:=filesize(zf) - 1;
    while (i>=0) and (not abort) do begin
      seek(zf,i);
      read(zf,d1);
      if (i = filesize(zf) - 1) then
        d1.Date := 'Today''s ';
      if (d1.callers > 0) then
        s := mrnn(d1.active div d1.callers,4)
      else
        s := '    ';
      printacr('^1'+todate8(d1.date)+' '+mrnn(d1.active,5)+' '+mrnn(d1.callers,4)+' '+
               ctp(d1.active,1440)+' '+mrnn(d1.newusers,4)+' '+
               s+' '+mrnn(d1.posts,4)+' '+mrnn(d1.email,4)+' '+
               mrnn(d1.feedback,4)+' '+mrnn(d1.errors,4)+' '+
               mrnn(d1.uploads,4)+' '+mrnn(d1.uk,5)+' '+
               mrnn(d1.downloads,4)+' '+mrnn(d1.dk,5));
      dec(i);
    end;
    close(zf);
    AllowContinue := FALSE;
    Lasterror := IOResult;
  end;
end;

procedure showlogs;
var s:astr;
    day:integer;
begin
  print(^M^J'SysOp Logs available for up to '+cstr(general.backsysoplogs)+' days ago.');
  prt('Date (MM/DD/YYYY) or # days ago (0-'+cstr(general.backsysoplogs)+') [0] : ');
  input(s,10);
  if (length(s)=10) and (daynum(s)>0) then day:=daynum(date)-daynum(s)
    else day:=value(s);

  AllowContinue := TRUE;

  if (day=0) then
    printf(general.logspath+'sysop.log')
  else
    printf(general.logspath+'sysop'+cstr(day)+'.log');

  if (nofile) then
    print(^M^J'SysOp Log not found.');

  if (useron) then begin
    s:='Viewed SysOp Log - ';
    if (day=0) then s:=s+'Today''s' else s:=s+cstr(day)+' days ago';
    sysoplog(s);
  end;
end;

end.
