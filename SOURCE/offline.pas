{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S-,V-}

unit offline;

interface

uses crt, dos, overlay, timefunc, common;

procedure messagepointers;
procedure downloadpacket;
procedure uploadpacket(Already:boolean);

implementation

uses file0, file2, file8, file11, archive1, mail0, mail1, mail5, execbat, nodelist;

type
  bsingle = array[0..3] of byte;
  ndxrec= record
    pointer:bsingle;
    conf:byte;
  end;

  qwkheaderec=
    record
      flag:char;
      num:array[1..7] of char;
      msgdate:array[1..8] of char;
      msgtime:array[1..5] of char;
      msgto:array[1..25] of char;
      msgfrom:array[1..25] of char;
      msgsubj:array[1..25] of char;
      msgpword:string[11];
      rnum:string[7];
      numblocks:array[1..6] of char;
      status:byte;
      mbase:word;
      crap:string[3];
    end;

procedure messagepointers;
var
  s:astr;
  dt:datetime;
  x:word;
  oldboard:word;
  l:longint;
begin
  print(^M^J'Enter oldest date for new msgs: '^M^J);
  prt('mm/dd/yyyy: ');
  inputformatted(s,'##/##/####',TRUE);
  if (daynum(s)=0) then print('Illegal date.')
     else if (s<>'') then begin
        print(^M^J'Current newscan date is now '+s);
        oldboard := board;
        fillchar(dt, sizeof(dt), 0);
        dt.month:=value(copy(s,1,2));
        dt.day:=value(copy(s,4,2));
        dt.year:=value(copy(s,7,4));
        l := datetopack(dt);
        for x:=1 to MaxMBases do
          begin
            initboard(x);
            SaveLastRead(l);
          end;
        board := oldboard;
        initboard(board);
        sl1('Reset last read pointers.');
     end;
  nl;
end;

procedure downloadpacket;
var msgfile:file;
    t:text;
    UseBoardNumber,availboards,i,cn,x,totload,newm,yourm,yourt:integer;
    marker,lastk,tmsg,tnew:longint;
    AutoLogoff,oldconf,dok,kabort,ok,nospace:boolean;
    s,texts:string;
    indexr:ndxrec;
    ndxfile,pndxfile:file of ndxrec;
    mheader:mheaderrec;
    qwkheader:qwkheaderec;
    tooktime,lastupdate:longint;
    dt4:datetime;
    OldActivity:byte;
    Junk:char;

  procedure real_to_msb (preal : real; var b : bsingle);
  var
    r : array [0 .. 5] of byte absolute preal;
  begin
    b [3] := r [0];
    move (r [3], b [0], 3);
  end;

  procedure kill_email;
  var
    i:word;
  begin
    initboard(-1);
    reset(msghdrf);
    if (IOResult = 0) then
      begin
        for i := 1 to filesize(msghdrf) do
          begin
            seek(msghdrf, i - 1);
            read(msghdrf, mheader);
            if ToYou(mheader) then
              begin
                mheader.status := mheader.status + [mdeleted];
                seek(msghdrf, i - 1);       { inline for speed }
                write(msghdrf, mheader);
              end
          end;
        close(msghdrf);
      end;
    thisuser.waiting := 0;
  end;

procedure update_display;
begin
  lastupdate:=timer;
  if not abort then
    prompt(' ‚' + mrn(cstr(newm),7) + 'ƒ' + mrn(cstr(yourm),6) +
           '„' + mrn(cstr((filesize(msgfile) - lastk) div 1024) + 'k',8));
end;

procedure updatepointers;
var i:integer;
begin
  tnew := 0;
  for i := 1 to MaxMBases do
    if (cmbase(i) <> 0) then
      begin
        initboard(i);
        if aacs(memboard.acs) and
          ((NewScanMBase) or (mbforceread in memboard.mbstat)) then
          begin
            Lasterror := IOResult;
            reset(msghdrf);
            if (IOResult = 2) then
              rewrite(msghdrf);
            x := FirstNew;
            if (x > 0) then
              newm := filesize(msghdrf) - x + 1
            else
              newm := 0;
            x := FileSize(msghdrf);
            if (tnew + newm > general.maxqwktotal) then
              x := (filesize(msghdrf) - newm) + (general.maxqwktotal - tnew);
            if (newm > general.maxqwkbase) and
               (((filesize(msghdrf) - newm) + general.maxqwkbase) < x) then
              x := (filesize(msghdrf) - newm) + general.maxqwkbase;
            seek(msghdrf, x - 1);
            read(msghdrf, mheader);
            SaveLastRead(mheader.date);
            inc(tnew, x - (filesize(msghdrf) - newm));
            close(msghdrf);
          end;
      end;
end;

begin
  oldconf:=confsystem;
  nl;
  if (thisuser.defarctype < 1) or (thisuser.defarctype > maxarcs) or
    (not general.filearcinfo[thisuser.defarctype].active) then
    begin
      print('Please select an archive type first.'^M^J);
      exit;
    end;

  if (makeqwkfor > 0) or (exist(tempdir + 'QWK\' + general.packetname+'QWK') and
    pynq('Create a new QWK packet for download? ')) then
      purgedir(tempdir + 'QWK\', FALSE)
  else
    purgedir(tempdir + 'QWK\', FALSE);

  OldActivity := update_node(6);

  offlinemail := TRUE;
  if not exist(tempdir + 'QWK\' + general.packetname+'QWK') then begin
    assign(t,tempdir + 'QWK\' + 'CONTROL.DAT');
    rewrite(t);
    writeln(t,general.bbsname);
    writeln(t);
    writeln(t,general.bbsphone);
    writeln(t,general.sysopname,', Sysop');
    writeln(t,'0,'+general.packetname);
    writeln(t,copy(date,1,2)+'-'+copy(date,4,2)+'-'+copy(date,7,4)+','+time);
    writeln(t,thisuser.name);
    writeln(t);
    writeln(t,'0');
    writeln(t,'0');
    availboards:=1;   {email}
    confsystem:=FALSE;
    if oldconf then
      newcomptables;

    for i:=1 to MaxMBases do
      if mbaseac(i) then
        inc(availboards);

    writeln(t,availboards - 1);

    for i := -1 to MaxMBases do
      if (i > 0) and mbaseac(i) then
        begin
          writeln(t, memboard.qwkindex);
          writeln(t,caps(stripcolor(memboard.filename)));
        end
      else
        if (i = -1) then
          begin
            writeln(t,0);
            writeln(t,'Private Mail');
          end;

    writeln(t,'WELCOME');
    writeln(t,'NEWS');
    writeln(t,'GOODBYE');
    close(t);

    if thisuser.scanfilesqwk then
      begin
        assign(newfilesf,tempdir + 'QWK\' + 'NEWFILES.DAT');
        rewrite(newfilesf);
        gnfiles;
        close(newfilesf);
        Lasterror := IOResult;
      end;

    s:=general.qwkwelcome;
    if (okansi) and exist(s+'.ANS') then s:=s+'.ANS'
       else s:=s+'.ASC';
    copyfile(ok,nospace,FALSE,s,tempdir + 'QWK\' + 'WELCOME');

    s:=general.qwknews;
    if (okansi) and exist(s+'.ANS') then s:=s+'.ANS'
       else s:=s+'.ASC';
    copyfile(ok,nospace,FALSE,s,tempdir + 'QWK\' + 'NEWS');

    s:=general.qwkgoodbye;
    if (okansi) and exist(s+'.ANS') then s:=s+'.ANS'
       else s:=s+'.ASC';
    copyfile(ok,nospace,FALSE,s,tempdir + 'QWK\' + 'GOODBYE');

    assign(msgfile,tempdir + 'QWK\' + 'MESSAGES.DAT');
    s:='Produced by Renegade...Copyright (c) 1992-1993 by Cott Lang.  All Rights Reserved';
    while length(s)<128 do s:=s+' ';
    rewrite(msgfile,1);
    blockwrite(msgfile,s[1],128);
    fillchar(qwkheader.crap, sizeof(qwkheader.crap), 0);

    assign(pndxfile,tempdir + 'QWK\' + 'PERSONAL.NDX');
    rewrite(pndxfile);

    lastk:=0;
    tmsg:=0;
    tnew:=0;
    newm:=0;
    yourt:=0;
    TempPause := FALSE;
    abort := FALSE;
    cls;
    print(centre('|The QWKÿSystem is now gathering mail.') + ^M^J);
    printacr('sÚÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄ¿');
    printacr('s³t Num s³u Message base name     s³v  Short  s³w Echo s³x  Total  '+
             's³y New s³z Your s³{ Size s³');
    printacr('sÀÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÙ');

    abort:=FALSE; next:=FALSE;
    fillchar(qwkheader.msgpword,sizeof(qwkheader.msgpword),' ');
    fillchar(qwkheader.rnum,sizeof(qwkheader.rnum),' ');
    qwkheader.status:=225;

    for i:= -1 to MaxMBases do
      begin
        if (IOResult <> 0) then
          begin
            writeln('error processing QWK packet.');
            exit;
          end;
        if (i = 0) or ((i = -1) and (not thisuser.privateqwk)) or
          ((cmbase(i) = 0) and (i >= 0)) then
          continue;

        initboard(i);

        if (i > 0) then
          UseBoardNumber := memboard.qwkindex
        else
          UseBoardNumber := 0;

        if aacs(memboard.acs) and
           ((NewScanMBase) or (mbforceread in memboard.mbstat)) and
           (not abort) then
          begin
            Lasterror := IOResult;
            reset(msghdrf);
            if (IOResult = 2) then
              rewrite(msghdrf);
            reset(msgtxtf,1);
            if (IOResult = 2) then
              rewrite(msgtxtf);
            qwkheader.mbase := UseBoardNumber;
            indexr.conf := UseBoardNumber;
            newm:=0;
            yourm:=0;
            printmain('}'+mrn(cstr(i),4)+'    ~'+mln(memboard.name,22)+'  '+mln(memboard.filename,11)+'€'+
              mln(syn(memboard.mbtype<>0),3) + '' + mrn(cstr(filesize(msghdrf)),8));
            update_display;

            if (UseBoardNumber > 0) then
              cn := FirstNew
            else
              cn := 1;

            if (cn > 0) then begin

              s := cstr(UseBoardNumber);
              while (length(s) < 3) do
                s := '0' + s;

              assign(ndxfile,tempdir + 'QWK\' + s + '.NDX');
              rewrite(ndxfile);

              wkey;

              while (cn <= filesize(msghdrf)) and (not abort) and
                    (newm < general.maxqwkbase) and
                    (tnew + newm < general.maxqwktotal) and
                    (not hangup) do begin
                 if (i >= 0) then
                   inc(newm);
                 wkey;
                 if (timer-lastupdate>3) or (timer-lastupdate<0) then begin
                    BackErase(22);
                    update_display;
                 end;
                 seek(msghdrf, cn - 1);
                 read(msghdrf, mheader);
                 if not (mdeleted in mheader.status) and
                    not (unvalidated in mheader.status) and
                    not (FromYou(Mheader) and not thisuser.getownqwk) and
                    not ((Prvt in mheader.status) and not (FromYou(Mheader) or ToYou(Mheader))) and
                    not ((i = -1) and not (ToYou(Mheader)))
                    then begin

                   if (i = -1) then
                     inc(newm);
                   if (Prvt in mheader.status) then
                     qwkheader.flag := '*'
                   else
                     qwkheader.flag:=' ';

                   s:=cstr(cn);

                   fillchar(qwkheader.num[1],sizeof(qwkheader.num),' ');
                   move(s[1],qwkheader.num[1],length(s));

                   packtodate(dt4,mheader.date);

                   if mheader.from.anon=0 then
                     s:=Zeropad(cstr(dt4.month))+'-'+Zeropad(cstr(dt4.day))+'-'+copy(cstr(dt4.year),3,2)
                   else
                     s:='';

                   fillchar(qwkheader.msgdate[1],sizeof(qwkheader.msgdate),' ');
                   move(s[1],qwkheader.msgdate[1],length(s));

                   if mheader.from.anon=0 then
                     s:=Zeropad(cstr(dt4.hour))+':'+Zeropad(cstr(dt4.min))
                   else
                     s:='';

                   fillchar(qwkheader.msgtime,sizeof(qwkheader.msgtime),' ');
                   move(s[1],qwkheader.msgtime[1],length(s));

                   s:=mheader.mto.as;
                   if (mbrealname in memboard.mbstat) then
                     s:=allcaps(mheader.mto.real);
                   s:=caps(Usename(mheader.mto.anon,s));

                   fillchar(qwkheader.msgto,sizeof(qwkheader.msgto),' ');
                   move(s[1],qwkheader.msgto[1],length(s));

                   s:=mheader.from.as;
                   if (mbrealname in memboard.mbstat) then
                     s:=allcaps(mheader.from.real);
                   s:=caps(Usename(mheader.from.anon,s));

                   fillchar(qwkheader.msgfrom[1],sizeof(qwkheader.msgfrom),' ');
                   move(s[1],qwkheader.msgfrom[1],length(s));

                   fillchar(qwkheader.msgsubj[1],sizeof(qwkheader.msgsubj),' ');

                   if (mheader.fileattached > 0) then
                     mheader.subject := stripname(mheader.subject);

                   move(mheader.subject[1],qwkheader.msgsubj[1],length(mheader.subject));

                   marker:=filepos(msgfile);

                   blockwrite(msgfile,qwkheader,128);

                   real_to_msb(filesize(msgfile) div 128, indexr.pointer);
                   write(ndxfile,indexr);

                   if ToYou(mheader) then
                     begin
                       write(pndxfile,indexr);
                       inc(yourm);
                     end;

                   x:=1;
                   totload:=0;
                   texts:='';

                   if (mheader.pointer-1<filesize(msgtxtf)) and
                      (mheader.pointer-1+mheader.textsize<=filesize(msgtxtf)) then begin
                         seek(msgtxtf, mheader.pointer-1);
                         repeat
                           blockread(msgtxtf, s[0], 1);
                           blockread(msgtxtf, s[1], byte(s[0]));
                           inc(totload, length(s)+1);
                           { USED to stripcolor() here, but that fucks up uuencodes }
                           s:=s+'ã';
                           texts:=texts+s;
                           if (length(texts) > 128) then
                             begin
                               blockwrite(msgfile, Texts[1], 128);
                               inc(x);
                               move(Texts[129], Texts[1], Length(Texts) - 128);
                               dec(Texts[0], 128);
                             end;
                         until (totload>=mheader.textsize);
                         if (texts <> '') then
                           begin
                             if (length(texts) < 128) then
                               begin
                                 fillchar(Texts[length(Texts) + 1], 128 - length(Texts), 32);
                                 Texts[0] := #128;
                               end;

                             blockwrite(msgfile, texts[1], 128);
                             inc(x);
                           end;
                   end else begin
                     mheader.status:=mheader.status+[mdeleted];
                     mheader.textsize:=0;
                     mheader.pointer:=1;
                     seek(msghdrf, cn - 1);   { inline for speed }
                     write(msghdrf, mheader);
                   end;

                   s:=cstr(x);

                   fillchar(qwkheader.numblocks[1],sizeof(qwkheader.numblocks),' ');
                   move(s[1],qwkheader.numblocks[1],length(s));

                   seek(msgfile,marker);
                   blockwrite(msgfile,qwkheader,128);
                   seek(msgfile,filesize(msgfile));
                 end;
                 inc(cn);
              end;
              close(ndxfile);
            end;
          BackErase(22);
          update_display; nl;
          if (newm >= general.maxqwkbase) then
            print('Maximum number of messages per base reached.');
          if ((tnew + newm) >= general.maxqwktotal) then
            print('Maximum number of messages per QWK packet reached.');
          lastk:=filesize(msgfile);
          inc(tnew,newm);
          inc(yourt,yourm);
          inc(tmsg,filesize(msghdrf));
          close(msghdrf); close(msgtxtf);
        end;
        if ((tnew + newm) >= general.maxqwktotal) or abort then
          break;
      end;

    if filesize(pndxfile)=0 then begin
      close(pndxfile);
      erase(pndxfile);
    end else close(pndxfile);

    nl;

    if not abort then print('^0     Totals:'+mrn(cstr(tmsg),43)+mrn(cstr(tnew),7)+mrn(cstr(yourt),6)+
        mrn(cstr(filesize(msgfile) div 1024)+'k',8));

    close(msgfile);
    nl;

    initboard(board);

    lil := 0;
    if (tnew<1) or (abort) then begin
       if tnew<1 then print('No new messages!');
       update_node(OldActivity);
       offlinemail := FALSE;
       confsystem:=oldconf;
       if oldconf then
         newcomptables;
       exit;
    end;
    if (makeqwkfor = 0) then
      begin
        dyny := TRUE;
        if not pynq('Proceed to packet compression? ') then
          begin
            update_node(OldActivity);
            offlinemail := FALSE;
            confsystem:=oldconf;
            if oldconf then
              newcomptables;
            exit;
          end;
      end;

    nl;
    star('Compressing '+general.packetname+'.QWK');

    arccomp(ok,thisuser.defarctype,tempdir + 'QWK\' + general.packetname+'.QWK',tempdir + 'QWK\*.*');

    if (not ok) or (not exist(tempdir + 'QWK\' + general.packetname+'.QWK')) then
      begin
        print(^M^J'error archiving QWK packet!');
        update_node(OldActivity);
        offlinemail := FALSE;
        confsystem:=oldconf;
        if oldconf then
          newcomptables;
        exit;
      end;

    sysoplog('QWK packet created.');
  end;

  findfirst(tempdir + 'QWK\' + general.packetname+'.QWK',anyfile,dirinfo);
  if incom and (nsl< dirinfo.size div rate) and not general.qwktimeignore then
    begin
      print(^M^J'Sorry, not enough time left to transfer.'^M^J);
      update_node(OldActivity);
      offlinemail := FALSE;
      confsystem:=oldconf;
      if oldconf then
        newcomptables;
      exit;
    end;
  star('Compressed packet size is '+cstr(dirinfo.size div 1024)+'k');
  if incom and not hangup then
    begin
      availboards:=fileboard;
      fileboard:=-1;
      send(tempdir + 'QWK\' + general.packetname+'.QWK',FALSE,FALSE,dok,kabort,false,tooktime);
      fileboard:=availboards;
      if dok and (not kabort) then
        begin
          star('Packet transferred');
          sysoplog('Downloaded QWK packet.');
          star('Updating message pointers');

          updatepointers;

          star('Message pointers updated');
          if thisuser.privateqwk then
            begin
              kill_email;
              star('Private Mail killed.');
            end;
        end;
    end
  else
    begin
      s := general.qwklocalpath+general.packetname;
      if exist(s + '.QWK') and ((makeqwkfor > 0) or not (pynq(^M^J'Replace existing .QWK? '))) then
        for Junk := 'A' to 'Z' do
          if not (exist(s + '.QW' + Junk)) then
            begin
              s := s + '.QW' + Junk;
              break;
            end;
      if (pos('.', s) = 0) then
        s := s + '.QWK';
      copyfile(ok,nospace,FALSE,tempdir + 'QWK\' + general.packetname+'.QWK',s);
      nl;
      updatepointers;
      if thisuser.privateqwk then
        kill_email;
    end;
  if exist(tempdir + 'QWK\' + general.packetname+'.REP') then
    begin
      nl;
      star('Bidirectional upload of '+general.packetname+'.REP detected');
      UploadPacket(True);
    end;
  update_node(OldActivity);
  offlinemail := FALSE;
  confsystem:=oldconf;
  if oldconf then
    newcomptables;
  Lasterror := IOResult;
end;


procedure uploadpacket(Already:boolean);
var ok,dok,kabort,addbatch:boolean;
    f:file;
    s,os:string;
    qwkheader:qwkheaderec;
    i,x,blocks:word;
    oldboard:integer;
    OldActivity,bt:byte;
    mheader:mheaderrec;
    tooktime:longint;
    oldconf:boolean;
    tempdate:longint;
    u:userrec;

    function findbase(indexnumber:word): word;
    var
      j,k:integer;
    begin
      reset(MBasesFile);
      j := 0;
      k := 0;
      while (j = 0) and not (eof(MBasesFile)) do
        begin
          inc(k);
          read(MBasesFile, memboard);
          if (memboard.qwkindex = indexnumber) then
            j := k;
        end;
      close(MBasesFile);
      findbase := k;
    end;

begin
  if (rpost in thisuser.flags) then
    begin
      print(^M^J'You are restricted from posting messages.'^M^J);
      exit;
    end;
  dok := TRUE;
  kabort := FALSE;
  oldconf:=confsystem;
  confsystem:=FALSE;
  if (oldconf) then
    newcomptables;

  OldActivity := update_node(6);
  purgedir(tempdir + 'UP\', FALSE);

  TimeLock := TRUE;
  OldBoard := readboard;

  if (Speed = 0) or (upqwkfor > 0) then
    copyfile(dok,kabort,FALSE,general.qwklocalpath+general.packetname+'.REP',tempdir + 'QWK\' + general.packetname+'.REP')
  else
    begin
      if not Already then
        receive(general.packetname+'.REP',tempdir + '\QWK',FALSE,dok,kabort,addbatch,tooktime)
      else
        movefile(dok, kabort, false, tempdir+'UP\'+general.packetname+'.REP',
               tempdir+'QWK\'+general.packetname+'.REP');
   end;

  TimeLock := FALSE;

  if (dok) and (not kabort) then begin
     sysoplog('Uploaded REP packet');
     if not Already then
       print('Transfer successful');

     execbatch(ok,tempdir + 'QWK\' ,general.arcspath+
            FunctionalMCI(general.filearcinfo[thisuser.defarctype].unarcline,
            tempdir + 'QWK\' +general.packetname+'.REP',
            general.packetname+'.MSG'),
            general.filearcinfo[thisuser.defarctype].succlevel,bt,FALSE);

     if (ok) and exist(tempdir + 'QWK\' +general.packetname+'.MSG') then begin
        assign(f,tempdir + 'QWK\' +general.packetname+'.MSG');
        reset(f,1);
        getftime(f,tempdate);

        if (tempdate = thisuser.lastqwk) then
          begin
            print(^M^J'This packet has already been uploaded here.'^M^J);
            close(f);
            TimeLock := FALSE;
            exit;
          end;

        thisuser.lastqwk := tempdate;

        mheader.fileattached := 0;
        mheader.mto.usernum:=0;
        mheader.mto.anon:=0;
        mheader.replyto:=0;
        mheader.replies:=0;

        tempdate := getpackdatetime;

        blockread(f,s,128);
        while not eof(f) do begin
          if (IOResult <> 0) then
            begin
              writeln('error processing REP packet.');
              break;
            end;
          blockread(f,qwkheader,128);

          s[0] := #6;
          move(qwkheader.numblocks[1], s[1], 6);

          blocks := value(s) - 1;

          if (qwkheader.mbase = 0) then
            board := -1
          else
            board := findbase(qwkheader.mbase);

          initboard(board);

          if aacs(memboard.acs) and aacs(memboard.postacs) and not
           ((ptoday>=general.maxpubpost) and (not MsgSysOp)) then
          begin
             Lasterror := IOResult;
             reset(msghdrf);
             if (IOResult = 2) then
               rewrite(msghdrf);
             reset(msgtxtf,1);
             if (IOResult = 2) then
               rewrite(msgtxtf);

             if aacs(general.qwknetworkacs) then
               begin
                 s[0] := #25;
                 move(qwkheader.msgfrom[1],s[1],sizeof(qwkheader.msgfrom));
                 while s[length(s)] =' ' do
                   dec(s[0]);
                 mheader.from.usernum := 0;
               end
             else
               begin
                 if (mbrealname in memboard.mbstat) then
                   s := thisuser.realname
                 else
                   s := thisuser.name;
                 mheader.from.usernum:=usernum;
               end;

             mheader.from.as:=s;
             mheader.from.real:=s;
             mheader.from.name:=s;
             mheader.from.anon:=0;

             s[0] := #25;
             move(qwkheader.msgto[1],s[1],sizeof(qwkheader.msgto));
             while s[length(s)] =' ' do
               dec(s[0]);

             mheader.mto.as:=s;
             mheader.mto.real:=s;
             mheader.mto.name:=s;
             mheader.mto.usernum := searchuser(mheader.mto.name, FALSE);

             mheader.pointer:=filesize(msgtxtf)+1;
             mheader.date := tempdate;
             inc(tempdate);     { make sure all messages have unique date }
             getdayofweek(mheader.dayofweek);

             mheader.status:=[];

             if (qwkheader.flag in ['*','+']) and
                (mbprivate in memboard.mbstat) then
                mheader.status := mheader.status + [Prvt];

             if (rvalidate in thisuser.flags) then
               mheader.status := mheader.status + [unvalidated];
             if (aacs(memboard.mciacs)) then
                 mheader.status := mheader.status + [allowmci];

             move(qwkheader.msgsubj[1],s[1],sizeof(qwkheader.msgsubj));
             s[0] := chr(sizeof(qwkheader.msgsubj));

             while (s[length(s)] = ' ') do
               dec(s[0]);

             mheader.subject:=s;

             mheader.origindate[0] := #14;
             move(qwkheader.msgdate[1],mheader.origindate[1],8);
             mheader.origindate[9] := #32;
             move(qwkheader.msgtime[1],mheader.origindate[10],5);

             mheader.textsize:=0;

             if allcaps(mheader.mto.as)<>'QMAIL' then begin
                seek(msgtxtf,filesize(msgtxtf));
                os:='';

                x := 1;
                while (x <= blocks) and (IOResult = 0) do
                  begin
                    blockread(f,s[1],128);
                    s[0]:=#128;
                    s:=os+s;
                    while pos('ã',s)>0 do begin
                      os:=copy(s,1,pos('ã',s)-1);
                      s:=copy(s,pos('ã',s)+1,length(s));
                      if (memboard.mbtype<>0) and (copy(os,1,4)='--- ') then os:=''
                         else begin
                          if (lennmci(os) > 78) then
                            os := copy(os,1, 78 + length(os) - lennmci(os));
                          inc(mheader.textsize,length(os)+1);
                          blockwrite(msgtxtf,os,length(os)+1);
                      end;
                    end;
                    os:=s;
                    inc(x);
                  end;

                while s[length(s)] = ' ' do
                  dec(s[0]);

                if length(s)>0 then begin
                   inc(mheader.textsize,length(s)+1);
                   blockwrite(msgtxtf,s,length(s)+1);
                end;
                if memboard.mbtype<>0 then
                  begin
                    newechomail:=TRUE;
                    if not (mbscanout in memboard.mbstat) then
                      UpdateBoard;
                  end;
                if (memboard.mbtype<>0) and (mbaddtear in memboard.mbstat) then
                  with memboard do begin
                   s:=decode(';h•µlÚ?¦kÐðf', 183)+ver;
                   inc(mheader.textsize,length(s)+1);
                   blockwrite(msgtxtf,s,length(s)+1);
                  if (memboard.origin <> '') then
                    s := memboard.origin
                  else
                    s := General.origin;
                   s:=' * Origin: '+ s + ' (';
                   if (aka > 19) then
                     aka := 0;
                    s := s + cstr(General.aka[aka].zone) + ':' +
                             cstr(General.aka[aka].net)  + '/' +
                             cstr(General.aka[aka].node);
                    if (General.aka[aka].point > 0) then
                      s := s + '.' + cstr(General.aka[aka].point);
                    s := s + ')';
                   inc(mheader.textsize,length(s)+1);
                   blockwrite(msgtxtf,s,length(s)+1);
                end;

                cls;
                ok:=FALSE; dok:=FALSE;

                seek(msghdrf,filesize(msghdrf));
                write(msghdrf,mheader);

                if (upqwkfor <= 0) then
                  anonymous(TRUE,mheader);

                if (board = -1) then
                  begin
                    if (mheader.mto.usernum = 0) then
                      begin
                        if (aacs(general.netmailacs)) and
                           (pynq(^M^J'Is this to be a netmail message? ')) then
                          begin
                            if (general.allowalias) and pynq('Send this with your real name? ') then
                              mheader.from.as := thisuser.realname;
                            with mheader.mto do
                              GetNetAddress(name, Zone,Net,Node,Point,x, FALSE);
                            if (mheader.mto.name = '') then
                              mheader.status := mheader.status + [mdeleted]
                            else
                              begin
                                inc(thisuser.debit,x);
                                mheader.status := mheader.status + [netmail];
                                mheader.netattribute := General.netattribute *
                                  [intransit,private,crash,killsent,hold,local];

                                ChangeFlags(mheader);
                                x := 0;
                                i := 0;
                                while (i <= 9) and (x = 0) do
                                  begin
                                    if (General.aka[i].zone = mheader.mto.zone) and
                                       (General.aka[i].zone <> 0) then
                                       x := i;
                                    inc(i);
                                  end;
                                mheader.from.zone:=General.aka[x].zone;
                                mheader.from.net:=General.aka[x].net;
                                mheader.from.node:=General.aka[x].node;
                                mheader.from.point:=General.aka[x].point;
                              end;
                          end
                        else
                          mheader.status := mheader.status + [mdeleted]
                      end
                    else
                      begin
                        if (mheader.mto.usernum > 1) then
                          begin
                            inc(thisuser.emailsent);
                            inc(etoday);
                          end
                        else
                          begin
                            inc(thisuser.feedback);
                            inc(ftoday);
                          end;

                        loadurec(u,mheader.mto.usernum);
                        inc(u.waiting);
                        saveurec(u,mheader.mto.usernum);
                      end;
                  end
                else
                  begin
                    inc(thisuser.msgpost);
                    inc(ptoday);
                    AdjustBalance(General.CreditPost);
                  end;

                seek(msghdrf,filesize(msghdrf)-1);
                write(msghdrf,mheader);

             end else
               begin
                 if mheader.subject='DROP' then
                   begin
                     if not ToggleNewScan then
                       next := ToggleNewScan;
                   end
                    else if mheader.subject='ADD' then
                      begin
                        if ToggleNewScan then
                          next := ToggleNewScan;
                      end;
                 seek(f, filepos(f) + (blocks * 128));
               end;
             close(msghdrf); close(msgtxtf);
          end
          else seek(f, filepos(f) + (blocks * 128));
        end;
        close(f);
     end else print('Unable to decompress REP packet.');
  end else print('Transfer unsuccessful');

  if exist(general.qwklocalpath+general.packetname+'.REP') and (Speed = 0)
     and (upqwkfor = 0) and pynq(^M^J'Delete REP packet? ') then
     kill(general.qwklocalpath+general.packetname+'.REP');

  purgedir(tempdir + 'QWK\', FALSE);
  TimeLock := FALSE;

  update_screen;
  update_node (OldActivity);
  if (oldconf) then
    begin
      confsystem := oldconf;
      newcomptables;
    end;
  initboard(OldBoard);
  Lasterror := IOResult;
end;

end.
