{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Various miscellaneous functions used by the BBS. }

unit SysChat;

interface

uses crt, dos, overlay, common;

procedure reqchat(const x:astr);
procedure chatfile(b:boolean);
procedure chat;
procedure inli1(var s:string);

implementation

Uses Email, TimeFunc, Event;

procedure reqchat(const x:astr);
var ii:byte;
    i:integer;
    r:char;
    chatted:boolean;
    s,why:astr;
    u:userrec;
    mheader:mheaderrec;

begin
  mheader.status:=[];
  why:=fstring.chatreason;
  if (pos(';',x)<>0) then why:=copy(x,pos(';',x)+1,length(x));
  nl;
  if (chatt<general.maxchat) or (CoSysOp) then begin
    print(why);
    chatted:=FALSE;

    prt(':'); mpl(60); inputl(s,60);

    if (s<>'') then begin
      inc(chatt);
      sysoplog('^4Chat attempt:');
      sl1(s);
      if not (sysopavailable) and aacs(general.overridechat) then
        printf('chatovr');
      if (sysopavailable) or (aacs(general.overridechat) and pynq(^M^J'SysOp is not available. Override ? ')) then begin
        status_screen(100,'Press [SPACE] to chat or [ENTER] for silence.',false,s);
        print(fstring.chatcall1);
        ii:=0;  abort := FALSE;
        repeat
          inc(ii);
          wkey;
          if (outcom) then com_tx(^G);
          prompt(fstring.chatcall2);
          if (outcom) then com_tx(^G);
          if (shutupchatcall) then delay(600)
          else
            begin
{$IFDEF MSDOS}	
              For i := 300 downto 2 Do
                Begin
                  Delay(1);
                  Sound(i * 10);
                End;
              For i := 2 to 300 do
                Begin
                  Delay(1);
                  Sound(i * 10);
                End;
              nosound;
{$ENDIF}
{$IFDEF WIN32}
              sound(3000, 200);
			  sound(1000, 200);
			  sound(3000, 200);
{$ENDIF}
            end;
          if (keypressed) then begin
            r:=readkey;
            case r of
               #0:begin
                    r := readkey;
                    skey1(r);
                  end;
              #32:begin
                    chatted:=TRUE; chatt:=0;
                    chat;
                  end;
               ^M:shutupchatcall:=TRUE;
            end;
          end;
        until (abort) or (chatted) or (ii=9) or (hangup);
      end;
      status_screen(100,'Chat Request: '+s,FALSE,s);
      if (not chatted) then begin
        chatr:=s;
        printf('nosysop');
        i := value(x);
        if (i > 0) then begin
          irt:=#1'Tried chatting';
          loadurec(u, i);
          nl;
          if pynq('Send mail to '+caps(u.name)+'? ') then semail(i, mheader);
        end;
      end else
        chatr:='';
      tleft;
    end;
  end else begin
    printf('goaway');
    i := value(x);
    if (i > 0) then
      begin
        irt:='Tried chatting (more than '+cstr(general.maxchat)+' times!)';
        sysoplog(irt);
        semail(value(x),mheader);
      end;
  end;
end;

procedure chatfile(b:boolean);
var
  s:string[91];
begin
  s:='chat';
  if (chatseparate in thisuser.sflags) then s:=s+cstr(usernum);
  s:=general.logspath+s+'.log';
  if (not b) then begin
    if (cfo) then begin
      status_screen(100,'Chat recorded to '+s,FALSE,s);
      cfo:=FALSE;
      if (textrec(cf).mode<>fmclosed) then close(cf);
    end;
  end else begin
    cfo:=TRUE;
    if (textrec(cf).mode=fmoutput) then close(cf);
    assign(cf,s);
    append(cf);
    if (ioresult = 2) then
      rewrite(cf);
    if (ioresult <> 0) then
      sysoplog('Cannot open chat log file: ' + s);
    status_screen(100,'Recording chat to '+s,FALSE,s);
    s:='Chat reason: ';
    if (chatr = '') then
      s := s + 'None'
    else
      s := s + chatr;
    writeln(cf,^M^J^M^J+dat+^M^J+'Recorded with user: '+caps(thisuser.name)+
               ^M^J+s+^M^J+'------------------------------------'+^M^J);
  end;
end;

procedure chat;
var
    ChatTime:longint;
    xx:string;
    i:integer;
    c:char;
    OldAvail,savecho,savprintingfile,savemciallowed:boolean;
begin
  UserColor(1);
  savemciallowed:=mciallowed;
  mciallowed:=TRUE;
  ChatTime := getpackdatetime;
  dosansion:=FALSE;

  if General.MultiNode then
    begin
      loadnode(node);
      OldAvail := (NAvail in Noder.Status);
      Noder.Status := Noder.Status - [NAvail];
      savenode(node);
    end;

  savprintingfile:=printingfile;
  ch:=TRUE; chatcall:=FALSE; savecho:=echo; echo:=TRUE;
  if (general.autochatopen) then chatfile(TRUE)
     else if (chatauto in thisuser.sflags) then chatfile(TRUE);
  nl;
  thisuser.flags:=thisuser.flags-[alert];

  printf('chatinit');
  if (nofile) then
    prompt('^5'+fstring.engage);

  UserColor(general.sysopcolor); wcolor:=TRUE;

  if (chatr <> '') then
    begin
      status_screen(100,chatr,FALSE,xx);
      chatr:='';
    end;
  repeat
    inli1(xx);
    if (xx[1]='/') then xx:=allcaps(xx);
    if (copy(xx,1,6)='/TYPE ') and (so) then begin
      xx:=copy(xx,7,length(xx));
      if (xx<>'') then begin
        printfile(xx);
        if (nofile) then print('*File not found*');
      end;
    end
    else if ((xx='/HELP') or (xx='/?')) then begin
      nl;
      if so then
        print('^5/TYPE d:\path\filename.ext^3: Type a file');
      print('^5/BYE^3:   Hang up');
      print('^5/CLS^3:   Clear the screen');
      print('^5/PAGE^3:  Page the SysOp and User');
      print('^5/Q^3:     Exit chat mode'^M^J);
    end
    else if (xx='/CLS') then cls
    else if (xx='/PAGE') then begin
{$IFDEF MSDOS}
      for i:=650 to 700 do begin
        sound(i); delay(4);
        nosound;
      end;
      repeat
        dec(i); sound(i); delay(2);
        nosound;
      until (i=200);
{$ENDIF}
{$IFDEF WIN32}
      sound(650, 200);
	  sound(700, 200);
	  sound(600, 200);
	  sound(500, 200);
	  sound(400, 200);
	  sound(300, 200);
{$ENDIF}	 
      prompt(^G^G);
    end

    else if (xx='/BYE') then begin
      print('Hanging up...');
      hangup:=TRUE;
    end
    else if (xx='/Q') then begin
      ch:=FALSE;
      print('Chat Aborted...');
    end;
    if (cfo) then writeln(cf,xx);
  until ((not ch) or (hangup));

  printf('chatend');
  if (nofile) then
    print(^M^J'^5'+fstring.endchat);


  if General.MultiNode then
    begin
      loadnode(node);
      if OldAvail then
        Noder.Status := Noder.Status + [NAvail];
      savenode(node);
    end;

  ChatTime := getpackdatetime - ChatTime;

  if (choptime = 0) then
    inc(freetime,ChatTime);

  tleft;
  xx:='Chatted for ' + FormattedTime(ChatTime);
  if (cfo) then begin
    xx:=xx+'  -{ Recorded in CHAT';
    if (chatseparate in thisuser.sflags) then xx:=xx+cstr(usernum);
    xx:=xx+'.LOG }-';
  end;
  sysoplog(xx);
  ch:=FALSE; echo:=savecho;
  if ((hangup) and (cfo)) then
    writeln(cf,^M^J'=> User disconnected'^M^J);
  printingfile:=savprintingfile;
  if (cfo) then chatfile(FALSE);
  if invisedit then buf := ^L;
  mciallowed:=savemciallowed;
end;


procedure inli1(var s:string);             (* Input routine for chat *)
var cv,cc,cp,g,j:integer;
    c,c1:char;
begin
  cp:=1;
  s:='';
  if (ll<>'') then begin
      prompt(ll);
    s:=ll; ll:='';
    cp:=length(s)+1;
  end;
  repeat
    c := char(getkey);
    checkhangup;
    case ord(c) of
      32..255:if (cp < 79) then begin
                s[cp]:=c; inc(cp);
                outkey(c);
                if (trapping) then write(trapfile,c);
              end;
      16:if (okansi or okavatar) then
           begin
             c1 := char(getkey);
             UserColor(ord(c1) - 48);
           end;
      27:if (cp < 79) then begin
           s[cp]:=c; inc(cp);
           outkey(c);
           if (trapping) then write(trapfile,c);
         end;
      8:if (cp>1) then begin
          dec(cp);
          backspace;
        end;
      24:begin
           for cv:=1 to cp-1 do backspace;
           cp:=1;
         end;
       7:if (outcom) then com_tx(^G);
      23:if cp>1 then
           repeat
             dec(cp);
             backspace;
           until (cp=1) or (s[cp]=' ');
       9:begin
           cv:=5-(cp mod 5);
           if (cp+cv<79) then
             for cc:=1 to cv do begin
               s[cp]:=' ';
               inc(cp);
               prompt(' ');
             end;
         end;
  end;
  until ((c=^M) or (cp=79) or (hangup) or (not ch));
  if (not ch) then begin c:=#13; ch:=FALSE; end;
  s[0]:=chr(cp-1);
  if (c<>^M) then begin
    cv:=cp-1;
    while (cv>0) and (s[cv]<>' ') and (s[cv]<>^H) do dec(cv);
    if (cv>(cp div 2)) and (cv<>cp-1) then begin
      ll:=copy(s,cv+1,cp-cv);
      for cc:=cp-2 downto cv do prompt(^H);
      for cc:=cp-2 downto cv do prompt(' ');
      s[0]:=chr(cv-1);
    end;
  end;
  if (wcolor) then j:=1 else j:=2;
  nl;
end;

end.
