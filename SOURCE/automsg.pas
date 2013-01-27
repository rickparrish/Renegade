{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit Automsg;

interface

uses crt, dos, overlay, common;

procedure readamsg;
procedure wamsg;
procedure replyamsg;

implementation

uses mail0, Mail1, Email;

procedure readamsg;
var filv:text;
    s:astr;
    i,j:integer;
begin
  nl;
  assign(filv,general.miscpath+'auto.asc');
  reset(filv);
  nofile:=(ioresult<>0);
  j:=0;
  if (nofile) then print('^0No AutoMessage available.')
  else begin
    readln(filv,s);
    case s[1] of
      '@':if (aacs(general.anonpubread)) then
            s:=copy(s,2,length(s))+' (Posted Anonymously)'
            else s:='Anonymous';
      '!':if (CoSysOp) then s:=copy(s,2,length(s))+' (Posted Anonymously)'
                   else s:='Anonymous';
    end;
    print(fstring.automsgt+s);
    repeat
      readln(filv,s);
      if lennmci(s)>j then j:=lennmci(s);
    until (eof(filv));
    if (j>=thisuser.linelen) then j:=thisuser.linelen-1;
    reset(filv); readln(filv,s);
    UserColor(0);
    if ((not okansi and not okavatar and (ord(fstring.autom) > 128)) or (fstring.autom=#32)) then
      nl
    else
      begin
        for i := 1 to j do
          outkey(fstring.autom);
        nl;
      end;
    repeat
      readln(filv,s);
      printacr('^3'+s);
    until eof(filv) or (abort);
    UserColor(0);
    if ((not okansi and not okavatar and (ord(fstring.autom) > 128)) or (fstring.autom=#32)) then
      nl
    else
      for i := 1 to j do
        outkey(fstring.autom);
    nl;
    pausescr(FALSE);
    close(filv);
  end;
  Lasterror := IOResult;
end;

procedure wamsg;
var
  Mheader:mheaderrec;
  AutoMsg1,AutoMsg2:text;
  s:astr;
begin
  if (ramsg in thisuser.flags) then
    print('You are restricted from writing automessages.')
  else
    begin
     irt := '';
     if (InputMessage(TRUE, FALSE, 'Auto-Message',mheader, general.miscpath + 'auto.tmp')) then
       if exist(general.miscpath + 'auto.tmp') then
         begin
           assign(AutoMsg1, general.miscpath + 'auto.asc');
           assign(AutoMsg2, general.miscpath + 'auto.tmp');
           rewrite(AutoMsg1);
           reset(AutoMsg2);
           if (IOResult <> 0) then
             exit;
           if (aacs(general.anonpubpost)) and pynq('Post Anonymously? ') then
             if (CoSysOp) then
               writeln(AutoMsg1,'!' + caps(thisuser.name) + '#'+cstr(usernum))
             else
               writeln(AutoMsg1,'@' + caps(thisuser.name) + '#'+cstr(usernum))
           else
             writeln(AutoMsg1, caps(thisuser.name));

           while (not eof(AutoMsg2)) do
             begin
               readln(AutoMsg2,s);
               writeln(AutoMsg1,s);
             end;
           close(AutoMsg1);
           close(AutoMsg2);
           kill(general.miscpath + 'auto.tmp');
         end;
    end;
end;

procedure replyamsg;
var autof:text;
    s:astr;
    mheader:mheaderrec;
begin
  nl;
  mheader.status:=[];
  nofile:=FALSE;
  assign(autof,general.miscpath+'auto.asc');
  reset(autof);
  if (ioresult<>0) then print('Nothing to reply to.')
  else begin
    irt:='Your auto-message';
    readln(autof,s);
    lastauthor := searchuser(s, CoSysOp);
    close(autof);
    if (s[1] in ['!','@']) then
      if (not aacs(general.anonprivread)) then lastauthor:=0;
    if (lastauthor = 0) then print('Can''t reply to an anonymous message!') else autoreply(mheader);
  end;
end;
end.
