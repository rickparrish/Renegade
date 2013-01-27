{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit ShortMsg;

interface

uses crt, dos, overlay, common;

procedure rsm;
procedure ssm(dest:integer; const s:astr);

implementation

uses doors;

procedure ssm(dest:integer; const s:astr);
var u:userrec;
    x:smr;
begin
  if (dest > 0) and (dest <= MaxUsers) then
    begin
      reset(smf);
      if (ioresult = 2) then rewrite(smf);
      seek(smf,filesize(smf));
      x.msg:=s; x.destin:=dest;
      write(smf,x);
      close(smf);

      loadurec(u,dest);
      u.flags:=u.flags+[smw];
      saveurec(u,dest);
      Lasterror := IOResult;
    end;
end;

procedure rsm;
var x:smr;
    i:integer;

begin
  i:=0;
  reset(smf);
  thisuser.flags := thisuser.flags - [smw];
  if ioresult=0 then begin
    UserColor(1);
    repeat
      if (i<=filesize(smf)-1) then begin seek(smf,i); read(smf,x); end;
      while (i<filesize(smf)-1) and (x.destin<>usernum) do begin
        inc(i);
        seek(smf,i); read(smf,x);
      end;
      if (x.destin=usernum) and (i<=filesize(smf)-1) then begin
        print(x.msg);
        seek(smf,i); x.destin:=-1; write(smf,x);
        smread:=TRUE;
      end;
      inc(i);
    until (i>filesize(smf)-1) or hangup;
    close(smf);
    UserColor(1);
  end;
  saveurec(thisuser, usernum);
  Lasterror := IOResult;
end;

end.
