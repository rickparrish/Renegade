{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O-,R-,S+,V-}

{  Main menu handling routines }

Unit Menus;

Interface

uses crt, dos, overlay, myio, common;

Procedure readin2;
Procedure mainmenuhandle(var cmd:astr);
Procedure fcmd(const cmd:astr; var i:integer; noc:integer;
               var cmdexists,cmdnothid:boolean);
Procedure domenuexec(cmd:astr; var newmenucmd:astr);
Procedure domenucommand(var done:boolean; const cmd:astr; var newmenucmd:astr);

Implementation

Uses
  boot,     Sysop1,   Sysop2,   Sysop3,   Sysop4,   Sysop6,   Script,
  Sysop7,   Sysop8,   Sysop9,   Sysop10,  Sysop11,  Mail0,    Mail1,
  Email,    Mail5,    Mail6,    Mail7,    Arcview,  Menus4,   SysChat,
  File0,    File1,    File2,    File5,    File6,    File8,    File9,
  File10,   File11,   Multnode, File12,   File13,   File14,   Archive1,
  Archive2, Archive3, TimeBank, Bulletin, User,     Automsg,  BBSList,
  CUser,    Doors,    Menus2,   Menus3,   offline,  vote,     File3;

Procedure readin2;
var s:string[20];
    nacc:boolean;
begin
  readin;
  nacc:=FALSE;
  with menur do begin
    if (not aacs(acs)) or (password<>'') then
    begin
      nacc:=TRUE;
      if (password<>'') then
      begin
        echo:=FALSE;
        prt(^M^J'Password: '); input(s,15);
        echo:=TRUE;
        if (s=password) then nacc:=FALSE;
      end;
      if (nacc) then
      begin
        printf('noaccess');
        if (nofile) then
          begin
            print(^M^J'Access denied.');
            pausescr(FALSE);
          end;
        curmenu:=general.menupath+fallback+'.mnu';
        readin;
      end;
    end;
    if (not nacc) then
      if (forcehelplevel <> 0) then
        chelplevel := forcehelplevel
      else
        if (novice in thisuser.flags) or (OkRIP) then
          chelplevel := 2
        else
          chelplevel := 1;
  end;
end;

procedure checkforcelevel;
begin
  if (chelplevel<menur.forcehelplevel) then chelplevel:=menur.forcehelplevel;
end;

procedure getcmd(var s:astr);
var
  s1,ss,oss,shas0,shas1:astr;
  i:integer;
  c:char;
  oldco:byte;
  gotcmd,has0,has1,has2:boolean;
begin
  s:='';
  if (buf<>'') then
    if buf[1] = '`' then
    begin
      buf:=copy(buf,2,length(buf)-1);
      i:=pos('`',buf);
      if (i<>0) then
      begin
        s:=allcaps(copy(buf,1,i-1)); buf:=copy(buf,i+1,length(buf)-i);
        nl; exit;
      end;
    end;

  shas0:='?'; shas1:='';
  has0:=FALSE; has1:=FALSE; has2:=FALSE;

  { find out what kind of 0:"x", 1:"/x", and 2:"//xxxxxxxx..." commands
    are in this menu. }

  for i:=1 to noc do
    if ((i <= noc - GlobalMenuCommands) or not (NoGlobalUsed in menur.menuflags)) then
      if (aacs(MenuCommand^[i].acs)) then
        if (MenuCommand^[i].ckeys[0]=#1) then
          begin
            has0:=TRUE;
            shas0:=shas0+MenuCommand^[i].ckeys;
          end
        else
          if ((MenuCommand^[i].ckeys[1]='/') and (MenuCommand^[i].ckeys[0]=#2)) then
            begin
              has1:=TRUE;
              shas1:=shas1+MenuCommand^[i].ckeys[2];
             end
          else
            has2:=TRUE;

  oldco:=curco;

  gotcmd:=FALSE; ss:='';

  if (trapping) then
    flush(trapfile);

  {Before accepting MENU input}

  if (not (hotkey in thisuser.flags)) or (forceline in menur.menuflags) then
    inputmain(s,60,'UL')
  else begin
    repeat
      i := getkey;    {After/during MENU input}
      if (i = F_UP) or (i=F_DOWN) or (i=F_LEFT) or (i=F_RIGHT) then
        begin
          case i of
            F_UP: if (pos(#255, menukeys) > 0) then
                    begin
                      s := 'UP_ARROW';
                      gotcmd := TRUE;
                      exit;
                    end;
            F_DOWN: if (pos(#254, menukeys) > 0) then
                      begin
                        s := 'DOWN_ARROW';
                        gotcmd := TRUE;
                        exit;
                      end;
            F_LEFT: if (pos(#253, menukeys) > 0) then
                      begin
                        s := 'LEFT_ARROW';
                        gotcmd := TRUE;
                        exit;
                      end;
            F_RIGHT: if (pos(#252, menukeys) > 0) then
                        begin
                          s := 'RIGHT_ARROW';
                          gotcmd := TRUE;
                          exit;
                        end;
          end;
        end;

      c:=upcase(char(i));
      oss:=ss;
      if (ss='') then
        begin
          if (c=#13) then
            gotcmd:=TRUE;
          if ((c='/') and ((has1) or (has2) or (so))) then
            ss:='/';
          if (((fqarea) or (rqarea) or (mqarea) or (vqarea)) and (c in ['0'..'9'])) then
            begin
              ss:=c;
              if (rqarea) and (HiMsg <= 9) then
                gotcmd := TRUE
              else
                if (fqarea) and (MaxFBases <= 9) then
                  gotcmd := TRUE
                else
                  if (mqarea) and (MaxMBases <= 9) then
                    gotcmd := TRUE;
            end
          else
            if (pos(c, shas0) <> 0) then
              begin
                gotcmd:=TRUE;
                ss:=c;
              end;
        end
      else
        if (ss='/') then
          begin
            if (c=^H) then
              ss:='';
            if ((c='/') and ((has2) or (so))) then
              ss:=ss+'/';
            if ((pos(c,shas1)<>0) and (has1)) then
              begin
                gotcmd:=TRUE;
                ss:=ss+c;
              end;
          end
        else
          if (copy(ss,1,2)='//') then
            begin
              if (c=#13) then
                gotcmd:=TRUE
              else
                if (c=^H) then
                  dec(ss[0])
                else
                  if (c=^X) then
                    begin
                      for i:=1 to length(ss)-2 do
                        backspace;
                      ss:='//';
                      oss:=ss;
                    end
                  else
                    if ((length(ss)<62) and (c>=#32) and (c<=#127)) then
                      ss:=ss+c;
            end
          else
            if ((length(ss)>=1) and (ss[1] in ['0'..'9']) and
                ((fqarea) or (rqarea) or (mqarea) or (vqarea))) then
              begin
                if (c=^H) then
                  dec(ss[0]);
                if (c=#13) then
                  gotcmd:=TRUE;
                if (c in ['0'..'9']) then
                  begin
                    ss:=ss+c;
                    if (vqarea) and (length(ss)=2) then
                      gotcmd := TRUE
                    else
                      if (rqarea) and (length(ss) = length(cstr(HiMsg))) then
                        gotcmd := TRUE
                      else
                        if (mqarea) and (length(ss) = length(cstr(MaxMBases))) then
                          gotcmd := TRUE
                        else
                          if (fqarea) and (length(ss) = length(cstr(MaxFBases))) then
                            gotcmd:=TRUE;
                  end;
              end;

      if ((length(ss)=1) and (length(oss)=2)) then setc(oldco);
      if (oss<>ss) then begin
        if (length(ss)>length(oss)) then prompt(ss[length(ss)]);
        if (length(ss)<length(oss)) then backspace;
      end;
      if ((not (ss[1] in ['0'..'9'])) and
        ((length(ss)=2) and (length(oss)=1))) then UserColor(6);

    until ((gotcmd) or (hangup));
    UserColor(1);

    if (copy(ss,1,2)='//') then ss:=copy(ss,3,length(ss)-2);

    s:=ss;
  end;

  nl;

  if (pos(';',s)<>0) then                 {* "command macros" *}
    if (copy(s,1,2)<>'\\') then begin
      if (hotkey in thisuser.flags) then begin
        s1:=copy(s,2,length(s)-1);
         if (copy(s1,1,1)='/') then s:=copy(s1,1,2) else s:=s1[1];
         s1:=copy(s1,length(s)+1,length(s1)-length(s));
      end else begin
        s1:=copy(s,pos(';',s)+1,length(s)-pos(';',s));
        s:=copy(s,1,pos(';',s)-1);
      end;
      while (pos(';',s1)<>0) do s1[pos(';',s1)]:=^M;
      buf := s1;
    end;
end;

procedure mainmenuhandle(var cmd:astr);
var
  newarea:integer;
  i:integer;
  done:boolean;
  newmenucmd:astr;
begin
  tleft;

  checkforcelevel;

  if ((forcepause in menur.menuflags) and (chelplevel>1) and (lastcommandgood))
    then pausescr(FALSE);
  lastcommandgood:=FALSE;
  menuaborted:=FALSE;
  abort := FALSE;

  showthismenu;

  i := 1;
  while (i <= noc) do
  begin
    if (MenuCommand^[i].ckeys = 'EVERYTIME') then
      if (aacs(MenuCommand^[i].acs)) then
        domenucommand(done, MenuCommand^[i].cmdkeys + MenuCommand^[i].options,newmenucmd);
    inc(i);
  end;

  if general.multinode then check_status;

  if ((not (nomenuprompt in menur.menuflags)) and (not menuaborted)) and not
     (OKAnsi and (NoGenericAnsi in menur.menuflags) and not (OkAvatar or OKRIP)) and not
     (OkAvatar and (NoGenericAvatar in menur.menuflags) and not OkRIP) and not
     (OkRIP and (NoGenericRIP in menur.menuflags)) then begin
    nl;
    if (autotime in menur.menuflags) then
      print('^3[Time Left:'+ctim(nsl)+']');
    prompt(menur.menuprompt);
  end;

  TempPause := (pause in thisuser.flags);

  getcmd(cmd);

  if (cmd = '') and (pos(#13, menukeys) > 0) then
    cmd := 'ENTER';

  if (cmd='?') then begin
    cmd:='';
    inc(chelplevel);
    if (chelplevel > 3) then chelplevel := 3;
    {if ((menur.longmenu='') and (chelplevel>=3)) then chelplevel:=2;}
  end else
    if (menur.forcehelplevel<>0) then chelplevel:=menur.forcehelplevel
    else
      if (novice in thisuser.flags) or (OkRIP) then
        chelplevel := 2
      else
        chelplevel := 1;

  checkforcelevel;

  if (fqarea) or (mqarea) or (vqarea) or (rqarea) then begin
    newarea:=value(cmd);
    if ((newarea<>0) or (cmd[1] = '0')) then begin
      if (fqarea) then begin
        if (newarea>=0) and (newarea<=MaxFBases) then
          changefileboard(afbase(newarea));
      end else
        if (mqarea) then
          begin
            if (newarea>=0) and (newarea<=MaxMBases) then
              changeboard(ambase(newarea))
          end
        else
          if (vqarea) then
            voteone(newarea)
          else
            if (rqarea) and (newarea > 0) and (newarea <= himsg) then
              if not (mbforceread in memboard.mbstat) or (newarea <= msg_on) then
                begin
                  Msg_On := newarea - 1;
                  treadprompt := 18;
                end
              else
                print('You must read all of the messages in this area.');
      cmd:='';
    end;
  end;
end;

procedure fcmd(const cmd:astr; var i:integer; noc:integer;
               var cmdexists,cmdnothid:boolean);
var done:boolean;
begin
  done:=FALSE;
  repeat
    inc(i);
    if (i <= noc) and (cmd = MenuCommand^[i].ckeys) then
      begin
        cmdexists:=TRUE;
        if (oksecurity(i,cmdnothid)) then
          done:=TRUE;
      end;
    if ((i > noc - GlobalMenuCommands) and (NoGlobalUsed in menur.menuflags)) then
      begin
        i := 0;
        cmdexists:=FALSE;
        done := TRUE;
      end;
  until (i > noc) or (done);
  if (i > noc) then i:=0;
end;

procedure domenuexec(cmd:astr; var newmenucmd:astr);
var cmdacs,cmdnothid,cmdexists,done:boolean;
    i:integer;

begin
  if (newmenucmd<>'') then
    begin
      cmd:=newmenucmd;
      newmenucmd:='';
    end;
  cmdacs:=FALSE; cmdexists:=FALSE; cmdnothid:=FALSE; done:=FALSE;
  i:=0;
  repeat
    fcmd(cmd, i, noc, cmdexists, cmdnothid);
    if (i<>0) then begin
      cmdacs:=TRUE;
      domenucommand(done,MenuCommand^[i].cmdkeys+MenuCommand^[i].options,newmenucmd);
    end;
  until ((i=0) or (done));
  if (not done) and (cmd<>'') then
    if ((not cmdacs) and (cmd<>'')) then begin
      nl;
      if ((cmdnothid) and (cmdexists)) then
        print('Insufficient clearence for this command.')
      else
        print('Invalid command.');

      end;
end;

procedure domenucommand(var done:boolean; const cmd:astr; var newmenucmd:astr);
var mheader:mheaderrec;
    cms,s:astr;
    i:integer;
    c1,c2,c:char;
    b,nocmd:boolean;

  function semicmd(x:integer):string;
  var s:astr;
      i,p:byte;
  begin
    s:=cms; i:=1;
    while (i<x) and (s<>'') do begin
      p:=pos(';',s);
      if (p<>0) then s:=copy(s,p+1,length(s)-p) else s:='';
      inc(i);
    end;
    while (pos(';',s)<>0) do s:=copy(s,1,pos(';',s)-1);
    semicmd:=s;
  end;

begin
  newmenutoload:=FALSE;
  newmenucmd:='';
  c1:=cmd[1]; c2:=cmd[2];
  cms:=copy(cmd,3,length(cmd)-2);
  nocmd:=FALSE;
  abort := FALSE;
  lastcommandovr:=FALSE;
  case c1 of
    '$':case c2 of
          'D':deposit(cms);
          'W':withdraw(cms);
          '+':inc(thisuser.credit, value(cms));
          '-':inc(thisuser.debit, value(cms));
        end;
    '-':case c2 of
          'C':status_screen(100,cms,FALSE,cms);
          'F':printf(mci(cms));
          'L':prompt(cms);
          'Q':readq(general.miscpath + cms);
          'R':readasw1(cms);
          'S':sysoplog(MCI(cms));
          ';':begin
                s := cms;
                while (pos(';',s) >0) do
                  s[pos(';',s)] := ^M;
                buf := s;
              end;
          '$':if (semicmd(1)<>'') then begin
                if (semicmd(2)='') then prt(':') else prt(semicmd(2));
                echo:=FALSE;
                input(s,20);
                echo:=TRUE;
                if (s<>semicmd(1)) then begin
                  done:=TRUE;
                  if (semicmd(3)<>'') then print(semicmd(3));
                end;
              end;
          'Y':if (semicmd(1) <> '') and not(pynq(semicmd(1))) then
                begin
                  done:=TRUE;
                  if (semicmd(2)<>'') then print(semicmd(2));
                end;
          'N':if (semicmd(1) <> '') and (pynq(semicmd(1))) then
                begin
                  done:=TRUE;
                  if (semicmd(2)<>'') then print(semicmd(2));
                end;
          '^','/','\':dochangemenu(done,newmenucmd,c2,cms);
        else  nocmd:=TRUE;
        end;
    'A':case c2 of
          'A','C','M','T':doarccommand(c2);
          'E':extracttotemp;
          'G':userarchive;
          'R':rezipstuff;
        else  nocmd:=TRUE;
        end;
    'B':case c2 of
          '?':batchinfo;
          'C':if (cms='U') then clearubatch else clearbatch;
          'D':batchdl;
          'L':if (cms='U') then listubatchfiles else listbatchfiles;
          'R':if (cms='U') then removeubatchfiles else removebatchfiles;
          'U':batchul(FALSE,0);
        else  nocmd:=TRUE;
        end;
    'D':case c2 of
          'P','C','D','G','S','W','-':dodoorfunc(c2,cms);
        else nocmd:=TRUE;
        end;
    'F':case c2 of
          'A':fbasechange(done,cms);
          'B':idl(true,cms);
          'D':idl(false,cms);
          'F':searchd;
          'L':listfiles(cms);
          'N':nf(allcaps(cms));
          'P':pointdate;
          'S':search;
          'U':iul;
          'V':lfii;
          'Z':setdirs;
          '@':createtempdir;
          '#':begin
                print(^M^J'Enter the number of a file base to change to.');
                if (novice in thisuser.flags) then pausescr(FALSE);
              end;
        else  nocmd:=TRUE;
        end;
    'H':case c2 of
          'C':if pynq(cms) then begin
                cls;
                printf('logoff');
                hangup:=TRUE;
                hungup:=FALSE;
              end;
          'I':hangup:=TRUE;
          'M':begin
                print(^M^J + cms);
                hangup:=TRUE;
              end;
        else  nocmd:=TRUE;
        end;
    'L':tfileprompt := ord(c2) - 48;
    'M':case c2 of
          'A':mbasechange(done,cms);
          'E':ssmail(cms);
          'K':showemail;
          'L':smail(TRUE);
          'M':readmail;
          'N':StartNewScan(cms);
          'P':if (mbprivate in memboard.mbstat) then
                begin
                  nl;
                  post(-1,mheader.from,pynq('Is this to be a private message? '))
                end
              else
                post(-1,mheader.from,FALSE);
          'R':readmessages;
          'S':scanmessages(cms);
          'U':begin
                loadboard(board);
                ulist(memboard.acs);
              end;
          'Y':scanyours;
					'Z':chbds;
          '#':begin
                print(^M^J'Enter the number of a message base to change to.');
                if (novice in thisuser.flags) then pausescr(FALSE);
              end;
        else  nocmd:=TRUE;
        end;
    'N':case c2 of
          'A':toggle_chat_avail;
          'D':dump_node;
          'O':begin
                list_nodes;
                if (novice in thisuser.flags) then
                  pausescr(FALSE);
              end;
          'P':page_user;
          'G':multiline_chat;
          'S':send_message(cms);
          'T':if aacs(general.Invisible) then
                begin
                  Invisible := not Invisible;
                  loadnode(node);
                  if Invisible then
                    noder.status := noder.status + [NInvisible]
                  else
                    noder.status := noder.status - [NInvisible];
                  savenode(node);
                  print(^M^J'Invisible mode is now '+onoff(Invisible));
                end;
          'W':begin
                loadnode(node);
                noder.activity := 255;
                noder.description := cms;
                savenode(node);
              end;
        end;
    'O':case c2 of
          '1','2':tshuttlelogon:=ord(c2)-48;
          'A':begin
                s:=copy(cms,pos(';',cms)+1,1);
                autovalidationcmd(copy(cms,1,pos(';',cms)-1),s[1]);
              end;
          'B':AddEditBBSList(cms);
          'C':reqchat(cms);
          {'E':pausescr(FALSE);}
          'F':changearflags(cms);
          'G':changeacflags(cms);
          'L':begin                         {procedure found in bulletin.pas}
              if pos(';',cms) <> 0 then
                begin
                 cms:=copy (cms, pos(';',cms)+1, (length(cms)) - (pos(';',cms)));
                 s:= copy (cms,1, pos(';',cms)-1);
                end
                else s:='0';
              todayscallers(value(s), cms);
              end;
          {'N':cls;}
          'P':cstuff(value(cms),2,thisuser);
          'R':changeconf(cms);
          'S':bulletins(cms);
          'T':begin {place addtolastcaller procedure here} end;
          'U':ulist(cms);
          'V':ViewBBSList(cms);
        else  nocmd:=TRUE;
        end;
    'R':case c2 of
          '#':begin
                print(^M^J'Enter the number of a message to read it.');
                if (novice in thisuser.flags) then
                  pausescr(FALSE);
              end;
          'A':treadprompt := 1;
          '-':treadprompt := 2;
          'M':treadprompt := 3;
          'X':treadprompt := 4;
          'E':treadprompt := 5;
          'R':treadprompt := 6;
          'I':if (not (mbforceread in memboard.mbstat)) or (CoSysOp) then
                treadprompt := 7
              else
                print('You must read all of the messages in this area.');
          'B':treadprompt := 8;
          'F':treadprompt := 9;
          'C':treadprompt := 10;
          'D':treadprompt := 11;
          'H':treadprompt := 12;
          'G':if (not (mbforceread in memboard.mbstat)) or (CoSysOp) then
                treadprompt := 13
              else
                print('You must read all of the messages in this area.');
          'Q':if (not (mbforceread in memboard.mbstat)) or (CoSysOp) then
                treadprompt := 14
              else
                print('You must read all of the messages in this area.');
          'L':treadprompt := 15;
          'U':treadprompt := 16;
          'T':treadprompt := 17;
          'N':treadprompt := 18;
        else nocmd:=TRUE;
        end;
    'U':case c2 of
          'A':replyamsg;
          'R':readamsg;
          'W':wamsg;
        else nocmd:=TRUE;
        end;
    'V':case c2 of
          '#':print(^M^J'Enter the number of the topic to vote on.');
          'A':addtopic;
          'L':listtopics(FALSE);
          'R':results(FALSE);
          'T':trackuser;
          'U':results(TRUE);
          'V':voteall;
        else  nocmd:=TRUE;
        end;
    '!':case c2 of
          'P':messagepointers;
          'D':downloadpacket;
          'U':uploadpacket(FALSE);
        end;
    '*':case c2 of
          '=':showcmds(0);
          'B':if (checkpw) then begin
                sysoplog('* Message base edit');
                boardedit;
              end;
          'C':if (checkpw) then chuser;
          'D':if (checkpw) then
                begin
                  sysoplog('* Entered Dos Emulator');
                  minidos;
                end;
          'E':if (checkpw) then begin
                sysoplog('* Event edit');
                eventedit;
              end;
          'F':if (checkpw) then begin
                sysoplog('* File base edit');
                dlboardedit;
              end;
          'V':if (checkpw) then begin
                sysoplog('* Vote edit');
                editvotes;
              end;
          'L':if (checkpw) then showlogs;
          'N':tedit1;
          'P':if (checkpw) then begin
                sysoplog('* System configuration change');
                changestuff;
              end;
          'R':if (checkpw) then begin
                sysoplog('* Conference editor');
                confeditor;
              end;
          'U':if (checkpw) then begin
                sysoplog('* user editor');
                uedit(usernum);
              end;
          'X':if (checkpw) then begin
                sysoplog('* Protocol editor');
                exproedit;
              end;
          'Z':begin
                sysoplog('+ Viewed History');
                history;
              end;
          '1':begin
                sysoplog('* Edited files'); editfiles;
              end;
          '2':begin
                sysoplog('* Sorted files'); sort;
              end;
          '3':if (checkpw) then begin
                sysoplog('* Read Private Mail');
                mailr;
              end;
          '4':if (cms='') then do_unlisted_download
                else unlisted_download(cms);
          '5':begin
                sysoplog('* Rechecked files');
                recheck;
              end;
          '6':if (checkpw) then uploadall;
          '7':validatefiles;
          '8':addgifspecs;
          '9':packmessagebases;
          '#':if (checkpw) then begin
                sysoplog('* Menu edit');
                s := curmenu;
                menu_edit;
                first_time:=TRUE;
                curmenu := s;
                readin;
              end;
          '$':dirf(TRUE);
          '%':dirf(FALSE);
        else  nocmd:=TRUE;
        end;
  else
        nocmd:=TRUE;
  end;
  lastcommandgood:=not nocmd;
  if (lastcommandovr) then lastcommandgood:=FALSE;
  if (nocmd) then
    if (CoSysOp) then
    begin
      s:='Invalid command keys: '+cmd;
      sysoplog(s);
      print(^M^J + s);
    end;
  if (newmenutoload) then begin
    readin2;
    lastcommandgood:=FALSE;
    if (newmenucmd='') then begin
      i:=1;
      while ((i<=noc) and (newmenucmd='')) do
      begin
        if (MenuCommand^[i].ckeys='FIRSTCMD') then
          if (aacs(MenuCommand^[i].acs)) then newmenucmd:='FIRSTCMD';
        inc(i);
      end;
    end;
  end;
end;

end.
