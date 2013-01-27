{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Maintenance functions }

unit Maint;

interface

uses crt, dos, overlay, common, timefunc;

procedure LogonMaint;
procedure LogoffMaint;
procedure DailyMaint;
procedure UpdateGeneral;

implementation

uses Email, Bulletin, mail7, ShortMsg, cuser, Vote, Event, Automsg;

procedure LogonMaint;
var
  LastCallerFile:file of LastCallerRec;
  LastCaller:LastCallerRec;
  lcts,vna,z:integer;
  bsince:boolean;
  c:char;
  s:astr;

  function CheckBirthday:boolean;
  var
    x:longint;
  begin
    x := date2pd(copy(pd2date(Thisuser.Birthdate), 1, 6) + copy(date, 7, 4));
    if (x > thisuser.laston) and (x <= Thisuser.Birthdate) then
      begin
        CheckBirthday := TRUE;
        bsince := (x < Thisuser.Birthdate);
      end
    else
      CheckBirthday := FALSE;
  end;

  procedure showbday(const s:astr);
  begin
    if (bsince) then printf('bdys'+s);      {* birthday occured SINCE laston *}
    if (nofile) then printf('bday'+s);      {* birthday TODAY *}
  end;

  procedure findchoptime;
  var lng,lng2,lng3:longint;
      eventnum:byte;

    procedure onlinetime;
    begin
      printf('revent'+cstr(eventnum));
      if nofile then
        begin
          print(^G^M^J);
          print('^8Note: ^5System event approaching.');
          print('System will be shut down in ' + FormattedTime(nsl));
          print(^M^J^G);
          pausescr(FALSE);
        end;
    end;

  begin
    if (exteventtime <> 0) then begin
      lng:=exteventtime;
      if (lng < nsl div 60) then
      begin
        choptime:=(nsl-(lng*60))+120; onlinetime; exit;
      end;
    end;
    lng:=1; lng2:=nsl div 60;
    if (lng2>180) then lng2:=180;
    while (lng<=lng2) do
    begin
      lng3:=lng*60;
      eventnum := checkevents(lng3);
      if (eventnum <> 0) then begin
        choptime:=(nsl-(lng*60))+60;
        onlinetime;
        exit;
      end;
      inc(lng,2);
    end;
  end;

begin
  if general.multinode then
    begin
      loadnode(node);
      if aacs(general.Invisible) and pynq('Invisible login? ') then
        begin
          Invisible := TRUE;
          sysoplog('Selected invisible mode.');
          noder.status := noder.status + [NInvisible];
        end
      else
        Invisible := FALSE;
      fillchar(noder.Invited,sizeof(noder.invited),0);
      fillchar(noder.Booted,sizeof(noder.booted),0);
      fillchar(noder.Forget,sizeof(noder.forget),0);
      noder.status := noder.status + [NAvail];
      savenode(node);
      update_node(0);

      for z := 1 to MaxNodes do
        begin
          loadnode(z);
          Noder.Forget[Node div 8] := Noder.Forget[Node div 8] - [Node mod 8];
          savenode(z);
        end;

    end;

  confsystem:=TRUE;
  if thisuser.lastconf in ['@'..'Z'] then
    currentconf:=thisuser.lastconf
  else
    currentconf:='@';

  mread:=0;
  extratime:=0;
  freetime:=0;
  credittime := 0;
  timeon := getpackdatetime;
  useron:=TRUE;
  com_flush_rx;

  status_screen(100,'Cleaning up work areas...',FALSE,s);
  purgedir(tempdir + 'ARC\', FALSE);
  purgedir(tempdir + 'QWK\', FALSE);
  purgedir(tempdir + 'UP\' , FALSE);
  purgedir(tempdir + 'CD\' , FALSE);

  DailyMaint;

  if ((CoSysOp) and (not fastLogon) and (Speed > 0)) then
    begin
      if pynq('Fast Logon? ') then fastLogon:=TRUE;
      nl;
    end;

  assign(LastCallerFile, general.datapath + 'laston.dat');
  reset(LastCallerFile);
  if (ioresult  = 2) then
    rewrite(LastCallerFile);

  {if (general.lcallinlogon) and (not fastLogon) then
    begin
      if (CoSysOp) then
        lcts := 10
      else
        lcts := 5;
      if (filesize(LastCallerFile) > 0) then
        begin
          nl;
          close(LastCallerFile);
          todayscallers(lcts, '');
          reset(LastCallerFile);
          pausescr(FALSE);
        end;
      end;}

  lcts := 0;
  for z := 0 to filesize(LastCallerFile) - 1 do
    begin
      read(LastCallerFile, LastCaller);
      if ((getpackdatetime div 86400) = (LastCaller.LogonTime div 86400)) then
        begin
          lcts := filesize(LastCallerFile) - z;
          break;
        end;
    end;
  if (lcts < 10) and (filesize(LastCallerFile) > 9) then
    lcts := 10;
  if (filesize(LastCallerFile) > lcts) and (lcts > 0) then
    begin
      for z := filesize(LastCallerFile) - lcts to (filesize(LastCallerFile) - 1) do
        begin
          sysoplog('moving ' + cstr(z) + ' to ' + cstr(z-(filesize(lastcallerfile) - lcts)));
          seek(LastCallerFile, z);
          read(LastCallerFile, LastCaller);
          seek(LastCallerFile, z - (FileSize(LastCallerFile) - lcts));
          write(LastCallerFile, LastCaller);
        end;
      seek(LastCallerFile, filesize(LastCallerFile) - lcts);
      truncate(LastCallerFile);
    end;
  fillchar(LastCaller, sizeof(LastCaller), 0);
  LastCaller.Node := Node;
  LastCaller.Caller := general.callernum;
  LastCaller.UserName := caps(thisuser.name);
  LastCaller.UserID := Usernum;
  LastCaller.Location := thisuser.citystate;
  if (Speed <> 0) then
    LastCaller.Speed := ActualSpeed;
  LastCaller.LogonTime := timeon;
  LastCaller.LogoffTime := timeon;    { in case never updated }
  LastCaller.NewUser := WasNewUser;
  LastCaller.Invisible := Invisible;
  seek(LastCallerFile, filesize(LastCallerFile));
  write(LastCallerFile, LastCaller);

  close(LastCallerFile);
  Lasterror := IOResult;

  if ((not fastLogon) and (not hangup)) then
    begin
      printf('Logon');
      if not nofile then
        pausescr(FALSE)
      else
        nofile:=FALSE;
      z:=0;
      repeat
        inc(z); printf('Logon'+cstr(z));
      until (z=9) or (nofile) or (hangup);

      printf('sl'+cstr(thisuser.sl));
      printf('dsl'+cstr(thisuser.dsl));
      for c:='A' to 'Z' do
        if (c in thisuser.ar) then printf('arlevel'+c);
      printf('user'+cstr(usernum));

      if newfiles(general.miscpath + 'onceonly.*',s) then
        printf('onceonly');

      if (CheckBirthday) then begin
        showbday(cstr(usernum));
        if nofile then showbday('');
        if nofile then
          if bsince then
            begin
              print('^3Happy Birthday, '+caps(thisuser.name)+' !!!');
              print('(a little late, but it''s the thought that counts!)'^M^J);
            end
          else
            begin
              print('Happy Birthday, '+caps(thisuser.name)+' !!!');
              print('You turned '+cstr(ageuser(thisuser.birthdate))+' today!!'^M^J);
            end;
        pausescr(FALSE);
        cls;
      end;
      nl;
      if (general.autominLogon) then
        readamsg;
      nl;
    end;

  savegeneral(TRUE);

  with thisuser do begin
    if ((not fastLogon) and (not hangup)) then
      begin

        if (general.yourinfoinLogon) then
          begin
            printf('yourinfo');
            nl;
          end;

        lil := 0;

        if (general.bullinLogon) and newfiles(general.miscpath + general.bulletprefix + '*.ASC',s) then
          if pynq('^5New bulletins: ' + s + '. Read them? ') then
            bulletins('')
          else
            nl;

       vna := unvotedtopics;
        if (vna>0) then
          prompt(^M^J'^5You have not voted on ^9'+cstr(vna)+'^5 voting question' + Plural(vna) + ^M^J);

         if (lil <> 0) then pausescr(FALSE);

        nl;
        update_screen;
      end;
  end;
  findchoptime;

  with thisuser do
    begin
      if (smw in flags) then
        begin
          rsm;
          nl;
        end;
    flags:=flags-[smw];
    if ((alert in flags) and (sysopavailable)) then chatcall:=TRUE;
    if (waiting<>0) then
      begin
        if (rmsg in thisuser.flags) then
          begin
            pausescr(FALSE);
            readmail
          end
        else
          begin
            dyny:=TRUE;
            if pynq('Read your Email? ') then readmail;
          end;
      end;
  end;

  if general.passwordchange>0 then
     if daynum(date)-thisuser.passwordchanged>=general.passwordchange then begin
        printf('pwchange');
        if nofile then
          begin
            print(^M^J'You must select a new password every '+cstr(general.passwordchange)+' days.'^M^J);
          end;
        cstuff(9,3,thisuser);
     end;

  fastLogon:=FALSE;
end;

procedure LogoffMaint;
var
  i,tt:integer;
  HistoryFile:file of historyrec;
  TodayHistory:HistoryRec;
  LastCallerFile:file of LastCallerRec;
  LastCaller:LastCallerRec;
begin
  com_flush_tx;

  loadnode(node);
  noder.user:=0;
  noder.status := [NActive];
  savenode(node);

  if (usernum > 0) then
    begin
      purgedir(tempdir + 'ARC\', FALSE);
      purgedir(tempdir + 'QWK\', FALSE);
      purgedir(tempdir + 'UP\' , FALSE);
      purgedir(tempdir + 'CD\' , FALSE);

      slogging:=TRUE;

      if (trapping) then
        begin
          if (hungup) then
            begin
              writeln(trapfile);
              writeln(trapfile,'NO CARRIER');
            end;
          close(trapfile); trapping:=FALSE;
        end;

      tt := (getpackdatetime - timeon) div 60;

      thisuser.laston:= date2pd(date); inc(thisuser.loggedon);

      (* if not logged in, but logged on *)

      thisuser.illegal:=0;
      thisuser.ttimeon:=thisuser.ttimeon + tt;
      thisuser.tltoday := nsl div 60;

      if (choptime <> 0) then
        inc(thisuser.tltoday,choptime div 60);

      thisuser.lastmbase:=board; thisuser.lastfbase:=fileboard;

      if ((usernum>=1) and (usernum<=maxusers-1)) then
        saveurec(thisuser,usernum);

      for i:=1 to hiubatchv do
        release(ubatchv[i]); {* release dynamic memory *}

      if (hungup) then sl1('^7-= Hung Up =-');
      sl1('^4Read: ^3'+cstr(mread)+'^4 / Time on: ^3'+cstr(tt));
    end;
  Lasterror := IOResult;

  assign(HistoryFile, General.DataPath + 'HISTORY.DAT');
  reset(HistoryFile);
  if (IOResult = 2) then
    begin
      rewrite(HistoryFile);
      fillchar(TodayHistory, sizeof(TodayHistory), 0);
      TodayHistory.Date := Date;
    end
  else
    begin
      seek(HistoryFile, filesize(HistoryFile) - 1);
      read(HistoryFile, TodayHistory);
    end;
  inc(TodayHistory.active, (getpackdatetime - timeon) div 60);
  inc(TodayHistory.callers);
  if (WasNewUser) then
    inc(TodayHistory.newusers);
  inc(TodayHistory.posts, ptoday);
  inc(TodayHistory.email, etoday);
  inc(TodayHistory.feedback, ftoday);
  inc(TodayHistory.uploads, utoday);
  inc(TodayHistory.downloads, dtoday);
  inc(TodayHistory.uk, uktoday);
  inc(TodayHistory.dk, dktoday);
  if (exist(start_dir + '\critical.err')) then
    begin
      inc(TodayHistory.errors);
      kill(start_dir + '\critical.err');
    end;
  seek(HistoryFile, filesize(HistoryFile) - 1);
  write(Historyfile, TodayHistory);
  if (Speed <> 0) then
    case (Speed div 100) of
      3,6:inc(TodayHistory.userbaud[0]);
      12:inc(TodayHistory.userbaud[1]);
      24:inc(TodayHistory.userbaud[2]);
      48,72:inc(TodayHistory.userbaud[3])
      else
        inc(TodayHistory.userbaud[4]);
    end;
  close(HistoryFile);
  Lasterror := IOResult;

  assign(LastCallerFile, general.datapath + 'laston.dat');
  reset(LastCallerFile);
  if (ioresult  = 2) then
    rewrite(LastCallerFile);
  for i := filesize(LastCallerFile) - 1 downto 0 do
    begin
      seek(LastCallerFile, i);
      read(LastCallerFile, LastCaller);
      if (LastCaller.Node = Node) and (LastCaller.UserID = UserNum) then
        with LastCaller do
          begin
            LogOffTime := getpackdatetime;
            Uploads := utoday;
            Downloads := dtoday;
            UK := uktoday;
            DK := dktoday;
            MsgRead := mread;
            MsgPost := ptoday;
            EmailSent := etoday;
            FeedbackSent := ftoday;
            seek(LastCallerFile, i);
            write(LastCallerFile, LastCaller);
            break;
          end;
    end;
  close(LastCallerFile);
  Lasterror := IOResult;
end;

procedure DailyMaint;
var ul:text;
    hf:file of historyrec;
    TodayHistory:HistoryRec;
    s,s1:astr;
    n,d:integer;
    x:smr;

begin
  if ( date2pd(general.lastdate) <> date2pd(date) ) then
    begin
      general.lastdate := date;

      if general.multinode then savegeneral(FALSE);

      status_screen(100,'Updating data files ...',FALSE,s);

      reset(smf);
      if (ioresult = 0) then
        begin
          if (filesize(smf) > 1) then
            begin
              n:=0; d:=0;
              while (n < filesize(smf)) do
                begin
                  seek(smf, n); read(smf, x);
                  if (x.destin <> -1) then
                    if (n = d) then
                      inc(d)
                    else
                      begin
                        seek(smf, d); write(smf, x);
                        inc(d);
                      end;
                  inc(n);
                end;
              seek(smf, d);
              truncate(smf);
            end;
          close(smf);
        end;
      Lasterror := IOResult;

      assign(hf,general.datapath+'history.dat');
      reset(hf);
      if (ioresult = 2) then
        rewrite(hf)
      else
        begin
          seek(hf, filesize(hf) - 1);
          read(hf, Todayhistory);
          inc(general.Daysonline);
          inc(general.Totalcalls, Todayhistory.callers);
          inc(general.Totalusage, Todayhistory.active);
          inc(general.Totalposts, Todayhistory.posts);
          inc(general.Totaldloads, Todayhistory.downloads);
          inc(general.Totaluloads, Todayhistory.uploads);
        end;

      if (date2pd(Todayhistory.date) <> date2pd(date)) then
        begin
          if exist(general.logspath+'sysop'+cstr(general.backsysoplogs)+'.log') then
             kill(general.logspath+'sysop'+cstr(general.backsysoplogs)+'.log');

          for n:=general.backsysoplogs-1 downto 1 do
            if (exist(general.logspath+'sysop'+cstr(n)+'.log')) then
              begin
                assign(ul,general.logspath+'sysop'+cstr(n)+'.log');
                rename(ul,general.logspath+'sysop'+cstr(n+1)+'.log');
              end;

          sl1('');
          sl1('Total mins active..: '+cstr(TodayHistory.active));
          sl1('Percent of activity: '+sqoutsp(ctp(TodayHistory.active,1440))+' ('+
                                        cstr(TodayHistory.callers)+' calls)');
          sl1('New users..........: '+cstr(TodayHistory.newusers));
          sl1('Public posts.......: '+cstr(TodayHistory.posts));
          sl1('Private mail sent..: '+cstr(TodayHistory.email));
          sl1('Feedback sent......: '+cstr(TodayHistory.feedback));
          sl1('Critical errors....: '+cstr(TodayHistory.errors));
          sl1('Downloads today....: '+cstr(TodayHistory.downloads)+'-'+cstr(TodayHistory.dk)+'k');
          sl1('Uploads today......: '+cstr(TodayHistory.uploads)+'-'+cstr(TodayHistory.uk)+'k');

          fillchar(TodayHistory,sizeof(TodayHistory),0);
          TodayHistory.Date := Date;

          seek(hf,filesize(hf));
          write(hf,TodayHistory);
          close(hf);

          if general.multinode and exist(tempdir+'templog.'+cstr(node)) then
            begin
              assign(ul,general.logspath+'sysop.log');
              append(ul);
              if (ioresult = 2) then
                rewrite(ul);
              reset(sysopf);
              while not eof(sysopf) do
                begin
                  readln(sysopf,s);
                  writeln(ul,s);
                end;
              close(sysopf); close(ul);
              erase(sysopf);
            end;

          assign(sysopf,general.logspath+'sysop.log');
          rename(sysopf,general.logspath+'sysop1.log');

          assign(sysopf,general.logspath+'sysop.log');

          rewrite(sysopf);
          close(sysopf);

          sl1(^M^J'              Renegade SysOp log for '+date+^M^J);

          if general.multinode then
            assign(sysopf,tempdir+'templog.'+cstr(node))
          else
            assign(sysopf,general.logspath+'sysop.log');

          append(sysopf);
          if (ioresult = 2) then
            rewrite(sysopf);
          close(sysopf);
        end
      else
        close(hf);
    end;

  if (Speed > 0) then
    inc(Todaycallers);

  if (slogseparate in thisuser.sflags) then
    begin
      assign(sysopf1,general.logspath+'slog'+cstr(usernum)+'.log');
      append(sysopf1);
      if (ioresult = 2) then begin
        rewrite(sysopf1);
        append(sysopf1);
        s:=''; s1:='';
        for n:=1 to 26+length(thisuser.name) do begin s:=s+'_'; s1:=s1+' '; end;
        writeln(sysopf1,'');
        writeln(sysopf1,'  '+s);
        writeln(sysopf1,'>>'+s1+'<<');
        writeln(sysopf1,'>> Renegade SysOp Log for '+caps(thisuser.name)+': <<');
        writeln(sysopf1,'>>'+s+'<<');
        writeln(sysopf1,'');
      end;
      writeln(sysopf1);
      s:='^3Logon ^5['+dat+']^4 (';
      if (Speed > 0) then
        s := s + cstr(ActualSpeed) + ' baud)'
      else
        s := s + 'Keyboard)';
      if (general.stripclog) then s:=stripcolor(s);
      writeln(sysopf1,s);
      close(sysopf1);
    end;

  s:='^3'+cstr(general.callernum)+'^4 -- ^0'+caps(thisuser.name)+'^4 -- ^3'+
     'Today '+cstr(thisuser.ontoday);
  if (trapping) then s:=s+'^0*';
  sl1(s);
  nl;
  savegeneral(FALSE);
  Lasterror := IOResult;
end;

procedure UpdateGeneral;
var hf:file of historyrec;
    history:historyrec;
    i:integer;
begin
    assign(hf,general.datapath+'history.dat');
    reset(hf);
    if (ioresult = 2) then
      rewrite(hf);
    general.daysonline:=filesize(hf);
    general.totalusage:=0; general.totalposts:=0;
    general.totaldloads:=0; general.totaluloads:=0;
    general.totalcalls:=0;
    for i:=1 to filesize(hf) - 1 do begin
        read(hf,history);
        inc(general.totalcalls,history.callers);
        inc(general.totalusage,history.active);
        inc(general.totalposts,history.posts);
        inc(general.totaldloads,history.downloads);
        inc(general.totaluloads,history.uploads);
    end;
    if general.totalusage<1 then general.totalusage:=1;
    if general.daysonline<1 then general.daysonline:=1;
    savegeneral(FALSE);
    close(hf);
end;

end.
