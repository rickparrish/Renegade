{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit email;

interface

uses crt, dos, overlay, common, timefunc;

procedure ssmail(var mstr:astr);
procedure smail(massmail:boolean);
procedure semail(x:integer; replyheader:mheaderrec);
procedure autoreply(replyheader:mheaderrec);
procedure readmail;
procedure mailr;
procedure showemail;

implementation

uses mail0, mail1, mail6, sysop3, ShortMsg, Nodelist, User;

procedure ssmail(var mstr:astr);
var
  mheader:mheaderrec;
begin
  irt := '';
  mheader.status := [];
  if (pos(';',mstr) = 0) and (mstr <> '') then
    irt := #1'Feedback'
  else
    if (mstr <> '') then
      if (mstr[pos(';', mstr) + 1] = '\') then
        irt := '\' + #1 + copy(mstr, pos(';',mstr) + 2, 255)
      else
        irt := #1 + copy(mstr,pos(';',mstr) + 1, 255);
  if (value(mstr) < 1) then
    smail(FALSE)
  else
    semail(value(mstr),mheader);
end;

procedure smail(massmail:boolean);
var u,u2:userrec;
    mheader:mheaderrec;
    na:array[1..50] of word;
    massacs,s:astr;
    i,nac,x:integer;
    stype:byte;
    c:char;
    ok:boolean;
    Fee:word;

  procedure checkitout(var x:integer; showit:boolean);
  var i,ox:integer;
      b:boolean;

    procedure unote(s:astr);
    begin
      if (showit) then
        print('[> '+caps(u.name)+' #'+cstr(x)+': '+s);
    end;

  begin
    ox:=x;
    if ((x<1) or (x>maxusers)) then begin x:=0; exit; end;
    loadurec(u,x);

    if (u.waiting = 255) or (nomail in u.flags) then
      begin
        x:=0;
        print('Can''t send mail to that user.');
        exit;
      end;
    i:=u.forusr;
    if (i < 1) or (i >= maxusers) then i:=0;
    if (i<>0) then begin
      loadurec(u2,i);
      unote('Mail forwarded to '+caps(u2.name)+'.');
      x:=i;
    end;
    if (showit) then
      for i:=1 to 50 do
        if (na[i]=x) then begin
          unote('Can''t send more than once.');
          x:=0; exit;
        end;
    if (ox<>x) then
      if ((ox>=1) and (ox<=maxusers-1)) then begin
        loadurec(u,ox);
      end;
  end;

  procedure sendit(x:integer);
  begin
    checkitout(x,FALSE);
    if (x=0) or (x=usernum) then exit;

    if ((x>=1) and (x<=maxusers-1)) then begin
      loadurec(u,x);
      if (x=1) then begin
        inc(thisuser.feedback);
        inc(ftoday);
      end else begin
        inc(thisuser.emailsent);
        AdjustBalance(General.CreditEmail);
        inc(etoday);
      end;
      inc(u.waiting);
      saveurec(u,x);
    end;

    with mheader.mto do begin
      usernum:=x;
      as:=allcaps(u.name);
      real:=allcaps(u.realname);
      name:=allcaps(u.name);
    end;
    saveheader(himsg+1,mheader);
  end;

  procedure doit;
  var s:string[80];
      i,x:integer;
  begin
    initboard(-1);
    fillchar(mheader,sizeof(mheader),0);
    mheader.mto.as:='Mass mail';
    mheader.mto.real:=mheader.mto.as;
    if (not InputMessage(FALSE,TRUE,'',mheader,'')) then exit;
    case stype of
      0:begin
          print(^M^J'Sending mass-mail to:');
          sysoplog('Mass-mail sent to:');
          for i:=1 to nac do begin
            sendit(na[i]);
            s:='   '+caps(u.name);
            sysoplog(s); print(s);
          end;
        end;
      1:begin
          print(^M^J'Sending mass-mail to:');
          sysoplog('Mass-mail sent to: (by ACS "'+massacs+'")');
          x:=maxusers;
          for i:=1 to x-1 do begin
            loadurec(u,i);
            if (aacs1(u,i,massacs)) and not (deleted in u.sflags) then begin
              sendit(i); s:='   '+caps(u.name);
              sysoplog(s); print(s);
            end;
          end;
        end;
      2:begin
          print('Sending mass-mail to ALL USERS.');
          sysoplog('Mass-mail sent to ALL USERS.');
          for i:=1 to maxusers-1 do
            begin
              loadurec(u,i);
              if not (deleted in u.sflags) then
                sendit(i);
            end;
        end;
    end;
  end;

begin
  if ((remail in thisuser.flags) or (not (aacs(general.normprivpost)))) then begin
    print('Your access privledges do not include sending mail.'^M^J);
    exit;
  end else
    if ((etoday>=general.maxprivpost) and (not CoSysOp)) then
      begin
        print('Too much mail already sent today.'^M^J);
        exit;
      end
    else
      if (AccountBalance < General.CreditEmail) and (General.CreditEmail > 0) and
          not (fnocredits in thisuser.flags) then
        begin
          print('Insufficient account balance to send email.'^M^J);
          exit;
        end;

  if (not massmail) then begin
    if aacs(general.netmailacs) then
      ok := pynq(^M^J'Is this to be a netmail message? ')
    else
      ok := FALSE;

    if not ok then begin
      print(^M^J'^1Enter user number, user name, or partial search string:');
      prt(':'); finduserws(x);
      mheader.status:=[];
      if (x>0) then semail(x,mheader);
    end else begin
      printf('netmhelp');
      S := '';

      with mheader.from do
        GetNetAddress(S,Zone,Net,Node,Point,Fee, FALSE);

      if (s = '') then exit;
      mheader.from.name:=s;
      mheader.status:=[netmail];
      x := thisuser.emailsent;
      semail(0,mheader);
      if (thisuser.emailsent > x) then
        inc(thisuser.debit, Fee);
    end;
  end else begin
    print('Mass mail: Send mail to multiple users.'^M^J);
    irt := '';
    if (CoSysOp) then
      begin
        print('(1) Send to users with a certain ACS.');
        print('(2) Send to all system users.');
        print('(3) Send mail to a list of users.'^M^J);

        prt('Your choice: ');
        onek(c,'123'^M);
        if c=#13 then exit;
      end
    else
      c := '3';
    ok:=FALSE; nac:=0; stype:=0;
    fillchar(na[1],sizeof(na),0);
    nl;
    case c of
      '1':begin
            stype:=1;
            prt('Enter ACS: '); inputl(massacs,160);
            if (massacs='') then exit;
            i:=1;
            print(^M^J'Users marked by ACS "'+massacs+'":');
            abort:=FALSE; next:=FALSE;
            reset(uf);
            x:=filesize(uf);
            while ((i<=x-1) and (not abort)) do begin
              loadurec(u,i);
              if (aacs1(u,i,massacs)) then
                print('   '+caps(u.name));
              inc(i); wkey;
            end;
            close(uf);
          end;
      '2':begin
            print('All users marked for mass-mail.');
            stype:=2;
          end;
      '3':begin
            print('Begin entering user names, numbers, or partial search strings for users');
            print('you want to mail. Enter a blank line to stop entering names.'^M^J);

            x:=1;
            while (x <> 0) and (nac < 50) do begin
               prt('Search string: ');
               finduserws(x);
               nl;
               for i := 1 to nac do
                 if (na[nac] = x) then x := 0;
               if (x > 0) then
                 begin
                   inc(nac);
                   na[nac] := x;
                 end;
            end;
            if (nac > 0) then
              begin
                print('Users marked:');
                abort:=FALSE; next:=FALSE;
                reset(uf);
                for i:=1 to nac do
                  begin
                    loadurec(u,na[i]);
                    print('   '+caps(u.name));
                  end;
                close(uf);
              end;
          end;
    end;
    nl;
    if pynq('Is this OK? ') then doit;
  end;
  saveurec(thisuser, usernum);
end;

procedure semail(x:integer; replyheader:mheaderrec);
var u:userrec;
    mheader:mheaderrec;
    fto:string[80];
    i,t:integer;
    a:anontyp;
    s:astr;
    b,ok:boolean;
    xbread:word;
    c:char;

  procedure nope(s:astr);
  begin
    if ok then
      print(^M^J + s);
    ok:=FALSE;
  end;

begin
  ok:=TRUE;
  if not (netmail in replyheader.status) then begin
    if (x < 0) or (x >= maxusers) then exit;

    mheader.status:=[];

    loadurec(u,x);
    nl;
    if ((remail in thisuser.flags) or (not aacs(general.normprivpost))) and
       (not CoSysOp) then
      nope('Your access privledges do not include sending mail.');
    if (AccountBalance < General.CreditEmail) and not (fnocredits in thisuser.flags) then
      nope('Insufficient account balance to send email.');
    if (etoday>=general.maxprivpost) and (not CoSysOp) then
      nope('Too much mail sent today.');
    if ((x=1) and (ftoday>=general.maxfback) and (not CoSysOp)) then
      nope('Too much feedback sent today.');

    if (u.waiting = 255) or (nomail in u.flags) and not CoSysOp or (not ok) then
      exit;

    if ((u.forusr<1) or (u.forusr>maxusers-1)) then u.forusr:=0;

    if (u.forusr>0) then begin
       x:=u.forusr;
       loadurec(u,x);
       if (CoSysOp) then
         begin
           print('That user is forwarding his mail to '+caps(u.name)+'.');
           if not pynq('Send mail to '+caps(u.name) + ' ? ') then exit;
         end;
    end;
  end else begin
    if not aacs(general.netmailacs) then begin
       print(^M^J'You are not authorized to send netmail.');
       pausescr(FALSE);
       exit;
    end;
    u.name:=replyheader.from.name;
    u.realname:=replyheader.from.name;
    x:=0;
    mheader.status:=[netmail];
  end;

  xbread:=readboard;
  initboard(-1);
    with mheader.mto do begin
      usernum:=x;
      as:=allcaps(u.name);
      real:=allcaps(u.realname);
      name:=allcaps(u.name);
    end;

  if (InputMessage(FALSE,TRUE,'',mheader,'')) then begin
    if (netmail in replyheader.status) then begin
        mheader.status := mheader.status+[netmail];
        mheader.netattribute := General.netattribute *
          [intransit, private, crash, killsent, hold, local];

        ChangeFlags(mheader);
        t := 0;
        i := 0;
        while (i <= 9) and (t = 0) do
          begin
            if (General.aka[i].zone = replyheader.from.zone) and
               (General.aka[i].zone <> 0) then
               t := i;
            inc(i);
          end;
        if (CoSysop) and (General.aka[t].zone <> replyheader.from.zone) then
          begin
            for i := 0 to 19 do
               if (General.aka[i].net > 0) then
                 begin
                   s := cstr(General.aka[i].zone) + ':' +
                        cstr(General.aka[i].net)  + '/' +
                        cstr(General.aka[i].node);
                   if (General.aka[i].point > 0) then
                     s := s + '.' + cstr(General.aka[i].point);
                   printacr(mn(i+1,2)+'. ' + s);
                 end;
            prt(^M^J'Use which aka: '); mpl(5); inu(i);
            if (i >= 1) or (i <= 20) then t := i - 1;
            nl;
          end;

        mheader.from.zone:=General.aka[t].zone;
        mheader.from.net:=General.aka[t].net;
        mheader.from.node:=General.aka[t].node;
        mheader.from.point:=General.aka[t].point;
        mheader.mto.zone:=replyheader.from.zone;
        mheader.mto.net:=replyheader.from.net;
        mheader.mto.node:=replyheader.from.node;
        mheader.mto.point:=replyheader.from.point;
    end;
    if (x=1) then begin
      inc(thisuser.feedback);
      inc(ftoday);
    end else begin
      inc(thisuser.emailsent);
      AdjustBalance(General.CreditEmail);
      inc(etoday);
    end;

    if ((x>=1) and (x<=maxusers-1)) then begin
      loadurec(u,x);
      inc(u.waiting);
      saveurec(u,x);
    end;

    saveheader(himsg+1,mheader);

    if (netmail in mheader.status) then s:='Netm' else s:='M';

    s:=s+'ail sent to '+caps(u.name);
    if (useron) then sysoplog(s);
    print(s + ^M^J);
    update_screen;
  end;
  initboard(xbread);
  saveurec(thisuser, usernum);
end;

procedure autoreply(replyheader:mheaderrec);
var
  s:string[255];
  Fee:word;
  x:longint;
begin
  if aacs(general.netmailacs) and not (netmail in replyheader.status) and
     pynq(^M^J'Is this to be a netmail message? ') then begin
       replyheader.status:=[netmail];
       lastauthor:=0;

       if (mbrealname in memboard.mbstat) then
         S := replyheader.from.real
       else
         S := replyheader.from.as;

       S := usename(replyheader.from.anon,S);

       with replyheader.from do
          GetNetAddress(S,Zone,Net,Node,Point,Fee, FALSE);

      if (s = '') then exit;

      replyheader.from.name:=s;
      nl;
      replyheader.status:=[netmail];
    end;

  x := thisuser.emailsent + thisuser.feedback;

  if (lastauthor = 0) and not (netmail in replyheader.status) then
    begin
      lastauthor := searchuser(replyheader.from.as, TRUE);
      if (lastauthor = 0) then
        print('That user does not have an account here.')
      else
        semail(lastauthor, replyheader);
    end
  else
    begin
      semail(lastauthor,replyheader);
      if (thisuser.emailsent + thisuser.feedback > x) then
        if (Netmail in replyheader.status) then
          begin
            with replyheader.from do
              GetNetAddress(S,Zone,Net,Node,Point,Fee, TRUE);
            inc(thisuser.debit, Fee)
          end
        else
          begin
            if (replyheader.fileattached > 0) then
              s := stripname(replyheader.subject)
            else
              s := replyheader.subject;
            ssm(replyheader.from.usernum,
                Caps(Thisuser.name)+' replied to "' + s + '" on '+date+' '+time+'.');
          end;
    end;
end;

procedure readmail;
var u:userrec;
    msgnum:array[1..255] of longint;
    totload,tempptr:longint;
    mheader:mheaderrec;
    s:string;
    s1:astr;
    i,j:integer;
    OldActivity,snum,mnum:byte;
    dt:datetime;
    c:char;
    b,done,dotitles,holdit,noreshow:boolean;
    xbread:word;

  procedure removecurrent;
  var
    j:byte;
  begin
    dec(mnum);
    for j := snum to mnum do
      begin
        msgnum[j]:=msgnum[j+1];
      end;
    if (snum > mnum) then
      snum := mnum;
  end;

  procedure rescan;
  var
    i,q:integer;
  begin
    initboard(-1);
    reset(msghdrf);
    q := filesize(msghdrf);
    i := 1;
    mnum := 0;
    while (i <= q) do
      begin
        loadheader(i,mheader);
        if ((mheader.mto.usernum=usernum) and not
           (mdeleted in mheader.status)) then
          begin
            inc(mnum);
            msgnum[mnum] := i;
          end;
        inc(i);
      end;
    close(msghdrf);
    thisuser.waiting := 0;
    saveurec(thisuser,usernum);
    Lasterror := IOResult;
  end;

begin
  readingmail:=TRUE;
  dotitles:=TRUE;
  OldActivity := update_node(5);
  xbread:=readboard;

  rescan;

  if (mnum=0) then begin
     print(^M^J'^5You have no mail waiting.');
     if (novice in thisuser.flags) then
       pausescr(FALSE);
     readingmail:=false;
     update_node(OldActivity);
     initboard(xbread);
     exit;
  end;

  repeat
    if (dotitles) then begin
      abort:=FALSE; next:=FALSE;
      cls;
      printacr('‡ÚÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
      printacr('‡³ˆ Num ‡³‰ Date/Time         ‡³Š Sender                 ‡³‹ Subject                  ‡³');
      printacr('‡ÀÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
      i:=1;
      while (i<=mnum) do begin
        loadheader(msgnum[i],mheader);
        packtodate(dt,mheader.date);
        with dt do begin
          j:=hour;
          if (j>12) then dec(j,12);
          if (j=0) then j:=12;
          s:=Zeropad(cstr(j))+':'+Zeropad(cstr(min))+aonoff((hour>=12),'p','a');
           s:=Zeropad(cstr(day))+' '+copy(MonthString[month],1,3)+
             ' '+cstr(year)+'  '+s;
        end;
        s1:=Usename(mheader.from.anon,mheader.from.as);
        if (mheader.from.anon in [1,2]) then begin
          case mheader.from.anon of
            1:b:=aacs(general.anonprivread);
            2:b:=aacs(general.csop);
          end;
          if (b) then
            s1:=s1+' ('+caps(mheader.from.name)+')'
          else
            s:='                   ';
        end;
        if mheader.fileattached = 0 then
          printacr('Œ'+mrn(cstr(i),5)+'  '+s+' Ž'+mln(s1,23)+'  '+copy(mheader.subject,1,25))
        else
          printacr('Œ'+mrn(cstr(i),5)+'  '+s+' Ž'+mln(s1,23)+'  '+copy(stripname(mheader.subject),1,25));
        inc(i);
        wkey;
      end;
      nl;


      abort:=FALSE; done:=FALSE; next:=FALSE;
      repeat
        prt('Select message (^51^4-^5'+cstr(mnum)+'^4) : ');
        scaninput(s,'Q');
        i:=value(s);
        if ((i>=1) and (i<=mnum)) then snum:=i-1
           else snum:=0;
        if s[1]='Q' then begin
             if (rmsg in thisuser.flags) and (not CoSysOp) and (mnum>0) and (not inwfcmenu) then begin
                 print(^M^J'Sorry, you must read and reply to (or delete) your mail.'^M^J);
                 snum:=0;
              end else abort:=TRUE;
        end;
        done:=((abort) or (snum>-1));
      until ((done) or (hangup));
      if (abort) then begin
        readingmail:=false;
        update_node(OldActivity);
        inc(thisuser.waiting,mnum);
        initboard(xbread);
        exit;
      end;
    end;

    done:=FALSE;   dotitles:=FALSE;
    holdit:=FALSE; noreshow:=FALSE;
    c:=#0;

    repeat
      if (not holdit) then begin
         inc(snum);
         if snum>mnum then snum:=1;
      end;
      if (c='-') then
        if (snum>1) then
          dec(snum,1)
        else
          snum := 1;
      done:=FALSE;
      loadheader(msgnum[snum],mheader);
      while (mdeleted in mheader.status) and (snum>0) do begin
         removecurrent;
         if snum>0 then loadheader(msgnum[snum],mheader);
      end;
      if (snum > 0) then begin
        if (not noreshow) then
          begin
            cls;
            readmsg(msgnum[snum],snum,mnum);
            nl;
          end
        else
          noreshow:=FALSE;
        if (not next) then begin
          prt(fstring.readingemail);
          s:='Q?-ADFGRNL'^M;
          if (CoSysOp) then s:=s+'SUVXZM';
          onek(c,s);
        end else
          c:='N';
        abort:=FALSE; holdit:=TRUE; next:=FALSE;
        if (c in ['S','Q']) and (rmsg in thisuser.flags) and
           (not CoSysOp) and (mnum>0) and (not hangup) and (not inwfcmenu) then
           begin
             print(^M^J'Sorry, you must read and reply to (or delete) your mail.'^M^J);
             noreshow:=TRUE;
             c:='A';
           end;
        case c of
          '-':holdit:=TRUE;
          'U':if (CoSysOp) and (lastauthor <> 0) and checkpw then uedit(lastauthor);
          'F':begin
                prt(^M^J'Forward letter to which user? '); finduserws(i);
                if (i<1) then print('Unknown user.')
                else
                if (i<>usernum) then begin
                  loadurec(u, i);

                  if ((u.waiting < 255) and not (nomail in u.flags)) or CoSysOp then begin
                    mheader.mto.usernum:=i;
                    mheader.mto.as := u.name;
                    mheader.mto.name := u.name;
                    mheader.mto.real := u.realname;

                    reset(msgtxtf, 1);
                    totload:=0; tempptr := mheader.pointer - 1;
                    mheader.pointer := filesize(msgtxtf) + 1;

                    i := 0;
                    s := 'Message forwarded from ' + caps(Thisuser.name);
                    seek(msgtxtf, filesize(msgtxtf));
                    inc(i, length(s) + 1);
                    blockwrite(msgtxtf, s, i);
                    s := 'Message forwarded on '+date+' at '+time;
                    inc(i, length(s) + 1);
                    blockwrite(msgtxtf, s, length(s) + 1);
                    s := '';
                    blockwrite(msgtxtf, s, 1);
                    inc(i);

                    repeat
                      seek(msgtxtf, tempptr + totload);
                      blockread(msgtxtf,s[0],1);
                      blockread(msgtxtf,s[1],ord(s[0]));
                      Lasterror := IOResult;
                      seek(msgtxtf, filesize(msgtxtf));
                      blockwrite(msgtxtf,s,length(s)+1);
                      inc(totload, length(s)+1);
                    until (totload>=mheader.textsize);
                    close(msgtxtf);

                    inc(mheader.textsize, i);

                    saveheader(himsg+1, mheader);
                    loadheader(msgnum[snum], mheader);

                    loadurec(u, mheader.mto.usernum);
                    inc(u.waiting);
                    saveurec(u, mheader.mto.usernum);

                    print(^M^J'A copy of this letter has been forwarded.'^M^J);
                    pausescr(FALSE);
                    sysoplog('Forwarded letter to '+caps(u.name));
                  end;
                end;
              end;
          'G':begin
                prt('Goto message? (1-'+cstr(mnum)+') : '); inu(i);
                if ((not badini) and (i>=1) and (i<=mnum)) then
                  begin holdit:=FALSE; snum:=i-1; end;
              end;
          'N',^M:holdit:=FALSE;
          'Q':done:=TRUE; {begin; readingmail:=false; update_node(OldActivity); exit; end;}
          'A':;
          'L':dotitles:=TRUE;
          'S':if (CoSysOp) then
                if (lastauthor<>0) then begin
                  noreshow:=TRUE;
                  nl;
                  i:=lastauthor;
                  if (i<>0) then begin
                    if (i>0) and (i<=maxusers-1) then begin
                       loadurec(u,i);
                       showuserinfo(1,i,u);
                    end else print('^7Unable to find user!');
                    nl;
                  end;
                end;
          'V':if (CoSysOp) then
                if (lastauthor<>0) then begin
                  noreshow:=TRUE;
                  nl;
                  i:=lastauthor;
                  if (i>0) and (i<=maxusers-1) then begin
                    loadurec(u,i);
                    autoval(u,i);
                    saveurec(u,i);
                    sysoplog('Validated '+caps(u.name));
                    ssm(mheader.from.usernum,^G+'You were validated on '+date+' '+time+'.'^G);
                    nl;
                  end else
                     print('^7Unable to find user!')
                end;
          'X':if (CoSysOp) then extract(msgnum[snum]);
  'R','D','Z':begin
                if (c = 'R') then
                  if (mheader.from.anon in [1,2]) then
                    begin
                      case mheader.from.anon of
                        1:b:=aacs(general.anonprivread);
                        2:b:=aacs(general.csop);
                      end;
                    end;

                if (c='R') and not (netmail in mheader.status) then begin
                  i:=mheader.from.usernum;
                  if ((i>=1) and (i<=maxusers-1)) then loadurec(u,i);
                end;

                b := ((u.waiting < 255) and not (nomail in u.flags)) or CoSysOp;

                if b and not (netmail in mheader.status) then
                  begin
                   if (mheader.fileattached > 0) then
                     s := stripname(mheader.subject)
                   else
                     s := mheader.subject;
                   if c='D' then ssm(abs(mheader.from.usernum),
                          Caps(Thisuser.name)+' read "' + s + '" on '+date+' '+time+'.');
                  end;

                if (c='R') and (b) then begin
                  dumpquote(mheader);
                  autoreply(mheader);
                  dyny:=TRUE;
                  if pynq('Delete original message? ') then c:='D';
                end;

                if (c in ['D','Z']) then
                  begin
                    b := TRUE;
                    if (mheader.fileattached > 0) then
                      begin
                        for i := 1 to NumBatchFiles do
                          if (BatchDLQueue[i]^.FileName = mheader.subject) then
                            begin
                              print(^M^J'If you delete this message, you will not be able to download the attached');
                              print('file currently in your batch queue.'^M^J);
                              if not pynq('Continue with deletion? ') then
                                b := FALSE;
                            end;
                      end;
                    if (b) then
                      begin
                        mheader.status:=mheader.status+[mdeleted];
                        if (mheader.fileattached = 1) then
                          kill(mheader.subject);
                        saveheader(msgnum[snum], mheader);
                        removecurrent;
                      end;
                  end;

              end;
          'M':begin
                movemsg(msgnum[snum]);
                loadheader(msgnum[snum],mheader);
                if (mdeleted in mheader.status) then
                  removecurrent;
              end;
          '?':begin
                nl;
                lcmds(19,3,'Next letter','-Previous letter');
                lcmds(19,3,'Goto letter','Forward letter');
                lcmds(19,3,'Delete letter','Reply to author');
                lcmds(19,3,'Again','List messages');
                if (CoSysOp) then begin
                  lcmds(19,5,'user editor','Show Author''s account');
                  lcmds(19,5,'Validate author','Zap (delete w/o receipt)');
                  lcmds(19,5,'Xtract msg to file','Move message');
                end;
                lcmds(19,5,'Quit Email','');
                nl;
                noreshow:=TRUE;
              end;
        end;
      end;
      if mnum=0 then done:=TRUE;
    until (done) or (dotitles) or (hangup);
  until (done);
  inc(thisuser.waiting,mnum);
  readingmail:=FALSE;
  update_node(OldActivity);
  initboard(xbread);
end;

procedure mailr;
var mheader:mheaderrec;
    j:integer;
    i:longint;
    c:char;
    gonext,contlist:boolean;
    u:userrec;
begin
  readingmail:=TRUE;
  contlist:=FALSE; gonext:=FALSE;
  initboard(-1);
  i:=1; c:=#0;
  {if ((clsmsg in thisuser.sflags) and (i>=1)) then nl;}
  while ((i <= himsg) and (c <> 'Q') and (not hangup)) do begin
    loadheader(i,mheader);
    gonext:=FALSE;
    repeat
      if (c<>'?') then begin
        {if ((clsmsg in thisuser.sflags) and (not contlist)) then} cls;
        readmsg(i,i,himsg);
        nl;
      end;
      if (not contlist) or ((abort) and (not next)) then begin
        if (contlist) then begin
          print('Continuous message listing off.'^M^J);
          contlist:=FALSE;
        end;
        prt('Mail read (?=help) : '); onek(c,'Q-ACDGINRUXE?'^M^N);
      end else
        c:='I';
      case c of
        '?':begin
              print(^M^J'^1<^3CR^1>Next msg      (^3A^1)gain');
              lcmds(16,3,'Ignore message','-Previous message');
              lcmds(16,3,'Goto message','Continuous listing');
              lcmds(16,3,'Delete message','Xtract to file');
              lcmds(16,3,'Edit message','Reply to message');
              lcmds(16,3,'user editor','Quit');
              nl;
            end;
        'U':if CoSysOp and checkpw and (LastAuthor <> 0) then
              uedit(LastAuthor);
        'E':editmessage(i);
        'X':extract(i);
        '-':if (i > 1) then dec(i);
        'C':begin
              print(^M^J'Continuous message listing on.');
              contlist:=TRUE;
            end;
        'D':if not (mdeleted in mheader.status) then begin
              sysoplog('* Deleted mail from ' + mheader.from.as);
              mheader.status := mheader.status + [mdeleted];
              saveheader(i,mheader);
              loadurec(u, mheader.mto.usernum);
              if (u.waiting > 0) then
                dec(u.waiting);
              saveurec(u, mheader.mto.usernum);
              print('Mail deleted.');
            end else begin
              sysoplog('* Undeleted mail from ' + mheader.from.as);
              mheader.status := mheader.status - [mdeleted];
              saveheader(i,mheader);
              loadurec(u, mheader.mto.usernum);
              if (u.waiting > 255) then
                inc(u.waiting);
              saveurec(u, mheader.mto.usernum);
              print('Mail undeleted.');
            end;
        'G':begin
              prt('Goto which message? (1-'+cstr(himsg)+') : ');
              inu(j);
              if (not badini) then
                if ((j>=1) and (j<=himsg)) then i:=j;
            end;
        'R':begin
              dumpquote(mheader);
              autoreply(mheader);
            end;
        'A':;
      else
            gonext:=TRUE;
      end;
    until ((pos(c,'?LR')=0) or (gonext) or (hangup));
    if (gonext) then inc(i);
    gonext:=FALSE;
  end;
  readingmail:=FALSE;
end;

procedure showemail;
var mheader:mheaderrec;
    i,j:longint;
    c:char;
    done:boolean;
    u:userrec;
    anyfound:boolean;
begin
  readingmail:=TRUE; done:=FALSE; abort := FALSE;
  nl;
  initboard(-1);
  i:=1; c:=#0;
  anyfound := FALSE;
  while ((i <= himsg) and (not done) and (not hangup)) do begin
    loadheader(i, mheader);
    if (mheader.from.usernum <> usernum) then
      inc(i)
    else begin
      if (c<>'?') then
        begin
          anyfound := TRUE;
          cls;
          readmsg(i,i,himsg);
          nl;
        end;
      prt('Outgoing mail (?=help) : '); onek(c,'QDENPRX?'^M^N);
      case c of
        '?':begin
              print(^M^J'<^3CR^1>Next message');
              lcmds(20,3,'Re-read message','Edit message');
              lcmds(20,3,'Delete message','Previous message');
              if CoSysOp then
                lcmds(20,3,'Xtract to file','Quit')
              else
                print('<^3Q^1>uit');
              nl;
            end;
        'R':;
        'P':begin
              j := i - 1;
              while (j >= 1) and not done do
                begin
                  loadheader(j, mheader);
                  if (mheader.from.usernum <> usernum) then
                    dec(j)
                  else
                    done := TRUE;
               end;
               if Done then
                 i := j;
               done := FALSE;
            end;
        'Q':done:=TRUE;
        'X':if (MsgSysOp) then extract(i);
        'E':editmessage(i);
        'D':if not (mdeleted in mheader.status) then
              begin
                sysoplog('* Deleted mail to ' + mheader.from.as);
                mheader.status := mheader.status + [mdeleted];
                saveheader(i, mheader);
                loadurec(u, mheader.mto.usernum);
                if (u.waiting > 0) then
                  dec(u.waiting);
                saveurec(u, mheader.mto.usernum);
                print('Mail deleted.');
              end
            else
              begin
                sysoplog('* Undeleted mail to ' + mheader.from.as);
                mheader.status := mheader.status - [mdeleted];
                saveheader(i, mheader);
                loadurec(u, mheader.mto.usernum);
                if (u.waiting < 65535) then
                  inc(u.waiting);
                saveurec(u, mheader.mto.usernum);
                print('Mail undeleted.');
              end

      else
            inc(i);
      end;
    end;
  end;
  if (not AnyFound) then
    print('^3No outgoing messages.');
  readingmail:=FALSE;
end;

end.
