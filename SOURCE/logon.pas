{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Logon functions }

unit Logon;

interface

uses crt, dos, overlay, common, timefunc;

function getuser:boolean;

implementation

uses newusers,  mail0, mail1, Email, User, maint, ShortMsg,
     cuser,  doors,  archive1,  menus, menus2, Event;

var
  gotname:boolean;
  olduser:userrec;

function Hex(i : longint; j:byte) : String;
const
  hc : array[0..15] of Char = '0123456789ABCDEF';
var
  one,two,three,four: Byte;
begin
  one   := (i and $000000FF);
  two   := (i and $0000FF00) shr 8;
  three := (i and $00FF0000) shr 16;
  four  := (i and $FF000000) shr 24;

  Hex[0] := chr(j);          { Length of String = 4 or 8}
  if (j = 4) then
    begin
      Hex[1] := hc[two shr 4];
      Hex[2] := hc[two and $F];
      Hex[3] := hc[one shr 4];
      Hex[4] := hc[one and $F];
    end
  else
    begin
      Hex[8] := hc[one and $F];
      Hex[7] := hc[one shr 4];
      Hex[6] := hc[two and $F];
      Hex[5] := hc[two shr 4];
      hex[4] := hc[three and $F];
      hex[3] := hc[three shr 4];
      hex[2] := hc[four and $F];
      hex[1] := hc[four shr 4];
    end;
end {Hex} ;

procedure IEMSI;
var
  Tries:byte;
  T1,T2:longint;
  EMSI_IRQ:string[20];
  Done, Success:boolean;
  s,ISI:string;
  c:char;
  i:integer;
  buffer:array[1..2048] of char;
  buffptr:integer;
  u:userrec;
  NextItemPointer:integer;

  function NextItem:string;
  var s:astr;
  begin
    s := '';
    while (NextItemPointer < 2048) and (buffer[NextItemPointer] <> #0) and
      (buffer[NextItemPointer] <> '{') do
      inc(NextItemPointer);

    if (buffer[NextItemPointer] = '{') then
      inc(NextItemPointer);

    while (NextItemPointer < 2048) and (buffer[NextItemPointer] <> #0) and
      (buffer[NextItemPointer] <> '}') do
      begin
        s := s + buffer[NextItemPointer];
        inc(NextItemPointer);
      end;
    if (buffer[NextItemPointer] = '}') then
      inc(NextItemPointer);
    NextItem := s;
  end;

begin
  fillchar(IEMSIRec, sizeof(IEMSIRec), 0);
  if (Speed = 0) or (not General.useIEMSI) then exit;

  write('Attempting IEMSI negotiation ... ');
  fillchar(buffer, sizeof(buffer), 0);
  T1 := timer;
  T2 := timer;
  Tries := 0;
  Done := FALSE;
  Success := FALSE;
  EMSI_IRQ := '**EMSI_IRQ8E08'^M^L;
  com_flush_rx;
  SerialOut(EMSI_IRQ);
  s := '';

  repeat
    hangup := not com_carrier;
    if (abs(T1 - Timer) > 2) then
      begin
        T1 := Timer;
        inc(Tries);
        if (Tries >= 2) then
          Done := TRUE
        else
          begin
            com_flush_rx;
            SerialOut(EMSI_IRQ);
          end;
      end;
    if (abs(T2 - Timer) >= 8) then
      Done := TRUE;
    c := cinkey;
    if (c > #0) then
      begin
        if (length(s) >= 160) then
          delete(s, 1, 120);
        s := s + c;
        if (pos('**EMSI_ICI', s) > 0) then
          begin
            delete(s, 1, pos('EMSI_ICI',s) - 1);
            move(s[1], buffer[1], length(s));
            buffptr := length(s);
            T1 := Timer;
            repeat
              c := cinkey;
              if not (c in [#0, #13]) then
                begin
                  inc(buffptr);
                  buffer[buffptr] := c;
                end;
            until (hangup) or (abs(Timer - T1) > 4) or (c = ^M) or (buffptr = 2048);
            s[0] := #8;
            move(buffer[buffptr - 7], s[1], 8);
            dec(buffptr, 8);
            if (s = Hex(UpdateCRC32($FFFFFFFF, buffer[1], buffptr), 8)) then
              begin
                loadurec(u, 1);
                ISI := '{Renegade,'+ver+'}{'+General.BBSName+'}{'+u.citystate+
                       '}{'+General.SysOpName+'}{'+Hex(getpackdatetime, 8)+
                       '}{Live free or die!}{}{Everything!}';
                ISI := 'EMSI_ISI'+Hex(length(ISI), 4) + ISI;
                ISI := ISI + Hex(UpdateCRC32($FFFFFFFF, ISI[1], length(ISI)), 8);
                ISI := '**' + ISI + ^M;
                com_flush_rx;
                SerialOut(ISI);
                Tries := 0;  T1 := Timer;  s := '';
                repeat
                  if (abs(Timer - T1) >= 3) then
                    begin
                      T1 := Timer;
                      inc(Tries);
                      com_flush_rx;
                      SerialOut(ISI);
                    end;
                  c := cinkey;
                  if (c > #0) then
                    begin
                      if (length(s) >= 160) then
                        delete(s, 1, 120);
                      s := s + c;
                      if (pos('**EMSI_ACK', s) > 0) then
                        begin
                          com_flush_rx;
                          com_purge_tx;
                          Done := TRUE;
                          Success := TRUE;
                        end
                      else
                        if (pos('**EMSI_NAKEEC3', s) > 0) then
                          begin
                            com_flush_rx;
                            SerialOut(ISI);
                            inc(Tries);
                          end;
                    end;
                until (Tries >= 3) or (Done);
              end
            else
              begin
                SerialOut('**EMSI_NAKEEC3');
                T1 := Timer;
              end;
          end;
      end;
  until (Done) or (Hangup);
  if (Success) then
    begin
      writeln('success.');
      sl1('Successful IEMSI negotiation.');
    end
  else
    writeln('failure.');

  NextItemPointer := 1;

  with IEMSIRec do
    begin
      UserName := NextItem;
      Handle := NextItem;
      CityState := NextItem;
      ph := NextItem;
      s := NextItem;
      pw := allcaps(NextItem);
      i := value('$'+NextItem);
      if (i > 0) then
        bdate := pd2date(i);
    end;

  com_flush_rx;

end;

procedure check_ansi;
var
  l:longint;
  c:char;
  ox,x,y:byte;
  s:astr;

  procedure AnsiResponse(var X, Y:byte);
  var
    XS, YS: string[4];
  begin
    {  Not called unless remote }
    l:=timer + 2;
    c:=#0;
    XS := ''; YS := '';  X := 0;  Y := 0;
    while (l > timer) and (c <> ^[) and (not hangup) do
      if (not empty) then
        c := com_rx;        { must be low level to avoid ansi-eater }

    if (c = ^[) then
      begin
        l := timer + 1;
        while (l > timer) and (c <> ';') and (not hangup) do
          if (not empty) then
            begin
              c := com_rx;
              if (c in ['0'..'9']) and (length(YS) < 4) then
                YS := YS + c;
            end;

        l := timer + 1;
        while (l > timer) and (c <> 'R') and (not hangup) do
          if (not empty) then
            begin
              c := com_rx;
              if (c in ['0'..'9']) and (length(XS) < 4) then
                XS := XS + c;
            end;
        X := value(XS);
        Y := value(YS);
      end;
  end;

begin
  textattr := 10;
  write('Attempting to detect emulation ... ');
  thisuser.flags := thisuser.flags - [avatar,ansi,vt100];
  thisuser.sflags := thisuser.sflags - [rip];
  if (Speed = 0) then
    begin
      thisuser.flags:=thisuser.flags+[ansi];
      exit;
    end;
  com_flush_rx;
  SerialOut(^M^M^['[!'#8#8#8);
  l := timer + 2;
  c := #0;
  s := '';

  while (l > timer) and (c <> 'R') and (not hangup) do
    if (not empty) then
      c := com_rx;

  if (c = 'R') then
    begin
      l := ticks+3;
      while (not empty) and (ticks < l) do;
      c := com_rx;
      if (c = 'I') then
        begin
          l := ticks+3;
          while (not empty) and (ticks < l) do;
          c := com_rx;
          if (c = 'P') then
            begin
              thisuser.sflags := thisuser.sflags + [rip];
              s := 'RIP';
            end;
        end;
      com_flush_rx;
    end;

  SerialOut(^M^M^['[6n'#8#8#8#8);
  AnsiResponse(X, Y);
  if (X + Y > 0) then
    begin
      thisuser.flags := thisuser.flags + [ansi];
      if (s <> '') then
        s := s + '/Ansi'
      else
        s := 'Ansi';
      SerialOut(^V^F);
      SerialOut(^['[6n'#8#8);
      OX := X;
      AnsiResponse(X, Y);
      if (X = OX + 1) then
        begin
          thisuser.flags := thisuser.flags + [avatar];
          if (s <> '') then
            s := s + '/Avatar'
          else
            s := 'Avatar';
        end
      else
        SerialOut(#8#8);
    end;
  if (s <> '') then
    print('|10' + s + ' detected.')
  else
    begin
      textattr := 7;
      writeln;
    end;
end;

procedure getpws(var ok:boolean; var tries:integer);
var
  s,s1:astr;
  Phone:string[4];
  Mheader:Mheaderrec;
begin
  ok:=TRUE;
  if (not (fastlogon and (not general.localsec))) then
    begin

    if (IEMSIRec.pw = '') then
      begin
      prompt(fstring.yourpassword);
      Echo := FALSE;
      input(s, 20);
      Echo := TRUE;
      end
    else
      begin
      s := IEMSIRec.pw;
      IEMSIRec.pw := '';
      end;

    if (general.Phonepw) then
      if (IEMSIRec.ph = '') then
        begin
        prompt(fstring.yourphonenumber);
        Echo := FALSE;
        input(Phone,4);
        Echo := TRUE;
        end
      else
        begin
        Phone := copy(IEMSIRec.ph, length(IEMSIRec.ph) - 3, 4);
        IEMSIRec.ph := '';
        end
    else
      Phone := copy(thisuser.ph,length(thisuser.ph)-3,4);

    end; { end if not fast logon and local security off }

  if (not (fastlogon and (not general.localsec))) and
     ((thisuser.pw <> CRC32(s)) or (copy(thisuser.ph,length(thisuser.ph)-3,4)<>Phone)) then
    begin
    prompt(fstring.ilogon);
    if (not hangup) and (usernum<>0) then
      begin
      s:='* Illegal logon attempt! Tried: '+
      caps(thisuser.name) + ' #' + cstr(usernum) + ' PW=' + s;
      if (general.Phonepw) then
        s := s + ', PH#=' + Phone;
      ssm(1,s);
      sl1(s);
      end;
    inc(thisuser.illegal);
    if (usernum <> -1) then    
      saveurec(thisuser,usernum);
    inc(tries);
    if (tries>=general.maxlogontries) then
      begin
      hangup:=TRUE;
      nl;
      end;
    ok:=FALSE;
    end;

  if (ok) then
    status_screen(general.curwindow,'',FALSE, s1);

  if ((aacs(general.spw)) and (ok) and (incom) and (not hangup)) then
    begin
    prompt(fstring.sysopprompt);
    Echo:=FALSE;
    input(s,20);
    Echo:=TRUE;
    if (s <> general.sysoppw) then
      begin
      prompt(fstring.ilogon);
      sl1('* Illegal System password: ' + s); inc(tries);
      if (tries>=general.maxlogontries) then hangup:=TRUE;
      ok:=FALSE;
      end;
    end;

  if (ok) and not (aacs(liner.logonacs)) then
    begin
    printf('nonode');
    if nofile then print('You don''t have the required ACS to logon to this node!');
    sysoplog(thisuser.name+': Attempt to logon node '+cstr(node)+' without access.');
    hangup:=TRUE;
    end;

  if ((ok) and (general.shuttlelog) and (lockedout in thisuser.sflags)) then
    begin
    printf(thisuser.lockedfile);
    sysoplog(thisuser.name+': Attempt to access system when locked out^7 <--');
    hangup:=TRUE;
    end;

  if (usernum > 0) and (onnode(usernum) > 0) and not (CoSysOp) then
    begin
    printf('multilog');
    if (nofile) then
      print(^M^J'You are already logged in on another node!'^M^J);
    hangup := TRUE;
    end;

  if not fastlogon and ok and not hangup and (general.birthdatecheck > 0) and
    (thisuser.loggedon mod general.birthdatecheck = 0) then
    begin
    prt(^M^J'Please verify your date of birth (mm/dd/yyyy) : ');
    inputformatted(s,'##/##/####',FALSE);
    nl;
    if (date2pd(s) <> thisuser.birthdate) then
      begin
      dec(thisuser.loggedon);
      sl1('*' + thisuser.name+' Failed birthday verification. Tried = '+s+' Actual = '+pd2date(thisuser.birthdate));
      ssm(1,ThisUser.Name + ' failed birthday verification on '+date);
      printf('WRNGBDAY');
      irt := '\'#1'Failed birthdate check';
      Mheader.status := [];
      semail(1,Mheader);
      hangup := TRUE;
      end;
    end;

  useron := ok;
end;

procedure TryIEMSILogon;
var
  i, zz:integer;
  ok:boolean;
begin
  if (IEMSIRec.UserName <> '') then
    begin
    i := searchuser(IEMSIRec.UserName, TRUE);

    if (i = 0) and (IEMSIRec.Handle <> '') then
      i := searchuser(IEMSIRec.Handle, TRUE);

    if (i > 0) then
      begin
      zz := usernum;
      usernum := 0;
      olduser := thisuser;
      loadurec(thisuser, i);
      usernum := zz;
      getpws(ok, zz);
      gotname := ok;
      nl;
      if (not gotname) then
        begin
        thisuser := olduser;
        update_screen;
        end
      else
        begin
        usernum := i;
        if (pd2date(thisuser.laston) <> date) then
          with thisuser do
            begin
            ontoday:=0; tltoday:=general.timeallow[sl];
            timebankadd:=0; dltoday:=0; dlktoday:=0;
            timebankwith:=0;
            end;
        Useron:=TRUE;
        update_screen;
        sysoplog('Logged in IEMSI as '+caps(thisuser.name));
        end;
      end
    else
      print(fstring.namenotfound);
    end;
end;

procedure doshuttle;
var cmd,newmenucmd:astr;
    tries,i,j:integer;
    done,loggedon,ok,cmdnothid,cmdexists:boolean;
begin
  nl;
  printf('preshutl');

  gotname := FALSE; loggedon := FALSE;

  TryIEMSILogon;

  curmenu:=general.menupath+'shuttle.mnu';
  readin;

  i:=1;
  newmenucmd:='';
  while ((i<=noc) and (newmenucmd='')) do
    begin
      if (MenuCommand^[i].ckeys='FIRSTCMD') then
        begin
          if (aacs(MenuCommand^[i].acs)) then
            begin
              newmenucmd:='FIRSTCMD';
              domenuexec(cmd,newmenucmd);
            end;
        end;
      inc(i);
    end;

  tries:=0;

  chelplevel:=2;
  repeat
    tshuttlelogon:=0;
    mainmenuhandle(cmd);
    {if (gotname) or (noneedname)) then
      begin}
        newmenucmd:=''; j := 0; done := FALSE;
        repeat
          fcmd(cmd, j, noc, cmdexists, cmdnothid);
          if (j <> 0) then
            if (MenuCommand^[j].cmdkeys<>'OP') and (MenuCommand^[j].cmdkeys<>'O2') and
               (MenuCommand^[j].cmdkeys[1]<>'H') and (MenuCommand^[j].cmdkeys[1]<>'-') and
               (not gotname) then
              begin
                prompt(fstring.shuttleprompt);
                finduser(usernum);
                if (usernum >= 1) then
                  begin
                    i:=usernum;
                    usernum:=0;
                    olduser := thisuser;
                    loadurec(thisuser, i);
                    usernum:=i;
                    getpws(ok, tries);
                    gotname:=ok;
                    nl;
                    if (not gotname) then
                      begin
                        thisuser := olduser;
                        update_screen;
                      end
                    else
                      begin
                        if (pd2date(thisuser.laston) <> date) then
                          with thisuser do
                            begin
                              ontoday:=0; tltoday:=general.timeallow[sl];
                              timebankadd:=0; dltoday:=0; dlktoday:=0;
                              timebankwith:=0;
                            end;
                        Useron:=TRUE;
                        update_screen;
                        sysoplog('Logged on to Shuttle Menu as '+caps(thisuser.name));
                        domenucommand(done,MenuCommand^[j].cmdkeys+MenuCommand^[j].options,newmenucmd);
                      end;
                  end
                else
                  begin
                    print(fstring.ilogon);
                    inc(tries);
                  end;
              end
            else
              domenucommand(done,MenuCommand^[j].cmdkeys+MenuCommand^[j].options,newmenucmd);
        until (j = 0) or (done);
        case tshuttlelogon of
          1:if (thisuser.sl > general.validation['A'].newsl) then
              loggedon := TRUE
            else
              begin
                sl1('* Illegal Shuttle Logon attempt');
                printf('noshutt');
                if (nofile) then
                  print('You have not been validated yet.');
                inc(tries);
              end;
          2:begin
              nl;
              if (not general.closedsystem) and pynq('Logon as new? ') then
                begin
                  newuserinit;
                  newuser;
                  if (usernum>0) and (not hangup) then
                    begin
                      gotname:=TRUE;
                      Useron:=TRUE;
                      DailyMaint;
                    end;
                  curmenu:=general.menupath+'shuttle.mnu';
                  readin;
                end;
            end;
        end;
      {end;}
    if (tries=general.maxlogontries) then hangup:=TRUE;
  until (loggedon) or (hangup);
end;

function getuser:boolean;
var
  pw,s,acsreq:astr;
  lng:longint;
  tries,i,ttimes,zz,eventnum:integer;
  done,nu,ok,toomuch,acsuser:boolean;
begin
  wasnewuser:=FALSE;
  fillchar(thisuser,sizeof(thisuser),0);
  thisuser.tltoday:=15;  CreditsLastUpdated := GetPackDateTime;
  extratime:=0; freetime:=0; choptime:=0; credittime := 0;
  ChatChannel := 0;
  with thisuser do begin
    usernum:=-1;
    name:='Nobody'; realname:='Nobody';  ColorScheme := 1;
    sl:=0; dsl:=0; ar:=[];
    flags:=general.validation['A'].newac+[hotkey,pause,novice,color];
    linelen:=80; pagelen:=25;
  end;
  timeon := getpackdatetime;
  mread:=0; extratime:=0; freetime:=0; credittime := 0;

  sl1('');
  s:='^3Logon node '+cstr(node)+'^5 ['+dat+']^4 (';
  if (Speed > 0) then
    begin
      s := s + cstr(ActualSpeed) + ' baud';
      if (Reliable) then
        s := s + '/Reliable)'
      else
        s := s + ')';
      if (CallerIDNumber > '') then
        s := s + ' Number: ' + CallerIDNumber;
    end
  else
    s := s + 'Keyboard)';
  sl1(s);
  nu:=FALSE;
  nl;
  pw:='';

  if (ActualSpeed < general.minimumbaud) and (Speed > 0) then
    begin
      if (general.minbaudhitime - general.minbaudlowtime > 1430) then
        begin
          if (general.minbaudoverride <> '') then
            begin
              prt('Baud rate override password: ');
              Echo := FALSE;
              input(s, 20);
              Echo := TRUE;
            end;
          if (general.minbaudoverride = '') or (s <> general.minbaudoverride) then
            begin
              printf('nobaud.asc');
              if (nofile) then
                print('You must be using at least '+cstr(general.minimumbaud)+' baud to call this BBS.');
              hangup:=TRUE;
              exit;
            end;
        end
      else
        if (not intime(timer,general.minbaudlowtime,general.minbaudhitime)) then
          begin
            if general.minbaudoverride<>'' then
              begin
                prt('Baud rate override password: ');
                Echo:=FALSE;
                input(s, 20);
                Echo:=TRUE;
              end;
            if (general.minbaudoverride = '') or (s <> general.minbaudoverride) then
              begin
                printf('nobaudh.asc');
                if (nofile) then
                  print('Hours for those using less than '+cstr(general.minimumbaud)+' baud are from '+
                        ctim(general.minbaudlowtime)+' to '+ctim(general.minbaudhitime));
                hangup:=TRUE;
                exit;
              end;
          end
        else
          if (not hangup) then
            if ((general.minbaudlowtime <> 0) or (general.minbaudhitime <> 0)) then
              begin
                printf('yesbaudh.asc');
                if (nofile) then
                  begin
                    print('NOTE: Callers at less than '+cstr(general.minimumbaud)+' baud are');
                    print('restricted to the following hours ONLY:');
                    print('  '+ctim(general.minbaudlowtime)+' to '+ctim(general.minbaudhitime));
                  end;
              end;
  end;

  acsuser:=FALSE;
  for i:=1 to numevents do
    with events[i]^ do
      if ((etype='A') and (active) and (checkeventtime(i,0))) then begin
        acsuser:=TRUE;
        acsreq:=events[i]^.execdata;
        eventnum:=i;
      end;

  check_ansi;

  IEMSI;

  GotName := FALSE;

  if ((general.shuttlelog) and (not fastlogon) and (not hangup)) then
    DoShuttle;

  setc(7);
  cls;
  nl;
  for i := 1 to 2 do
    print(centre(verline(i)));
  nl;
  printf('prelogon');
  if acsuser then begin
    printf('acsea'+cstr(eventnum));
    if (nofile) then
      print('Restricted: Only certain users allowed online at this time.'^M^J);
  end;

  if (not GotName) then
    TryIEMSILogon; { here  -1 }

  ttimes:=0; tries:=0;
  repeat
    repeat
      if (usernum <> -1) and (ttimes >= general.maxlogontries) then
          hangup := TRUE;

      olduser := thisuser;    { userrec }

      if (not GotName) then
        begin
          if (fstring.note[1] <> '') then
            print(fstring.note[1]);
          if (fstring.note[2] <> '') then
            print(fstring.note[2]);
          if (fstring.lprompt <> '') then
            prompt(fstring.lprompt);
          finduser(usernum);
          inc(ttimes);
          if acsuser and (usernum = -1) then
            begin
              printf('acseb'+cstr(eventnum));
              if (nofile) then
                begin
                  print('This time window allows certain other users to get online.');
                  print('Please call back later, after it has ended.');
                end;
              hangup:=TRUE;
            end;
          if (not hangup) and (usernum = 0) then
            begin
              print(fstring.namenotfound);
              if not (general.shuttlelog) then
                if (not general.closedsystem) and pynq('Logon as new? ') then
                  usernum := -1;
              nl;
            end;
        end;
    until (usernum <> 0) or (hangup);

    if acsuser and (usernum = -1) then { here }
      begin
        printf('acseb'+cstr(eventnum));
        if (nofile) then
          begin
            print('This time window allows certain other users to get online.');
            print('Please call back later, after it has ended.');
          end;
        hangup:=TRUE;
      end;

    ok:=TRUE; done:=FALSE;
    if (not hangup) then begin
      if (usernum = -1) then begin
         newuserinit;
         nu:=TRUE;
         done:=TRUE; ok:=FALSE;
      end else begin
         i:=usernum;
         usernum:=0;
         loadurec(thisuser,i);
         usernum:=i;
         TempPause := (Pause in thisuser.flags);
         newdate := pd2date(thisuser.laston);
         board := thisuser.lastmbase;
         fileboard := thisuser.lastfbase;
         if (AutoDetect in thisuser.sflags) then
           begin
             if (RIP in olduser.sflags) then
               thisuser.sflags := thisuser.sflags + [RIP]
             else
               thisuser.sflags := thisuser.sflags - [RIP];
             if (Ansi in olduser.flags) then
               thisuser.flags := thisuser.flags + [Ansi]
             else
               thisuser.flags := thisuser.flags - [Ansi];
             if (Avatar in olduser.flags) then
               thisuser.flags := thisuser.flags + [Avatar]
             else
               thisuser.flags := thisuser.flags - [Avatar];
           end;
         if (pd2date(thisuser.laston)<>date) then
           with thisuser do
             begin
               ontoday:=0; tltoday:=general.timeallow[sl];
               timebankadd:=0; dltoday:=0; dlktoday:=0;
               timebankwith:=0;
             end
         else
           if general.percall then
             thisuser.tltoday := general.timeallow[thisuser.sl];

         if (thisuser.expiration <= getpackdatetime) and
            (thisuser.expiration > 0) and
            (thisuser.expireto in ['A'..'Z']) then
           begin
             autovalidate(thisuser,usernum,thisuser.expireto);
             sysoplog('Subscription expired to level ' + thisuser.expireto);
           end;

         if (thisuser.callerid = '') and (CallerIDNumber > '') then
           thisuser.callerid := CallerIDNumber;

         saveurec(thisuser,usernum);

         if (not gotname) then
           getpws(ok,tries);

         if (ok) then done:=TRUE;

         if not done then
           begin
             thisuser := olduser;
             usernum := 0;
             update_screen;
           end;
      end;
    end;
  until ((done) or (hangup));

  reset(SchemeFile);
  if (Thisuser.ColorScheme > 0) and
     (Thisuser.ColorScheme <= filesize(SchemeFile)) then
     seek(SchemeFile, Thisuser.ColorScheme - 1)
  else
    Thisuser.ColorScheme := 1;

  read(SchemeFile, Scheme);
  close(SchemeFile);

  if acsuser and not (aacs(acsreq)) then begin
     printf('acseb'+cstr(eventnum));
     if (nofile) then begin
       print('This time window allows certain other users to get online.');
       print('Please call back later, after it has ended.');
     end;
     hangup:=TRUE;
  end;

  if not (aacs(liner.logonacs)) and (not hangup) then begin
    printf('nonode');
    if nofile then print('You don''t have the required ACS to logon to this node!');
    sysoplog(thisuser.name+': Attempt to logon node '+cstr(node)+' without access.');
    hangup:=TRUE;
  end;
  if ((lockedout in thisuser.sflags) and (not hangup)) then begin
    printf(thisuser.lockedfile);
    sysoplog(thisuser.name+': Attempt to access system when locked out^7 <--');
    hangup:=TRUE;
  end;
  if ((not nu) and (not hangup)) then begin
    toomuch:=FALSE;
    if (AccountBalance < General.CreditMinute) and (General.CreditMinute > 0) and
       not (fnocredits in thisuser.flags) then
      begin
        printf('nocreds');
        sysoplog(thisuser.name+': insufficient credits for logon.');
        if (nofile) then print('You have insufficient credits for online time.');
        if (General.CreditFreeTime < 1) then
          hangup := TRUE
        else
          begin
            Thisuser.TlToday := General.CreditFreeTime div General.CreditMinute;
            inc(Thisuser.Credit, General.CreditFreeTime);
          end;
      end
    else
    if (((rlogon in thisuser.flags) or (general.callallow[thisuser.sl]=1)) and
       (thisuser.ontoday>=1) and (pd2date(thisuser.laston)=date)) then begin
      printf('2manycal');
      if (nofile) then print('You can only log on once per day.');
      toomuch:=TRUE;
    end else
      if ((thisuser.ontoday>=general.callallow[thisuser.sl]) and
          (pd2date(thisuser.laston)=date)) then begin
        printf('2manycal');
        if (nofile) then
          print('You can only log on '+cstr(general.callallow[thisuser.sl])+' times per day.');
        toomuch:=TRUE;
      end else
        if (thisuser.tltoday <= 0) and not (general.percall) then begin
          printf('notlefta');
          if (nofile) then
            prompt('You can only log on for '+cstr(general.timeallow[thisuser.sl])+' minutes per day.');
          toomuch:=TRUE;
          if (thisuser.timebank>0) then begin
            print(^M^J^M^J'^5However, you have '+cstr(thisuser.timebank)+
                   ' minutes left in your Time Bank.');
            dyny:=TRUE;
            if pynq('Withdraw from Time Bank? ') then begin
              prt('Withdraw how many minutes? '); inu(zz); lng:=zz;
              if (lng>0) then begin
                if (lng>thisuser.timebank) then lng:=thisuser.timebank;
                dec(thisuser.timebankadd,lng);
                if (thisuser.timebankadd<0) then thisuser.timebankadd:=0;
                dec(thisuser.timebank,lng);
                inc(thisuser.tltoday,lng);
                print('^5In your account: ^3'+cstr(thisuser.timebank)+
                        '^5   Time left online: ^3' + FormattedTime(nsl));
                sysoplog('TimeBank: Withdrew '+cstr(lng)+' minutes at logon.');
              end;
            end;
            if (nsl>=0) then toomuch:=FALSE else print('Hanging up.');
          end;
        end;
    if (toomuch) then begin
      sl1(thisuser.name+' Attempt to exceed time/call limits.');
      hangup:=TRUE;
    end;
    if (tries=general.maxlogontries) then hangup:=TRUE;
    if (not hangup) then inc(thisuser.ontoday);
  end;
  if (usernum > 0) and (not hangup) then
    begin
      getuser:=nu;
      if (not fastlogon) then begin
         printf('welcome');
         if (not nofile) then pausescr(FALSE);
         i:=0;
         repeat
           inc(i);
           printf('welcome'+cstr(i));
           if (not nofile) then pausescr(FALSE);
         until (i=9) or (nofile) or (hangup);
      end;
    Useron:=TRUE;
    update_screen;
    update_node(254);
    inittrapfile;
    Useron:=FALSE;
    cls;
  end;
  if (hangup) then getuser:=FALSE;
end;

end.
