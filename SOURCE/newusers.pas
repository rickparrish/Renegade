{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Handle New Users }

unit newusers;

interface

uses crt, dos, overlay, timefunc;

procedure newuser;
procedure newuserinit;

implementation

uses mail0, Email, Script, User, cuser, doors,
     archive1, menus, common;

procedure p1;
var c:char;
    tries,t,i,j:integer;
    old_menu, cmd, newmenucmd:astr;
    atype,pw:astr;
    cmdnothid,cmdexists,done,choseansi,chosecolor:boolean;

  procedure showstuff;
  begin
    if (general.newuserpw<>'') then begin
      tries:=0; pw:='';
      while ((pw<>general.newuserpw) and
            (tries<general.maxlogontries) and (not hangup)) do begin
        prt(fstring.newuserpassword); echo:=FALSE; input(pw,20); echo:=TRUE;
        if ((general.newuserpw<>pw) and (pw<>'')) then begin
          sl1('* Illegal newuser password: '+pw);
          inc(tries);
        end;
      end;
      if (tries>=general.maxlogontries) then begin
        nl;
        printf('nonewusr');
        hangup:=TRUE;
      end;
    end;
    printf('newuser');
  end;

  procedure doitall;
  const
    neworder:array[1..17] of integer = (7,10,23,1,4,14,8,12,2,5,6,13,3,11,24,9,-1);
  var i:integer;
      iANSI,iAVATAR:boolean;
  begin
    with thisuser do begin
      usernum:=-1;
      name:='NO USER'; realname:='NO USER';
      sl:=0; dsl:=0; ar:=[]; debit := 0; credit := 0;
      iANSI := (ansi in flags);
      iAVATAR := (Avatar in flags);
      flags:=general.validation['A'].newac + [hotkey,pause,novice,color];
      if iANSI then flags := flags + [ansi];
      if iAVATAR then flags := flags + [Avatar];
      linelen:=80; pagelen:=24;
      TeleConfEcho := TRUE;  TeleConfInt := TRUE;
    end;
    showstuff;
    i:=1;
    repeat
      update_screen;
      cstuff(neworder[i],1,thisuser);
      inc(i);
    until (neworder[i]=-1) or (hangup);
  end;

begin
  t:=0;
  loadnode(node);
  noder.user := 65535;
  savenode(node);

  doitall;


  { newmenutoload should be true ONLY if NEWINFO is currently loaded }

  old_menu := curmenu;      { otherwise it fucks up calling other menus }
  curmenu := general.menupath + 'newinfo.mnu';

  readin2;

  i:=1;
  newmenucmd:='';
  while ((i <= noc) and (newmenucmd = '')) do
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

  repeat
    mainmenuhandle(cmd);
    newmenucmd := ''; j := 0;  done := FALSE;
    repeat
      fcmd(cmd, j, noc, cmdexists, cmdnothid);
      if (j <> 0) then
        begin
          domenucommand(done, MenuCommand^[j].cmdkeys + MenuCommand^[j].options, newmenucmd);
          if (MenuCommand^[j].cmdkeys = 'OQ') then
            Abort := TRUE;
          inc(t);
        end;
    until (j = 0) or (done) or (hangup);
  until (abort) or (next) or (hangup);
  curmenu := Old_menu;   { not really necessary, no menu should be loaded }
  newmenutoload := TRUE;
end;

procedure p2;
var user:userrec;
    IndexR:useridxrec;
    i,j,k:integer;
begin
  if (not hangup) then begin
    prompt(^M^J'Saving your information ... ');
    sysoplog('Saving new user information ...');
    j:=0; i:=1;
    reset(sf);
    k:=filesize(sf);
    while (i < k) and (j = 0) do
      begin
        read(sf, IndexR);
        if (IndexR.Deleted) then
          begin
            loadurec(User, IndexR.Number);
            if (deleted in user.sflags) then
              j := IndexR.Number;
          end;
        inc(i);
      end;
    close(sf);

    if (j > 0) then
      usernum := j
    else
      usernum := maxusers;

    sysoplog('Saved as user #'+cstr(usernum));

    with thisuser do begin
      sflags:=sflags-[lockedout,deleted,trapseparate,trapactivity,chatauto,
             chatseparate,slogseparate];

      waiting:=0; firston:=getpackdatetime; laston:=getpackdatetime;
      loggedon:=0; msgpost:=0; emailsent:=0; feedback:=0; ontoday:=0;
      illegal:=0; forusr:=0; dltoday:=0; dlktoday:=0;
      downloads:=0; uploads:=0; dk:=0; uk:=0;
      ttimeon:=0;

      if (Liner.UseCallerID) and (CallerIDNumber <> '') then
        thisuser.note := CallerIDNumber
      else
        note:='';

      defarctype:=1; lastconf:='@';
      TeleConfEcho := TRUE;
      TeleConfInt := FALSE;

      timebank:=0;

      timebankadd:=0;

      loadurec(user,0);
      lastmbase:=1; lastfbase:=1;

      tltoday:=general.timeallow[sl];

      for i:=1 to 20 do vote[i]:=0;

    end;

    autovalidate(thisuser, usernum, 'A');

    saveurec(thisuser,usernum);

    InsertIndex(thisuser.name, usernum, FALSE, FALSE);
    InsertIndex(thisuser.realname, usernum, TRUE, FALSE);
    inc(Todaynumusers);
    savegeneral(TRUE);

    if (usernum < maxusers) then
      for i := 1 to MaxMBases do
        begin
          initboard(i);
          SaveLastRead(0);
          if not NewScanMBase then
            ToggleNewScan;
        end;

    print('^3Saved.'^M^J);
    useron:=TRUE;
    cls;

    if ((exist(general.miscpath+'newuser.inf')) or
        (exist(general.datapath+'newuser.inf'))) then
      readq('newuser');
    update_screen;
    if (general.newapp<>-1) then begin
      printf('newapp');
      if (nofile) then
        begin
          print('You must now send a newuser application letter to the SysOp.');
          pausescr(FALSE);
        end;
      irt:='\'#1'New User Application';
    end;
    nl;
  end;
end;

procedure newuser;
var
  i:integer;
  mheader:mheaderrec;
  letter:text;
  s:string;
  u:userrec;
begin
  mheader.status:=[];
  sl1('* New user logon');
  p1;
  if hangup then exit;
  p2;
  if (general.newapp<>-1) then begin
    i:=general.newapp;
    if (i<0) or (i>maxusers) then i:=1;
    semail(i,mheader);
  end;
  wasnewuser:=TRUE;
  useron:=TRUE;
  if not hangup and (exist(General.MiscPath + 'NEWLET.ASC')) then
    begin
      thisuser.waiting := 1;
      initboard(-1);
      assign(letter, General.MiscPath + 'NEWLET.ASC');
      reset(letter);
      fillchar(mheader, sizeof(mheader), 0);
      readln(letter, mheader.from.as);
      readln(letter, mheader.subject);
      if (General.NewApp > 0) then
        mheader.from.usernum := General.NewApp
      else
        mheader.from.usernum := 1;
      mheader.mto.usernum := usernum;
      mheader.mto.as := thisuser.name;
      mheader.date := getpackdatetime;
      mheader.status := [allowmci];
      reset(msgtxtf, 1);
      seek(msgtxtf, filesize(msgtxtf));
      mheader.pointer := filesize(msgtxtf) + 1;
      while not eof(letter) do
        begin
          readln(letter, s);
          inc(mheader.textsize, length(s) + 1);
          blockwrite(msgtxtf, s[0], length(s) + 1);
        end;
      close(msgtxtf);
      reset(msghdrf);
      seek(msghdrf, filesize(msghdrf));
      write(msghdrf, mheader);
      close(msghdrf);
      close(letter);
    end;
end;

procedure newuserinit;
begin
  if (general.closedsystem) then begin
    printf('nonewusr');
    hangup:=TRUE;
  end else begin
    with thisuser do begin
      name:='NEW USER';
      sflags:=sflags-[trapactivity,trapseparate];
    end;
    inittrapfile;
  end;
end;

end.
