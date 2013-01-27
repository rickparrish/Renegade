{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit cuser;

interface

uses crt, dos, overlay, common;

procedure cstuff(which,how:byte; var user:userrec);

implementation

uses archive1, timefunc, user;

(******************************************************************************
 procedure: cstuff(which,how:byte; var user:userrec);
---
 purpose:   Inputs user information.
---
 variables passed:

    which- 1:Address        6:User Def 2  11:Screen size
           2:Age            7:User name   12:Sex
           3:ANSI status    8:Phone #     13:User Def 3
           4:City & State   9:Password    14:Zip code
           5:User Def 1    10:Real name

      how- 1:New user logon in process
           2:Menu edit command
           3:Called by the user-list editor

     user- User information to modify
******************************************************************************)

var callfromarea:integer;

(*****************************************************************************)
procedure cstuff(which,how:byte; var user:userrec);
var done,done1:boolean;
    try:integer;
    fi:text;
    s:astr;
    i,j:integer;

  procedure findarea;
  var c:char;
  begin
    print('^1Are you calling from:');
    print('  1. United States');
    print('  2. Canada');
    print('  3. Other country');
    prt(^M^J'Select (1-3) : '); onek(c,'123');
    if (hangup) then exit;
    callfromarea:=ord(c)-48;
    done1:=TRUE;
  end;



(*****************************************************************************)
  Procedure ConfigureQWK;
  var s:string[3];
      bb:byte;
  begin
    if (user.defarctype<1) or (user.defarctype>8) then user.defarctype:=1;
    print('Current archive type: ^5'+general.filearcinfo[user.defarctype].ext + ^M^J);

    repeat
      prt('Archive type to use? (?=List) : '); input(s,3);
      if (s='?') then
        begin
          nl;
          listarctypes;
          nl;
        end;
    until (s<>'?');
    if (value(s)<>0) then bb:=value(s)
       else bb:=arctype('F.'+s);
     if (bb>0) and (bb<9) then user.defarctype:=bb;
     done1:=true;
     nl;
     user.getownqwk := pynq('Do you want your own replies in your QWK packet? ');
     nl;
     user.scanfilesqwk := pynq('Would you like a new files listing in your QWK packet? ');
     nl;
     user.privateqwk := pynq('Do you want your private mail in your QWK packet? ');
     nl;
  end;

(*****************************************************************************)
  procedure doaddress;
  begin
    print('^1Enter your street address.');
    prt(':'); mpl(sizeof(user.street));
    if (how=3) then inputl(s,30) else inputcaps(s,30);
    if (s<>'') then begin
      if (how = 2) then
        sysoplog('Changed address from '+user.street+' to '+s);
      user.street:=s;
      done1:=TRUE;
    end;
  end;


(*****************************************************************************)
  procedure doage;
  var
    s:astr;
    q:boolean;

  begin
    if (how = 1) and (IEMSIRec.bdate <> '') then
      begin
        buf := IEMSIRec.bdate;
        IEMSIRec.bdate := '';
      end;
    print('^1Enter your date of birth (mm/dd/yyyy)');
    prt(':');
    if how=3 then q:=TRUE else q:=FALSE;
    UserColor(3); inputformatted(s,'##/##/####',q);
    if (s <> '') then
      begin
        if (how = 2) then
          sysoplog('Changed birthdate from '+pd2date(user.birthdate)+' to '+s);
        user.birthdate := date2pd(s);
      end;
    done1:=TRUE;
  end;

(*****************************************************************************)
  procedure docitystate;
  var s,s1,s2:astr;
  begin
    case how of
      2:findarea;
      3:callfromarea:=1;
    end;
    if (callfromarea<>3) then begin
      if (how=3) then begin
        print('Enter new city & state abbreviation: ');
        prt(':'); inputl(s,30);
        if (s<>'') then user.citystate:=s;
        done1:=TRUE;
        exit;
      end;
      if (callfromarea=1) then s2:='state' else s2:='province';
      print('^1Please enter only your city:');
      prt(':');
      mpl(sizeof(user.citystate));
      inputcaps(s1,sizeof(user.citystate)-1);
      if (pos(',',s1)<>0) then
        begin
          print(^M^J'^1Enter only your city name.');
          exit;
        end;
      nl;
      if (length(s1)<3) then exit;
      prompt('^1Now enter your ' + s2 + ' abbreviation: ');
      input(s2, 2);
      user.citystate := s1 + ', ' + s2;
      done1:=TRUE;
    end else begin
      print('^1First enter your city name only:');
      prt(':'); mpl(26); inputcaps(s1,26);
      if (length(s1)<2) then exit;

      print(^M^J'^1Now enter your country name:');
      prt(':'); mpl(26); inputcaps(s2,26);
      if (length(s2)<2) then exit;
      s:=s1+', '+s2;
      if (length(s)>30) then begin
        print('Too long!  Max total length is 30 characters.');
        exit;
      end;
      if (how = 2) and (user.citystate <> s) then
        sysoplog('Changed city/state from '+user.citystate+' to '+s);
      user.citystate:=s;
      done1:=TRUE;
    end;
  end;


(*****************************************************************************)
  procedure douserdef(x : byte);
  begin
    if fstring.userdefques[x] = '' then
      begin
        user.usrdefstr[x] := '';
        done1 := TRUE;
        exit;
      end;
    print('^1' + fstring.userdefques[x]);
    prt(':');
    mpl(sizeof(user.usrdefstr[1])-1);
    inputl(s,sizeof(user.usrdefstr[1])-1);
    if (s <> '') then
      begin
        user.usrdefstr[x] := s;
        done1 := TRUE;
      end;
  end;

(*****************************************************************************)
  procedure doname;
  var i:integer;
      s1,s2:astr;
      sr:useridxrec;
  begin
    if (how = 1) then
      if (General.Allowalias) and (IEMSIRec.Handle <> '') then
        begin
          buf := IEMSIRec.Handle;
          IEMSIRec.Handle := '';
        end
      else
        if (IEMSIRec.UserName <> '') then
          begin
            buf := IEMSIRec.UserName;
            IEMSIRec.UserName := '';
          end;

    if (general.allowalias) then
      begin
        print('^1Enter your handle, or your real first & last');
        print('names if you don''t want to use one.')
      end
    else
      begin
        print('^1Enter your first & last name.');
        print('Handles are not allowed.');
      end;

    prt(':');
    mpl(36);
    input(s, 36);

    done1 := FALSE;

    while (s[1] in [' ','0'..'9']) and (length(s) > 0) do
      delete(s, 1, 1);

    while (s[length(s)] = ' ') do
      dec(s[0]);

    if ((pos(' ',s) = 0) and (how<>3) and not (general.allowalias)) then begin
      print(^M^J'^1Please enter your first AND last name!');
      s:='';
    end;
    if (s <> '') then
      begin
        done1:=TRUE;
        i := Searchuser(s, TRUE);
        if (i > 0) and (i <> usernum) then
          begin
            done1:=FALSE;
            print(^M^J'^7That name is in use.');
          end;
      end;
    assign(fi, general.miscpath + 'trashcan.txt');
    reset(fi);
    if (ioresult=0) then begin
      s2:=' '+s+' ';
      while not eof(fi) do begin
        readln(fi,s1);
        if s1[length(s1)]=#1 then s1[length(s1)]:=' ' else s1:=s1+' ';
        s1:=' '+s1;
        for i:=1 to length(s1) do s1[i]:=upcase(s1[i]);
        if pos(s1,s2)<>0 then done1:=FALSE;
      end;
      close(fi);
      Lasterror := IOResult;
    end;
    if (not done1) and (not hangup) then begin
      print(^M^J^G'^7Sorry, can''t use that name.');
      inc(try);
      sl1('Unacceptable name : '+s);
    end;
    if (try >= 3) and (how = 1) then
      hangup:=TRUE;
    if ((done) and (how=1) and (not general.allowalias)) then
      user.realname:=caps(s);

    if (done1) then
      begin
        if (how = 2) and (Usernum > -1) then  { Don't do index on unregged users! }
          begin
            sysoplog('Changed name from '+user.name+' to '+s);
            InsertIndex(user.name, usernum, FALSE, TRUE);
            user.name := s;
            InsertIndex(user.name, usernum, FALSE, FALSE);
          end
        else
          user.name := s;
      end;
  end;

(*****************************************************************************)
  procedure dophone;
  begin
    case how of
      1:begin
          if (IEMSIRec.ph <> '') then
            begin
              buf := IEMSIRec.ph;
              IEMSIRec.ph := '';
            end;
        end;
      2:findarea;
      3:callfromarea:=1;
    end;
    print('^1Enter your phone number');
    prt(':');
    if (((how=1) and (callfromarea=3)) or (how=3)) then begin
      mpl(12);
      input(s,12);
      if (length(s)>5) then begin user.ph:=s; done1:=TRUE; end;
    end else begin
      inputformatted(s,'(###)###-####',FALSE);
      s[5]:='-';
      s:=copy(s,2,length(s)-1);
      if (how = 2) and (user.ph <> s) then
        sysoplog('Changed phone from '+user.ph+' to '+s);
      user.ph:=s;
      done1:=TRUE;
    end;
  end;

(*****************************************************************************)
  procedure dopw;
  var
    s:string[20];
    s2:string[20];
    op:longint;
  begin
    if (how = 1) and (IEMSIRec.pw <> '') then
      begin
        buf := IEMSIRec.pw;
        IEMSIRec.pw := '';
      end;
    op:=user.pw;
    if how=2 then begin
          print('^5Please enter your current password.'^M^J);
          echo:=FALSE;
          prompt('^0Password: ^5'); input(s,20);
          echo:=TRUE;
          if (CRC32(s)<>user.pw) then
            begin
              print(^M^J'Wrong!'^M^J);
              exit;
            end;
    end;
    repeat
      repeat
        print(^M^J'^1Enter your desired password for future access.');
        print('It should be 4 to 20 characters in length.'^M^J);
        prt('Password: ');
        echo:=FALSE;
        input(s,20);
        echo:=TRUE;
        nl;
        if (length(s)<4) then
          print('^7Must be at least 4 characters long.'^M^J)
        else
          if (length(s)>20) then
            print('^7Must be no more than 20 characters long.'^M^J)
          else
            if (how=3) and (CRC32(s) = op) then
              begin
                print('^7Must be different from your old password!');
                s:='';
              end
            else
              if (s = thisuser.name) or (s = thisuser.realname) then
                begin
                  print('^7You cannot use that password!');
                  s:='';
                end;
      until (((length(s)>3) and (length(s)<21)) or (hangup));
      print('Please enter your password again for verification.');
      prt(^M^J'Password: ');
      echo:=FALSE;
      input(s2, 20);
      echo:=TRUE;
      if s2 <> s then
        print(^M^J'Passwords do not match.'^M^J)
    until ((s2=s) or (hangup));
    if (hangup) and (how=3) then
      user.pw := op
    else
      user.pw := CRC32(s);
    user.passwordchanged:=daynum(date);
    if (how = 2) then
      begin
        print(^M^J'Password changed.'^M^J);
        sysoplog('Changed password.');
      end;
    done1:=TRUE;
  end;

(*****************************************************************************)
  procedure dorealname;
  begin
    if (how=1) then
      if (not general.allowalias) then
        begin
          user.realname:=caps(user.name);
          done1:=TRUE;
          exit;
        end
      else
        if (IEMSIRec.UserName <> '') then
          begin
            buf := IEMSIRec.UserName;
            IEMSIRec.UserName := '';
          end;

    print('^1Enter your real first & last name.');
    prt(':');
    mpl(36);
    if (how=3) then inputl(s,36) else inputcaps(s,36);

    while (s[1] in [' ','0'..'9']) and (length(s) > 0) do
      delete(s,1,1);

    while(s[length(s)] = ' ') do
      dec(s[0]);

    if (pos(' ',s)=0) and (how<>3) then begin
      print(^M^J'^1Please enter your first AND last name!');
      s:='';
    end;

    if (s <> '') then
      begin
        done1:=TRUE;
        i := Searchuser(s, TRUE);
        if (i > 0) and (i <> usernum) then
          begin
            done1:=FALSE;
            print(^M^J'^7That name is in use.');
          end;
      end;

    if (done1) then begin
      if (how = 2) and (Usernum > -1) then { don't do index on unregged users! }
        begin
          sysoplog('Changed real name from '+user.realname+' to '+s);
          InsertIndex(user.realname, usernum, TRUE, TRUE);
          user.realname:=s;
          InsertIndex(user.realname, usernum, TRUE, FALSE);
        end
      else
        user.realname:=s;
      done1:=TRUE;
    end;
  end;



(*****************************************************************************)
  procedure doscreen;
  var
    bb:byte;
  begin
    prt('How wide is your screen (32-132) ['+
      cstr(user.linelen)+'] : ');
    ini(bb);
    if (bb in [32..132]) then
      user.linelen := bb;
    prt('How many lines per page (4-50) ['+cstr(user.pagelen)+'] : ');
    ini(bb);
    if (bb in [4..50]) then
      user.pagelen:=bb;
    done1:=TRUE;
  end;


(*****************************************************************************)
  procedure dosex;
  var c:char;
  begin
    if (how=3) then begin
      prt('New sex (M,F) : ');
      onek(c,'MF '^M);
      if (c in ['M','F']) then user.sex:=c;
    end else begin
      user.sex:=#0;
      prt('Your sex (M,F) ? ');
      onek(user.sex,'MF');
    end;
    done1:=TRUE;
  end;


(*****************************************************************************)
  procedure dozipcode;
  var
    abortable:boolean;
  begin
    if how=3 then
      begin
        abortable:=TRUE;
        findarea;
        nl;
      end
    else
      abortable:=FALSE;
    case callfromarea of
      1:begin
          print('^1Enter your zipcode: #####-####');
          prt(':'); inputformatted(s,'#####-####',abortable);
          if (s <> '') then
            user.zipcode:=s;
          done1:=TRUE;
        end;
      2:begin
          print('^1Enter your postal code (LNLNLN format)');
          prt(':'); inputformatted(s,'@#@#@#',abortable);
          if (s <> '') then
            user.zipcode:=s;
          done1:=TRUE
        end;
      3:begin
          print('^1Enter your postal code:');
          prt(':'); mpl(10); input(s,10);
          if (length(s)>2) then
            begin
              user.zipcode:=s;
              done1:=TRUE;
            end;
        end;
    end;
  end;


(*****************************************************************************)
  procedure forwardmail;
  var u:userrec;
      s:astr;
      i:integer;
      b:boolean;
  begin
    print(^M^J'^1If you forward your mail, all Email sent to your account will be redirected to');
    print('that person.  Enter the user''s name, or just hit [Enter] to abort this function.');
    prt(':');
    finduserws(i);
    nl;
    if (i <= 0) then begin
      user.forusr := 0;
      print('Forwarding deactivated.');
    end else begin
      b:=TRUE;
      if (i >= maxusers) then b:=FALSE
       else begin
        loadurec(u,i);
        if (deleted in u.sflags) or (nomail in u.flags) then b:=FALSE;
      end;
      if (i=usernum) then b:=FALSE;
      if (b) then begin
        user.forusr:=i;
        s:='Forwarding mail to: '+caps(u.name)+' #'+cstr(i);
        print(s);
        sysoplog(s);
      end else
        print('Sorry, can''t forward to that user.');
    end;
  end;


(*****************************************************************************)
  procedure mailbox;
  begin
    if (nomail in user.flags) then begin
      user.flags:=user.flags-[nomail];
      s:='Mailbox now open.';
      print('^5'+s);
      sysoplog(s);
    end else
      if (user.forusr<>0) then begin
        user.forusr:=0;
        s:='Mail forwarding ended.';
        print(s);
        sysoplog(s);
      end else begin
        if pynq('Do you want to close your mailbox? ') then begin
          user.flags:=user.flags+[nomail];
          s:='Mailbox now closed.';
          print('^5'+s);
          print('^5You will NOT recieve mail now.');
          sysoplog(s);
        end else
          if pynq('Do you want to forward your mail? ') then forwardmail;
      end;
    done1:=TRUE;
  end;


(*****************************************************************************)
  procedure tog_ansi;
  var c:char;
  begin
    printf('terminal');
    print('^1Which terminal emulation do you support?'^M^J);

    print('(1) None');
    print('(2) Ansi');
    print('(3) Avatar');
    print('(4) VT-100');
    print('(5) RIP Graphics'^M^J);

    prompt('Selection : ');
    UserColor(3); onek(c,'12345');
    user.flags:=user.flags-[ansi,avatar,vt100];
    user.sflags:=user.sflags-[rip];
    case c of
      '2':user.flags := user.flags + [ansi];
      '3':begin
            user.flags := user.flags + [avatar];
            dyny := TRUE;
            if pynq(^M^J'Does your terminal program support ANSI fallback? ') then
              user.flags := user.flags + [ansi];
          end;
      '4':user.flags := user.flags + [vt100];
      '5':begin
            user.flags := user.flags + [ansi];
            user.sflags := user.sflags + [rip];
          end;
    end;
    if (ansi in user.flags) or (avatar in user.flags) or (vt100 in user.flags) then
      user.sflags := user.sflags + [fseditor]
    else
      user.sflags := user.sflags - [fseditor];

    dyny := TRUE;
    if (pynq(^M^J'Would you like this to be auto-detected in the future? ')) then
      user.sflags := user.sflags + [AutoDetect]
    else
      user.sflags := user.sflags - [AutoDetect];
    done1:=TRUE;
  end;


(*****************************************************************************)
  procedure tog_color;
  begin
    if (color in user.flags) then begin
      user.flags:=user.flags-[color];
      print('Ansi color disabled.');
    end else begin
      user.flags:=user.flags+[color];
      print('Ansi color enabled.');
    end;
    done1:=TRUE;
  end;


(*****************************************************************************)
  procedure tog_pause;
  begin
    if (pause in user.flags) then begin
      user.flags:=user.flags-[pause];
      print('Pause on screen disabled');
    end else begin
      user.flags:=user.flags+[pause];
      print('Pause on screen enabled');
    end;
    done1:=TRUE;
  end;


(*****************************************************************************)
  procedure tog_editor;
  begin
    done1:=TRUE;
    if (not (ansi in user.flags)) and (not (avatar in user.flags)) then begin
       print('You must use ansi to use the full screen editor.');
       user.sflags:=user.sflags-[fseditor];
       exit;
    end;
    if (fseditor in user.sflags) then begin
       user.sflags:=user.sflags-[fseditor];
       print('Full screen editor disabled.');
    end else begin
       user.sflags:=user.sflags+[fseditor];
       print('Full screen editor enabled.');
     end;
   end;


(*****************************************************************************)
  procedure tog_input;
  begin
    if (hotkey in user.flags) then begin
      user.flags:=user.flags-[hotkey];
      print('Full line input.');
    end else begin
      user.flags:=user.flags+[hotkey];
      print('Hot key input.');
    end;
    done1:=TRUE;
  end;


(*****************************************************************************)
  procedure tog_clsmsg;
  begin
    if (clsmsg in user.sflags) then begin
      user.sflags:=user.sflags-[clsmsg];
      print('Screen clearing off.');
    end else begin
      user.sflags:=user.sflags+[clsmsg];
      print('Screen clearing on.');
    end;
    done1:=TRUE;
  end;


(*****************************************************************************)
  procedure tog_expert;
  begin
    if (novice in user.flags) then begin
      user.flags:=user.flags-[novice];
      chelplevel:=1;
      print('Expert mode on.');
    end else begin
      user.flags:=user.flags+[novice];
      chelplevel:=2;
      print('Expert mode off.');
    end;
    done1:=TRUE;
  end;


(*****************************************************************************)
  procedure chcolors;
  var
    AScheme:SchemeRec;
    i,Onlin:integer;
  begin
    reset(SchemeFile);
    cls;
    abort:=FALSE; next:=FALSE;
    printacr('Available color schemes:'^M^J);
    i := 1;  Onlin := 0;
    seek(SchemeFile, 0);
    while (FilePos(SchemeFile) < filesize(SchemeFile)) and (not hangup) and (not abort) do
      begin
        read(SchemeFile, AScheme);
        inc(Onlin);
        prompt('^1' + mn(i,2) + '. ^3' + mln(AScheme.Description,35));
        if (OnLin = 2) then
          begin
            nl;
            Onlin := 0;
          end;
        wkey;
        inc(i);
      end;
    abort := FALSE; next := FALSE;
    prt(^M^J^M^J'Please select a color scheme : '); inu(i);
    if (not badini) and (i>0) and (i<=filesize(SchemeFile)) then
      begin
        thisuser.ColorScheme := i;
        seek(SchemeFile, i - 1);
        read(SchemeFile, Scheme);
        Done1 := TRUE;
      end;
    close(SchemeFile);
    Lasterror := IOResult;
  end;


(*****************************************************************************)
  procedure checkwantpause;
  begin
    dyny:=TRUE;
    if pynq('Do you want screen clearing? ') then user.sflags:=user.sflags+[clsmsg]
       else user.sflags:=user.sflags-[clsmsg];
    dyny:=TRUE;
    if pynq('Pause after each screen? ') then
      user.flags:=user.flags+[pause]
    else
      user.flags:=user.flags-[pause];
    done1:=TRUE;
  end;



(*****************************************************************************)
  procedure ww(www:integer);
  begin
    nl;
    case www of
      1:doaddress;     2:doage;         3:tog_ansi;
      4:docitystate;   5:douserdef(1);  6:douserdef(2);
      7:doname;        8:dophone;       9:dopw;
     10:dorealname;   11:doscreen;     12:dosex;
     13:douserdef(3); 14:dozipcode;    15:mailbox;
     16:tog_ansi;     17:tog_color;    18:tog_pause;
     19:tog_input;    20:tog_clsmsg;   21:chcolors;
     22:tog_expert;   23:findarea;     24:checkwantpause;
     25:;             26:tog_editor;   27:configureqwk;
    end;
  end;



(*****************************************************************************)
begin
  try:=0; done1:=FALSE;
  case how of
    1:repeat ww(which) until (done1) or (hangup);
    2,3:begin
        ww(which);
        update_node(0);
        if not done1 then print('Function aborted!');
      end;
  end;
end;

end.
