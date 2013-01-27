{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit file8;

interface

uses crt, dos, overlay, myio, common, timefunc;

procedure batchadd(fname:astr);
procedure send(fn:astr; CDROM, checkratio:boolean; var dok,kabort:boolean; addbatch:boolean; var TransferTime:longint);
procedure receive(fn:astr; Path:astr; ResumeFile:boolean; var dok,kabort,addbatch:boolean; var TransferTime:longint);

implementation

uses file0, file2, file6, file12, execbat;

procedure abeep;
var a,b,c,i,j:integer;
begin
  for j:=1 to 3 do begin
    for i:=1 to 3 do begin
      a:=i*500;
      b:=a;
      while (b>a-300) do begin
        sound(b);
        dec(b,50);
        c:=a+1000;
        while (c>a+700) do begin
          sound(c); dec(c,50);
          delay(2);
        end;
      end;
    end;
    delay(50);
    nosound;
  end;
end;

function CheckFileRatio(q:longint):integer;
var i:longint;
    r:real;
    j,TempFileRatio:integer;
    BadRatio, DailyLimits:boolean;
begin
  DailyLimits := FALSE;
  if (numbatchfiles > 0) then
    for j:=1 to numbatchfiles do
      begin
        loadfileboard (BatchDLQueue[j]^.Section);
        if (not (fbnoratio in memuboard.fbstat)) then
          q := q + BatchDLQueue[j]^.Size div 1024;
      end;

  BadRatio:=FALSE;

  if thisuser.uk > 0 then
    r := (q + thisuser.dk) / thisuser.uk
  else
    r := q + thisuser.dk;

  if (r > general.dlkratio[thisuser.sl]) and (general.dlkratio[thisuser.sl] > 0) then
    BadRatio:=TRUE;

  if (thisuser.uploads > 0) then
    r := trunc((thisuser.downloads + numbatchfiles) / thisuser.uploads)
  else
    r := thisuser.downloads + numbatchfiles;

  if (r > general.dlratio[thisuser.sl]) and (general.dlratio[thisuser.sl] > 0) then
    BadRatio := TRUE;

  if (not general.uldlratio) then
    BadRatio := FALSE;

  if general.dailylimits then
    if (thisuser.dlktoday + q > general.dlkoneday[thisuser.sl]) or
       (thisuser.dltoday + numbatchfiles + 1 > general.dloneday[thisuser.sl]) then
      begin
        BadRatio := TRUE;
        DailyLimits := TRUE;
      end;

  if (aacs(general.nodlratio)) or (fnodlratio in thisuser.flags) then
    BadRatio := FALSE;

  loadfileboard(fileboard);
  if (fbnoratio in memuboard.fbstat) then
    BadRatio := FALSE;


  TempFileRatio := 0;

  if (BadRatio) then
    if (NumBatchFiles = 0) then
      TempFileRatio := 1
    else
      TempFileRatio := 2;

  if DailyLimits and (TempFileRatio > 0) then
    CheckFileRatio := TempFileRatio + 2
  else
    CheckFileRatio := TempFileRatio;

end;

procedure batchadd(fname:astr);
var
  ff:ulfrec;
  slrn,rn:integer;
  slfn:astr;
  ffo:boolean;

begin
  ffo := (filerec(DirFile).mode <> fmclosed);
  if iswildcard(fname) then begin
    print('^1You cannot add wildcards to a batch transfer.'^M^J);
    exit;
  end;

  fname:=sqoutsp(fname);
  findfirst(fname,anyfile,dirinfo);
  if doserror=0 then begin
    if (BatchTime + Dirinfo.size div Rate > nsl) then
      begin
        print('Insufficient time for transfer.');
        abort := TRUE;
      end
    else
      if (numbatchfiles=maxbatchfiles) then
        begin
          print('The batch queue is full.');
          abort := TRUE;
        end
    else begin
      inc(numbatchfiles);
      new(BatchDLQueue[numbatchfiles]);
      with BatchDLQueue[numbatchfiles]^ do begin
        Points := 0;
        Size := Dirinfo.size;
        Storage := Disk;
        if (fileboard <> -1) then
          begin
            slrn:=lrn; slfn:=lfn;
            if ffo then close(DirFile);
            recno(stripname(fname),rn);
            seek(DirFile,rn); read(DirFile,ff);
            close(DirFile);
            if ffo then initfileboard;
            lrn:=slrn; lfn:=slfn;
            if not (fbnoratio in memuboard.fbstat) then
              Points := ff.credits;
            Uploader := ff.owner;
            if (fbcdrom in memuboard.fbstat) then
              Storage := CD;
            OwnerCRC := CRC32(Allcaps(ff.stowner));
          end;
        FileName := fname;
        Time := Dirinfo.Size div Rate;
        inc(BatchTime, Time);
        Section := fileboard;
        sysoplog('Put ' + stripname(FileName) + ' in batch queue.');
        print(fstring.batchadd);
        print(cstr(numbatchfiles)+' File' + Plural(numbatchfiles) + ' ' + FormattedTime(BatchTime));
      end;
    end;
  end else
    print('File doesn''t exist');
  Lasterror := IOResult;
end;

procedure addtologupdown;
var s:astr;
begin
  s:='  ULs: '+cstr(thisuser.uk)+'k in '+cstr(thisuser.uploads)+' file' + Plural(thisuser.uploads);
  s:=s+'  -  DLs: '+cstr(thisuser.dk)+'k in '+cstr(thisuser.downloads)+' file' + Plural(thisuser.downloads);
  sysoplog(s);
end;

procedure send(fn:astr; CDROM, checkratio:boolean; var dok,kabort:boolean; addbatch:boolean; var TransferTime:longint);
var
  cp,s:astr;
  ProtocolNumber,i:integer;
  OldActivity,errlevel:byte;
  AutoLogoff, b,done1,foundit,junk:boolean;
  c:char;

begin
  done1:=FALSE;
  reset(xf);
  if addbatch then
    ProtocolNumber := -4
  else
    repeat
      showprots(FALSE, TRUE, FALSE, FALSE);
      s := GetProts(FALSE, TRUE, FALSE, FALSE);
      prompt(fstring.protocolp); onek(c, s);
      ProtocolNumber := findprot(c, FALSE, TRUE, FALSE, FALSE);
      if (ProtocolNumber = -99) then
        print('Invalid entry.')
      else
        done1:=TRUE;
    until (done1) or (hangup);
    nl;
  dok:=TRUE; kabort:=FALSE;
  findfirst(fn,anyfile,dirinfo);
  if ((ProtocolNumber in [1..200]) or (ProtocolNumber = -4) or (ProtocolNumber = -1)) and checkratio then
    {
     1 - File bad
     2 - File + Batch bad
     3 - File Bad - Daily
     4 - File + Batch bad - Daily
    }
    i := CheckFileRatio(dirinfo.size div 1024);
    case i of
      1,3:begin
          if (i = 3) then
            begin
              printf('DLTMAX');
              if (nofile) then
                begin
                  print(^M^J + fstring.unbalance + ^M^J);
                  print('Today you have downloaded ' + FormatNumber(thisuser.dltoday)+' file' + Plural(thisuser.dltoday));
                  print(' totaling '+FormatNumber(thisuser.dlktoday)+'k.'^M^J);
                  print('The maximum you can download in one day is ' +  FormatNumber(general.dloneday[thisuser.sl])+' file' +
                         Plural(general.dloneday[thisuser.sl]));
                  print(' totaling '+FormatNumber(general.dlkoneday[thisuser.sl])+'k.'^M^J);
                end;
            end
          else
            begin
              printf('DLMAX');
              if (nofile) then
                begin
                  print(^M^J + fstring.unbalance + ^M^J);
                  print('You have downloaded: '+FormatNumber(thisuser.dk)+'k in '+cstr(thisuser.downloads)+' file' +
                         Plural(thisuser.downloads));
                  print('You have uploaded  : '+FormatNumber(thisuser.uk)+'k in '+cstr(thisuser.uploads)+' file' +
                         Plural(thisuser.uploads) + ^M^J);
                  print('  1 upload for every '+FormatNumber(general.dlratio[thisuser.sl])+' downloads must be maintained.');
                  print('  1k must be uploaded for every '+FormatNumber(general.dlkratio[thisuser.sl])+'k downloaded.');
                end;
            end;
          sysoplog('Download refused: Ratio out of balance:' + fn);
          addtologupdown;
          ProtocolNumber :=-2;
        end;
      2,4:begin
          if (i = 1) then
            printf('DLBTMAX')
          else
            printf('DLBMAX');
          if (nofile) then
            begin
              print(^M^J + fstring.unbalance + ^M^J);
              print('Assuming you download the files already in the batch queue,');
              if (i = 2) then
                print('your upload/download ratio would be out of balance.')
              else
                print('you would exceed the maximum download limits for one day.');
            end;
          sysoplog('Download refused: Ratio out of balance:' + fn);
          addtologupdown;
          ProtocolNumber :=-2;
        end;
    end;
  if (ProtocolNumber >= 0) then
    begin
      seek(xf,ProtocolNumber);
      read(xf,protocol);
      Lasterror := IOResult;
    end;
  close(xf);
  lastprot := ProtocolNumber;
  case ProtocolNumber of
   -1:begin
        dok := TRUE;
        TransferTime := getpackdatetime;
        UserColor(1);
        printf(fn);
        nl;
        TransferTime := getpackdatetime - TransferTime;
      end;
   -2:begin
        dok:=FALSE;
        kabort:=TRUE;
      end;
   -3:;
   -4:begin
        batchadd(fn);
        if numbatchfiles = maxbatchfiles then
          dok := FALSE
        else
          dok := TRUE;
      end;
  else
      if (incom) then begin
        if CDROM then
          begin
            print('Please wait, copying file from CD-ROM ...');
            copyfile(Junk, Done1, FALSE, FN, TempDir + 'CD\' + StripName(fn));
            if (Junk and not Done1) then
              fn := TempDir + 'CD\' + StripName(fn);
            nl;
          end;

        cp:=FunctionalMCI(protocol.dlcmd, sqoutsp(fn), '');

        autologoff := pynq('Autologoff after file transfer? ');
        nl;

        star('Ready to send ' + stripname(sqoutsp(fn)));

        b:=general.swapshell; general.swapshell:=FALSE;
        OldActivity := update_node(1);

        TransferTime := getpackdatetime;

        execwindow(junk,tempdir + 'UP\',FunctionalMCI(protocol.envcmd,'','')+#13#10+general.protpath+cp,0,errlevel);

        TransferTime := getpackdatetime - TransferTime;

        update_node(OldActivity);
        general.swapshell:=b;

        foundit:=FALSE; i:=0;
        while (i < 6) and (not foundit) do
          begin
            inc(i);
            if (value(protocol.dlcode[i]) = errlevel) then
              foundit:=TRUE;
          end;

        dok:=TRUE;
        if ((foundit) and (not (xbxferokcode in protocol.xbstat))) then dok:=FALSE;
        if ((not foundit) and (xbxferokcode in protocol.xbstat)) then dok:=FALSE;
        if (xbbidirectional in protocol.xbstat) and
           (not offlinemail) then batchul(TRUE, 0);

        if AutoLogoff then
          CountDown
      end
    else
      TransferTime := 0;
  end;
end;

procedure receive(fn:astr; Path:astr; ResumeFile:boolean;
                  var dok,kabort,addbatch:boolean;
                  var TransferTime:longint);
var cp,s:astr;
    ProtocolNumber,i:integer;
    OldActivity,errlevel:byte;
    b,done1,foundit,junk:boolean;
    c:char;
begin
  done1:=FALSE;
  reset(xf);
  repeat
    showprots(TRUE, FALSE, FALSE, ResumeFile);
    s := GetProts(TRUE, FALSE, FALSE, ResumeFile);
    prompt(fstring.protocolp); onek(c, s);
    ProtocolNumber :=findprot(c, TRUE, FALSE, FALSE, ResumeFile);
    if (ProtocolNumber = -99) then
      print('Invalid entry.')
    else
      done1 := TRUE;
  until (done1) or (hangup);
  nl;

  dok:=TRUE; kabort:=FALSE;
  if (ProtocolNumber >= 0) then
    begin
      seek(xf,ProtocolNumber);
      read(xf,protocol);
      Lasterror := IOResult;
    end;
  close(xf);
  case ProtocolNumber of
   -4:addbatch:=TRUE;
   -2,-3:begin
           dok:=FALSE;
           kabort:=TRUE;
         end;
  else
      if (incom) then begin
        cp:=FunctionalMCI(protocol.ulcmd, sqoutsp(fn),'');

        star('Ready to receive ' + stripname(sqoutsp(fn)));

        b:=general.swapshell; general.swapshell:=FALSE;

        OldActivity := update_node(1);

        purgedir(tempdir + 'UP\', FALSE);

        TransferTime := getpackdatetime;

        execwindow(junk, Path ,FunctionalMCI(protocol.envcmd,'','')+#13#10+general.protpath+cp,0,errlevel);

        TransferTime := getpackdatetime - TransferTime;

        update_node(OldActivity);

        general.swapshell:=b;

        foundit:=FALSE; i:=0;
        while ((i<6) and (not foundit)) do begin
          inc(i);
          if (value(protocol.ulcode[i])=errlevel) then foundit:=TRUE;
        end;

        dok:=TRUE;
        if ((foundit) and (not (xbxferokcode in protocol.xbstat))) then dok:=FALSE;
        if ((not foundit) and (xbxferokcode in protocol.xbstat)) then dok:=FALSE;
      end
    else
      TransferTime := 0;
  end;
end;

end.
