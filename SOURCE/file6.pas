{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit file6;

interface

uses crt, dos, overlay, common, timefunc, multnode;

procedure delbatch(n:integer);
function okprot(prot:protrec; ul,dl,batch,resume:boolean):boolean;
procedure showprots(ul,dl,batch,resume:boolean);
function findprot(c:char; ul,dl,batch,resume:boolean):integer;
function GetProts(ul,dl,batch,resume:boolean):string;
procedure batchdl;
procedure listbatchfiles;
procedure removebatchfiles;
procedure clearbatch;

implementation

uses execbat, file0, file1, file2, file9, file12, ShortMsg;

procedure delbatch(n:integer);
var c:integer;
begin
  if (n > 0) and (n <= numbatchfiles) then
    begin
      batchtime := batchtime - BatchDLQueue[n]^.Time;

      if (BatchDLQueue[n]^.Storage = Copied) then
        kill(BatchDLQueue[n]^.FileName);

      if (n <> numbatchfiles) then
        for c := n to numbatchfiles - 1 do
          BatchDLQueue[c]^ := BatchDLQueue[c + 1]^;
      dispose (BatchDLQueue[numbatchfiles]);
      dec(numbatchfiles);
    end;
end;

function okprot(prot:protrec; ul,dl,batch,resume:boolean):boolean;
var s:astr;
begin
  okprot:=FALSE;
  with prot do begin
    if (ul) then s:=ulcmd else if (dl) then s:=dlcmd else s:='';
    if (s='NEXT') and ((ul) or (batch) or (resume)) then exit;
    if (s='ASCII') and ((ul) or (batch) or (resume)) then exit;
    if (s='BATCH') and ((batch) or (resume))
       and not (write_msg) then exit;
    if (batch<>(xbisbatch in xbstat)) then exit;
    if (resume<>(xbisresume in xbstat)) then exit;
    if (xbreliable in xbstat) and (not Reliable) then exit;
    if (not (xbactive in xbstat)) then exit;
    if (not aacs(acs)) then exit;
    if (s='') then exit;
  end;
  okprot:=TRUE;
end;

function GetProts(ul, dl, batch, resume:boolean):string;
var
  i:integer;
  Junk:astr;
begin
  seek(xf, 0);
  junk := '';
  for i := 1 to filesize(xf) do
    begin
      read(xf, Protocol);
      if (okprot(Protocol, ul, dl, batch, resume) { or
         (Protocol.ulcmd = 'QUIT') or (Protocol.ulcmd = 'EDIT') or
         (Protocol.ulcmd = 'BATCH') or (Protocol.ulcmd = 'NEXT') } ) then
        if (Protocol.ckeys = 'ENTER') then
          Junk := Junk + ^M
        else
          Junk := Junk + Protocol.ckeys[1];
    end;
  GetProts := Junk;
end;

procedure showprots(ul, dl, batch, resume:boolean);
var
  i:integer;
begin
  nofile:=TRUE;
  if (resume) then
    printf('protres')
  else
    begin
      if (batch) then
        if (ul) then
          printf('protbul')
        else
          printf('protbdl')
      else
        if (ul) then
          printf('protsul')
        else
          printf('protsdl');
    end;
  if (nofile) then
    begin
      seek(xf, 0);
      nl;
      for i := 1 to filesize(xf) do
        begin
          read(xf, Protocol);
          if (okprot(Protocol, ul, dl, batch, resume) and
            (Protocol.ulcmd <> 'QUIT') and (Protocol.ulcmd <> 'BATCH') and
            (Protocol.ulcmd <> 'EDIT') and (Protocol.ulcmd <> 'NEXT')) then
            prompt(Protocol.Descr + ' ');
        end;
      nl;
    end;
end;

function findprot(c:char; ul,dl,batch,resume:boolean):integer;
var s:astr;
    i:integer;
    done:boolean;
begin
  findprot:=-99;
  seek(xf,0);
  done:=FALSE; i:=0;
  while ((i<=filesize(xf)-1) and (not done)) do begin
    read(xf,protocol);
    with protocol do
      if (c = ckeys[1]) or ((c = ^M) and (ckeys = 'ENTER')) then
        if (okprot(protocol,ul,dl,batch,resume)) then
          begin
            if (ul) then
              s:=ulcmd
            else
              if (dl) then
                s:=dlcmd
              else
                s:='';

            if (s='ASCII') then begin done:=TRUE; findprot:=-1; end
            else
              if (s='QUIT') then begin done:=TRUE; findprot:=-2; end
            else
              if (s='NEXT') then begin done:=TRUE; findprot:=-3; end
            else
              if (s='BATCH') then begin done:=TRUE; findprot:=-4; end
            else
              if (s='EDIT') then begin done:=TRUE; findprot:=-5; end
            else
              if (s<>'') then begin done:=TRUE; findprot:=i; end;
          end;
    inc(i);
  end;
end;

procedure batchdl;
var batfile,tfil:text;  {@4 file list file}
    nfn,s:astr;
    TransferTime:longint;
    TSize,TSize1,cps:longint;
    f:ulfrec;
    oldboard,rn,tpts,tpts1,tnfils,tnfils1,n,p,toxfer:integer;
    OldActivity, i:byte;
    c:char;
    v:verbrec;
    Descriptions,AutoLogoff,swap,done1,dok,readlog,tofile:boolean;
    u:userrec;

  procedure addnacc(i:integer; s:astr);
  begin
    if (i <> -1) then
      begin
        oldboard:=fileboard; fileboard:=i;
        s:=sqoutsp(stripname(s));
        recno(s,rn);
        if (rn <> -1) then
          begin
            seek(DirFile,rn); read(DirFile,f);
            inc(f.downloaded);
            seek(DirFile,rn); write(DirFile,f);
          end;
        fileboard:=oldboard;
        close(DirFile);
      end;
    Lasterror := IOResult;
  end;

  procedure chopoffspace(var s:astr);
  begin
    while s[1]=' ' do s:=copy(s,2,length(s)-1);
    if (pos(' ',s)<>0) then s:=copy(s,1,pos(' ',s)-1);
  end;

  procedure figuresucc;
  var filestr,statstr:astr;
      foundit:boolean;

    function wasok:boolean;
    var i:integer;
        foundcode:boolean;
    begin
      foundcode:=FALSE;
      wasok:=FALSE;
      for i:=1 to 6 do
        if (protocol.dlcode[i]<>'') and
           (protocol.dlcode[i]=copy(statstr,1,length(protocol.dlcode[i]))) then
          foundcode:=TRUE;
      if ((foundcode) and (not (xbxferokcode in protocol.xbstat))) then exit;
      if ((not foundcode) and (xbxferokcode in protocol.xbstat)) then exit;
      wasok:=TRUE;
    end;

  begin
    readlog:=FALSE;
    tofile:=TRUE;

    if (protocol.templog <> '') then begin
      sysoplog('');
      assign(batfile,FunctionalMCI(protocol.templog,'',''));
      reset(batfile);

      if (ioresult=0) then begin
        readlog:=TRUE;
        if (FunctionalMCI(protocol.dloadlog,'','') = '') then
          tofile:=FALSE
        else
          begin
            assign(tfil,FunctionalMCI(protocol.dloadlog,'',''));
            append(tfil);
            if (ioresult = 2) then
              rewrite(tfil);
          end;
        while (not eof(batfile)) do begin
          readln(batfile,s);
          if tofile then writeln(tfil,s);
          filestr:=copy(s,protocol.logpf,length(s)-(protocol.logpf-1));
          statstr:=copy(s,protocol.logps,length(s)-(protocol.logps-1));
          chopoffspace(filestr);
          foundit:=FALSE; n:=0;
          while ((n<numbatchfiles) and (not foundit)) do
            begin
              inc(n);
              if (allcaps(BatchDLQueue[n]^.FileName) = allcaps(filestr)) then
                foundit:=TRUE;
            end;
          if (foundit) then begin
            if (wasok) then begin
              sysoplog('^5Batch downloaded '+stripname(BatchDLQueue[n]^.FileName));
              if general.rewardsystem then
                 if (BatchDLQueue[n]^.Uploader > 0) and
                    (BatchDLQueue[n]^.Uploader <= MaxUsers) then
                    begin
                      loadurec(u,BatchDLQueue[n]^.Uploader);
                      i := trunc(BatchDLQueue[n]^.Points * general.rewardratio / 100);
                      if (BatchDLQueue[n]^.OwnerCRC = CRC32(U.Name)) and (i > 0)
                         and (BatchDLQueue[n]^.Uploader <> usernum) then begin
                        sysoplog('Awarded '+cstr(i) + ' credit' + Plural(i) + ' to '+caps(u.name));
                        if (i > 0) then
                          inc(u.credit, i)
                        else
                          inc(u.debit, i);
                        saveurec(u,BatchDLQueue[n]^.Uploader);
                        ssm(BatchDLQueue[n]^.Uploader,'You received ' + cstr(i) +
                              ' credit'+Plural(i)+' for the download of '+stripname(BatchDLQueue[n]^.FileName));
                      end;
                   end;
              inc(tnfils);
              inc(TSize, BatchDLQueue[n]^.Size);
              inc(tpts, BatchDLQueue[n]^.Points);
              loadfileboard(BatchDLQueue[n]^.section);
              if (not (fbnoratio in memuboard.fbstat)) then begin
                inc(tnfils1);
                inc(TSize1, BatchDLQueue[n]^.Size);
                inc(tpts1, BatchDLQueue[n]^.Points);
              end;
              addnacc(BatchDLQueue[n]^.section,BatchDLQueue[n]^.FileName);
              delbatch(n);
            end else
              sysoplog('^7Tried batch download '+stripname(BatchDLQueue[n]^.FileName));
          end;
        end;
        close(batfile);
        if tofile then close(tfil);
      end;
    end;
    if (not readlog) then begin
      while (toxfer>0) do begin
        sysoplog('^5Batch downloaded '+stripname(BatchDLQueue[1]^.FileName));
        inc(tnfils);
        inc(TSize,BatchDLQueue[1]^.Size);
        inc(tpts,BatchDLQueue[1]^.Points);
        loadfileboard(BatchDLQueue[1]^.section);
        if (not (fbnoratio in memuboard.fbstat)) then begin
          inc(tnfils1);
          inc(TSize1,BatchDLQueue[1]^.Size);
          inc(tpts1,BatchDLQueue[1]^.Points);
        end;
        addnacc(BatchDLQueue[1]^.section,BatchDLQueue[1]^.FileName);
        delbatch(1); dec(toxfer);
      end;
    end;
  end;

  procedure editbatch;
  begin
    repeat
      prt(^M^J'Batch queue [^5L^4]ist batch, [^5R^4]emove a file, [^5C^4]lear, [^5Q^4]uit : ');
      onek(c,'QRCL');
      case c of
        'R':removebatchfiles;
        'C':clearbatch;
        'L':listbatchfiles;
      end;
    until (hangup) or (C='Q');
  end;

begin
  if (numbatchfiles = 0) then
    print(^M^J'^1Batch queue empty.')
  else begin
    print(^M^J'^1Checking batch download request...');

    tpts:=0; tsize := 0;
    for n:=1 to numbatchfiles do
      begin
        tpts := tpts + BatchDLQueue[n]^.Points;
        tsize := tsize + BatchDLQueue[n]^.Size;
      end;

    print(^M^J'Number files in batch: ^5' + cstr(numbatchfiles));
    print('^1Total batch file size: ^5' + cstr(tsize div 1024) + 'k');
    print('^1Batch download time  : ^5' + ctim(Batchtime));
    print('^1Time left online     : ^5' + ctim(nsl));
    if (tpts > 0) then
      begin
        print('^1Credits required     : ^5' + cstr(tpts));
        print('^1Your credits         : ^5' + cstr(AccountBalance));
      end;

    if (tpts > AccountBalance) and not (fnocredits in thisuser.flags)
       and not (aacs(general.nofilecredits)) and (general.filecreditratio) then begin
      print(^M^J'Insufficient credits for download.');
      exit;
    end;

    if (Batchtime > nsl) then
      begin
        print(^M^J'Insufficient time for download.');
        print('Remove some files from your batch queue.'^M^J);
        editbatch;
        exit;
      end;

    reset(xf);
    done1:=FALSE;
    repeat
      showprots(FALSE, TRUE, TRUE, FALSE);
      s := GetProts(FALSE, TRUE, TRUE, FALSE);
      prompt(fstring.protocolp); onek(c, s);
      p := findprot(c, FALSE, TRUE, TRUE, FALSE);
      if (p = -99) then
        print('Invalid entry.')
      else if (p = -5) then
        begin
          editbatch;
          if (numbatchfiles = 0) then
            exit;
        end
      else
        done1 := TRUE;
    until (done1) or (hangup);
    nl;
    if (p <> -2) and not hangup then begin
      seek(xf,p); read(xf,protocol); close(xf);

      autologoff := pynq('Autologoff after file transfer? ');
      dok:=TRUE;
      TSize:=0; tpts:=0; tnfils:=0;
      TSize1:=0; tpts1:=0; tnfils1:=0;
      nl;

      if pynq('Download file descriptions? ') then
        begin
          oldboard := fileboard;
          Descriptions := TRUE;
          inc(numbatchfiles);
          new(BatchDLQueue[numbatchfiles]);
          BatchDLQueue[numbatchfiles]^.FileName:=TempDir + 'ARC\FILES.BBS';
          BatchDLQueue[numbatchfiles]^.Time:=0;
          BatchDLQueue[numbatchfiles]^.Storage := Disk;
          assign(batfile, TempDir + 'ARC\FILES.BBS');
          rewrite(batfile);
          for n := 1 to numbatchfiles - 1 do
           if (BatchDLQueue[n]^.section > -1) then
            begin
              fileboard := BatchDLQueue[n]^.section;
              s:=stripname(BatchDLQueue[n]^.FileName);
              recno(s,rn);
              if (rn <> -1) then
                begin
                  seek(DirFile,rn); read(DirFile,f);
                  writeln(batfile,mln(align(stripname(BatchDLQueue[n]^.FileName)),14) + f.description);
                  if (f.vpointer > -1) then
                    begin
                      reset(verbf);
                      seek(verbf,f.vpointer); read(verbf,v);
                      for i := 1 to MAXEXTDESC do
                        if (v.descr[i] <> '') then
                          writeln(batfile, mln('',14) + v.descr[i]);
                      close(verbf);
                      Lasterror := IOResult;
                    end;
                end;
              close(DirFile);
              Lasterror := IOResult;
            end;
          fileboard := oldboard;
          close(batfile);
          Lasterror := IOResult;
        end
      else
        Descriptions := FALSE;

      nl;

      n := 1;  Done1 := FALSE;
      while (n <= NumBatchFiles) and (not Done1) do
        begin
          Done1 := (BatchDLQueue[n]^.Storage = CD);
          inc(n);
        end;

      if (Done1) then
        begin
          print('Please wait, copying files from CD-ROM ...');
          for n := 1 to numbatchfiles do
            if (BatchDLQueue[n]^.Storage = CD) then
              begin
                copyfile(dok, done1, FALSE, BatchDLQueue[n]^.FileName,
                         TempDir + 'CD\' + StripName(BatchDLQueue[n]^.FileName));
                if (dok) and not Done1 then
                  begin
                    BatchDLQueue[n]^.Storage := Copied;
                    BatchDLQueue[n]^.FileName := TempDir + 'CD\' +
                      StripName(BatchDLQueue[n]^.FileName);
                  end;
                if Done1 then
                  begin
                    print(^M^J'Insufficient space.');
                    break;
                  end;
              end;
        end;

      nfn:=general.protpath + FunctionalMCI(protocol.dlcmd,'','');
      toxfer:=0;
      if (pos('%F',protocol.dlcmd)<>0) then begin
        done1:=FALSE;
        while ((not done1) and (toxfer<numbatchfiles)) do begin
          inc(toxfer);
          nfn := FunctionalMCI(nfn, BatchDLQueue[ToXfer]^.FileName, '');
          if (length(nfn) > protocol.maxchrs) then
            done1:=TRUE;
        end;
      end;

      if (protocol.dlflist<>'') then begin
        assign(batfile,FunctionalMCI(protocol.dlflist,'',''));
        rewrite(batfile);
        for n := 1 to numbatchfiles do
          begin
            writeln(batfile,BatchDLQueue[n]^.FileName);
            inc(toxfer);
          end;
        close(batfile);
        Lasterror := IOResult;
      end;

      kill(FunctionalMCI(protocol.templog,'',''));

      purgedir(tempdir + 'UP\', FALSE);

      if (useron) then
        print('Initiating batch transfer.');

      OldActivity := update_node(1);

      swap:=general.swapshell;
      general.swapshell:=FALSE;

      TransferTime := getpackdatetime;

      if (Speed > 0) then
        execwindow(dok,tempdir + 'UP\',FunctionalMCI(protocol.envcmd,'','')+#13#10+nfn,-1,i);

      general.swapshell:=swap;

      TransferTime := getpackdatetime - TransferTime;

      if (protocol.dlflist<>'') then
        kill(FunctionalMCI(protocol.dlflist,'',''));

      update_node(OldActivity);

      if Descriptions then
        begin
          delbatch(numbatchfiles);
          kill(TempDir + 'ARC\FILES.BBS');
        end;

      figuresucc;

      lil := 0;

      if (TransferTime > 0) then
        cps := TSize div TransferTime
      else
        cps:=0;

      nl;

      check_status;

      s:='Download totals : ^5' + cstr(tnfils) + ' file' + Plural(tnfils) + ', '+cstr(TSize)+' bytes';
      if (tpts <> 0) then
        s := s+', '+cstr(tpts)+' file point' + Plural(tpts);
      s := s+'.';
      star(s);

      sysoplog('Transfer: '+cstr(tnfils)+' file' + Plural(tnfils) + ', '+cstr(TSize)+
         ' bytes, '+cstr(cps)+ ' cps.');

      if (tnfils1<>tnfils) then begin
        if (tnfils<tnfils1) then tnfils1:=tnfils;

        s := 'Download charges: ^5' + cstr(tnfils1) + ' file' + Plural(tnfils1);
        if (TSize1 > 0) then
          s := s+', '+cstr(TSize1)+' bytes';
        if (tpts1 <> 0) then
          s := s+', '+cstr(tpts1)+' file point' + Plural(tpts1);
        s := s+'.';
        star(s);
      end;

      lil := 0;

      star('Download time   : ^5' + FormattedTime(Transfertime));
      star('Transfer rate   : ^5' + cstr(cps) + ' cps');

      thisuser.dk := thisuser.dk + (TSize1 div 1024);
      inc(thisuser.dlktoday, (TSize1 div 1024));
      inc(thisuser.dltoday, tnfils1);
      inc(thisuser.downloads, tnfils1);
      if not (aacs(General.NoFileCredits)) and
         not (fnocredits in thisuser.flags) and (general.filecreditratio) then
         AdjustBalance(tpts1);

      inc(dtoday, tnfils);
      inc(dktoday, TSize div 1024);

      if (numbatchfiles > 0) then
        begin
          TSize:=0; tpts:=0;
          for n:=1 to numbatchfiles do
            begin
              inc(TSize,BatchDLQueue[n]^.Size);
              inc(tpts,BatchDLQueue[n]^.Points);
            end;
          s:='Not transferred : ^5'+cstr(numbatchfiles)+' file' + Plural(NumBatchFiles) + ', '+cstr(TSize)+' bytes';
          if (tpts <> 0) then
            begin
              s := s+', '+cstr(tpts)+' file point' + Plural(tpts);
            end;
          s:=s+'.';
          star(s);
        end;

      if (xbbidirectional in protocol.xbstat) then
        batchul(TRUE,TransferTime);

      if AutoLogoff then
        CountDown
    end;
    saveurec(thisuser, usernum);
  end;
end;

procedure listbatchfiles;
var tot:record
          Points:integer;
          Size:longint;
          Time:longint;
        end;
    s:astr;
    i:integer;
begin
  if (numbatchfiles=0) then
    print(^M^J'Batch queue empty.')
  else begin
    abort:=FALSE; next:=FALSE;

    fillchar(Tot, sizeof(Tot), 0);

    printacr(^M^J'^4##:Filename.Ext Area Pts   Bytes      hh:mm:ss');
    printacr('--------------- ---- ----- ---------- --------');
    i:=1;
    while (not abort) and (not hangup) and (i<=numbatchfiles) do begin
      with BatchDLQueue[i]^ do begin
        if (Section = -1) then
          s := '^7 -- '
        else
          s := '^5' + mrn(cstr(cfbase(Section)), 4);
        s := '^3' + mn(i, 2) + '^4:^5' + align(stripname(FileName)) + ' ' +
             s + ' ^4' + mrn(cstr(Points), 5) + ' ^4' + mrn(FormatNumber(Size), 10) +
             ' ^7' + ctim(Time);
        if (Section <> -1) then
          begin
            loadfileboard(section);
            if (fbnoratio in memuboard.fbstat) then
              s := s + '^5 [No-Ratio]';
          end;
        printacr(s);
        inc(Tot.Points, BatchDLQueue[i]^.Points);
        inc(Tot.Size, BatchDLQueue[i]^.Size);
        inc(Tot.Time,  BatchDLQueue[i]^.Time);
      end;
      inc(i);
    end;

    printacr('^4--------------- ---- ----- ---------- --------');
    with tot do
      s:='^3'+mln('Totals:',20)+' ^4'+mrn(cstr(Points),5)+' '+
         mrn(FormatNumber(Size),10)+' ^7'+ctim(Time);
    printacr(s + ^M^J);
    pausescr(FALSE);
  end;
end;

procedure removebatchfiles;
var s:astr;
    i:integer;
begin
  if numbatchfiles=0 then
    print(^M^J'Batch queue empty.')
  else
    repeat
      prt(^M^J'File to remove (1-'+cstr(numbatchfiles)+') (?=list) : ');
      input (s,2);
      i := value(s);
      if (s = '?') then
        listbatchfiles;
      if (i > 0) and (i <= numbatchfiles) then
        begin
          print(^M^J + stripname(BatchDLQueue[i]^.FileName) + ' deleted from batch.');
          delbatch (i);
        end;
      if (numbatchfiles = 0) then
        print('Queue now empty.');
    until (s <> '?');
end;

procedure clearbatch;
begin
  nl;
  if pynq('Clear queue? ') then
    begin
      while numbatchfiles > 0 do
        begin
          dispose (BatchDLQueue[numbatchfiles]);
          dec (numbatchfiles);
        end;
      batchtime:=0;
      print('^1Queue now empty.');
    end;
end;

end.
