{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit boot;

interface

uses crt, dos, overlay, myio, common;

procedure readp;
procedure initp1;
procedure init;

implementation

uses User, file0;

procedure readp;
var
  d:astr;
  a:integer;

  function sc(s:astr; i:integer):char;
  begin
    sc:=upcase(s[i]);
  end;

begin
  a := 0;
  Reliable := FALSE;
  CallerIDNumber := '';
  while (a<paramcount) do begin
    inc(a);
    if ((sc(paramstr(a),1)='-') or (sc(paramstr(a),1)='/')) then
      case sc(paramstr(a),2) of
        'B':answerbaud:=value(copy(paramstr(a),3,255));
        'C':Reliable := (pos(AllCaps(Liner.Reliable), AllCaps(paramstr(a))) > 0);
        'I':CallerIDNumber := copy(paramstr(a), 3, 255);
        'M':begin
              makeqwkfor := value(copy(paramstr(a),3, 255));
              localioonly:=TRUE;
            end;
        'U':begin
              upqwkfor := value(copy(paramstr(a),3,255));
              localioonly:=TRUE;
            end;
        'N':node:=value(copy(paramstr(a), 3, 255));
        'E':if (length(paramstr(a))>=4) then begin
              d:=allcaps(paramstr(a));
              case d[3] of
                'E':exiterrors:=value(copy(d,4,length(d)-3));
                'N':exitnormal:=value(copy(d,4,length(d)-3));
              end;
            end;
        'L':localioonly:=TRUE;
        'P':begin packbasesonly:=TRUE; localioonly:=TRUE; end;
        'S':begin sortfilesonly:=TRUE; localioonly:=TRUE; end;
        'Q':quitafterdone:=TRUE;
        '5':textmode(259);
        'X':exteventtime:=value(copy(paramstr(a),3,255));
      end;
  end;
  allowabort:=TRUE;
end;

procedure initp1;
var filv:text;
    evf:file of eventrec;
    fstringf:file of fstringrec;
    f:file of byte;
    u:userrec;
    sr:useridxrec;
    i,j:integer;
    x:byte;
    s:astr;
    l:file of Linerec;

  procedure findbadpaths;
  const
    anydone:boolean = FALSE;
  var s,s1,s2:astr;
      i:integer;
  begin
    infield_out_fgrd:=7;
    infield_out_bkgd:=0;
    infield_inp_fgrd:=7;
    infield_inp_bkgd:=0;

    with general do
      for i:=1 to 9 do begin
        case i of 1:s1:='DATA'; 2:s1:='MSGS';
                  3:s1:='MENU'; 4:s1:='ATTACH';
                  5:s1:='MISC'; 6:s1:='LOGS';
                  7:s1:='ARCS'; 8:s1:='PROT';
                  9:s1:='MULT';
        end;
        case i of
          1:s:=datapath;  2:s:=msgpath;
          3:s:=menupath;  4:s:=fileattachpath;
          5:s:=miscpath;  6:s:=logspath;
          7:s:=arcspath;  8:s:=protpath;
          9:s:=multpath;
        end;
        if (not existdir(s)) then begin
          anydone := TRUE;
          writeln(s1+' path is currently '+S);
          writeln('This path is bad or missing.');
          repeat
            writeln;
            s2:=s;
            write('New '+s1+' path: ');
            infield(s2,60);
            s2:=allcaps(sqoutsp(s2));
            if (s=s2) or (s2='') then begin
               writeln(^M^J'Illegal pathname error');
               halt(exiterrors);
            end else begin
              if (s2<>'') then
                if (copy(s2,length(s2),1)<>'\') then s2:=s2+'\';
              if (existdir(s2)) then
                case i of
                  1:datapath:=s2;  2:msgpath:=s2;
                  3:menupath:=s2;  4:fileattachpath:=s2;
                  5:miscpath:=s2;  6:logspath:=s2;
                  7:arcspath:=s2;  8:protpath:=s2;
                  9:multpath:=s2;
                end
              else begin
                writeln;
                writeln('That path does not exist!');
              end;
            end;
          until (existdir(s2));
        end;
      end;
      if Anydone then
        savegeneral(FALSE);
  end;

begin
  assign(LPT,'prt');
  wantout:=TRUE;
  ch:=FALSE; lil:=0; thisuser.pagelen:=20; buf:=''; chatcall:=FALSE;
  lastauthor:=0; ll:=''; chatr:='';

  findbadpaths;

  assign(l,general.datapath+'NODE'+cstr(node)+'.DAT');
  reset(l);
  i := ioresult;
  if (i > 0) then begin
     if (i <> 2) then
       begin
         writeln('error opening ', general.datapath+'NODE'+cstr(node)+'.DAT');
         halt;
       end;
     rewrite(l);
     with Liner do begin
       InitBaud := 19200;
       ComPort := 1;
       MFlags := [CTSRTS];
       Init := 'ATV1S0=0M0E0H0|';
       Answer := 'ATA|';
       Hangup := '^ATH0|';
       Offhook := 'ATH1|';
       CALLERID := 'NMBR = ';
       DoorPath := '';
       UseCallerID := FALSE;
       TeleConfNormal := '^4[%UN] ^9';
       TeleConfAnon := '^4[^9??^4] ^9';
       TeleConfGlobal := '^4[%UN ^0GLOBAL^4] ^9';
       TeleConfPrivate := '^4[%UN ^0PRIVATE^4] ^9';
       OK := 'OK';
       RING := 'RING';
       RELIABLE := '/ARQ';
       NOCARRIER := 'NO CARRIER';
       CONNECT[1]  := 'CONNECT';          CONNECT[2] := 'CONNECT 600';
       CONNECT[3]  := 'CONNECT 1200';     CONNECT[4] := 'CONNECT 2400';
       CONNECT[5]  := 'CONNECT 4800';     CONNECT[6] := 'CONNECT 7200';
       CONNECT[7]  := 'CONNECT 9600';     CONNECT[8] := 'CONNECT 12000';
       CONNECT[9]  := 'CONNECT 14400';   CONNECT[10] := 'CONNECT 16800';
       CONNECT[11] := 'CONNECT 19200';   CONNECT[12] := 'CONNECT 21600';
       CONNECT[13] := 'CONNECT 24000';   CONNECT[14] := 'CONNECT 26400';
       CONNECT[15] := 'CONNECT 28800';   CONNECT[16] := 'CONNECT 31200';
       CONNECT[17] := 'CONNECT 33600';   CONNECT[18] := 'CONNECT 38400';
       CONNECT[19] := 'CONNECT 57600';   CONNECT[20] := 'CONNECT 115200';
       LogonACS := '';
       IRQ := '4';
       Address := '3F8';
     end;
     write(l, Liner);
  end;
  close(l);

  Lasterror := IOResult;

  assign(f,general.datapath+'NODE'+cstr(node)+'.DAT');
  reset(f);
  x:=0;
  seek(f,filesize(f));
  while filesize(f) < sizeof(Linerec) do
     write(f,x);
  close(f);

  reset(l); read(l,Liner); close(l);


  readp; { doot agin }

  if (Liner.comport = 0) and not (digiboard in Liner.mflags) then
    localioonly := TRUE;

  assign(nodef,general.multpath+'multnode.dat');

  TempDir := copy(general.temppath,1,length(general.temppath) - 1) + cstr(node) + '\';
  if not existdir(TempDir) then
    mkdir(copy(TempDir,1,length(TempDir)-1));
  if not existdir(TempDir + 'QWK\') then
    mkdir(TempDir + 'QWK');
  if not existdir(TempDir + 'ARC\') then
    mkdir(TempDir + 'ARC');
  if not existdir(TempDir + 'UP\') then
    mkdir(TempDir + 'UP');
  if not existdir(TempDir + 'CD\') then
    mkdir(TempDir + 'CD');


  if (ioresult <> 0) then
    begin
      writeln('error creating directories: ' + tempdir);
      delay(1000);
    end;

  assign(SchemeFile, general.datapath + 'scheme.dat');
  reset(SchemeFile);
  i := ioresult;
  if (i <> 0) then
    begin
     if (i <> 2) then
       begin
         writeln('error opening ', general.datapath+'SCHEME.DAT');
         halt;
       end;
      rewrite(SchemeFile);
      with scheme do
        begin
          Description := 'Renegade Default Color Scheme';
          fillchar(Color,sizeof(Color),7);
          Color[1] :=  15;
          Color[2] :=   3;
          Color[3] :=  13;
          Color[4] :=  11;
          Color[5] :=   9;
          Color[6] :=  14;
          Color[7] :=  31;
          Color[8] :=  12;
          Color[9] := 140;
          Color[10]:=  10;
        end;
      write(SchemeFile, Scheme);
    end;
  close(SchemeFile);

  assign(sysopf,general.logspath+'sysop.log');
  append(sysopf);
  if (ioresult = 2) then
    rewrite(sysopf);

  close(sysopf);

  if general.multinode then
    begin
      reset(nodef);
      if (ioresult = 2) then
        rewrite(nodef);

      if filesize(nodef) < node then
        begin
          seek(nodef, filesize(nodef));
          noder.user:=0;
          noder.activity:=0;
          noder.status:=[NActive];
          while filesize(nodef) < node do
            write(nodef,noder);
        end;

      close(nodef);
      assign(sysopf,tempdir+'templog.'+cstr(node))
    end
  else
    assign(sysopf,general.logspath+'sysop.log');

  append(sysopf);
  if (ioresult = 2) then
    rewrite(sysopf);

  close(sysopf);

  assign(sysopf1,general.logspath+'slogxxxx.log');

  first_time:=TRUE;
  sl1('^7---> ^5Renegade Node '+cstr(node)+' Loaded on '+dat+'^7 <---');

  assign(f,general.datapath+'string.dat');
  reset(f);
  if (ioresult <> 0) then
    begin
      writeln('Bad or missing STRING.DAT.  Obtain a new one from the distribution package.');
      halt;
    end;

  x:=0;
  seek(f,filesize(f));
  while filesize(f)<sizeof(fstring) do
     write(f,x);

  close(f);

  assign(fstringf,general.datapath+'string.dat');
  reset(fstringf);
  read(fstringf,fstring); close(fstringf);

  assign(sf,general.datapath+'users.idx');
  assign(uf,general.datapath+'users.dat');

  assign(VotingFile,general.datapath+'voting.dat');
  reset(VotingFile);
  i := ioresult;
  if (i <> 0) then
    if (i <> 2) then
      begin
        writeln('error opening ', general.datapath+'VOTING.DAT');
        halt;
      end
    else
      rewrite(VotingFile);
  close(VotingFile);

  if (maxusers>1) then loadurec(thisuser,1)
     else thisuser.sflags:=thisuser.sflags-[slogseparate];

  reset(sf);
  i := IOResult;
  if (I = 2) or (maxsf = -1) then begin
    if (i = 0) then
      close(sf);
    write('Regenerating corrupted user index:   0%');
    kill(general.datapath+'users.idx');
    general.numusers := 0;
    rewrite(sf);
    reset(uf);
    j:=filesize(uf);
    for i:=1 to j - 1 do
      begin
        loadurec(u,i);
        if (i mod 25 = 0) then
          write(^H^H^H^H, (i / filesize(uf) * 100):3:0,'%');
        if not (deleted in u.sflags) then
          inc(Todaynumusers);
        InsertIndex(u.name, i, FALSE, (Deleted in u.sflags));
        InsertIndex(u.realname, i, TRUE, (Deleted in u.sflags));
      end;
    close(uf);
    close(sf);
    writeln;
    savegeneral(FALSE);
    Lasterror := IOResult;
  end
  else
    close(sf);

  assign(conf,general.datapath+'confrenc.dat');
  reset(conf); seek(conf,0); read(conf,confr);
  if (ioresult = 2) then
    begin
      writeln('Bad or missing CONFRENC.DAT - creating...');
      rewrite(conf);
      for i:=1 to 27 do
        begin
          confr.conference[chr(i+63)].acs:='';
          confr.conference[chr(i+63)].name:='';
        end;
      confr.conference['@'].name:='General';
      write(conf,confr);
    end;
  close(conf);

  assign(verbf,general.datapath+'extended.dat');
  reset(verbf);
  if (ioresult = 2) then
    rewrite(verbf);
  close(verbf);

  assign(xf,general.datapath+'protocol.dat');
  reset(xf);
  if (IOResult = 2) then
    rewrite(xf);

  close(xf);


  assign(evf,general.datapath+'events.dat');
  reset(evf);
  if (ioresult = 2) then begin
    writeln('Bad or missing EVENTS.DAT - creating...');
    rewrite(evf); numevents:=1; new(events[1]);
    with events[1]^ do begin
      active:=FALSE;
      description:='New Event';
      etype:='D';
      execdata:='event.bat';
      offhooktime:=5;
      exectime:=0;
      busyduring:=TRUE;
      node:=0;
      durationorlastday:=1;
      execdays:=0;
      missed:=TRUE;
      monthly:=FALSE;
    end;
    write(evf,events[1]^);
  end else begin
    numevents:=0;
    if not eof(evf) then
    repeat
      inc(numevents);
      new(events[numevents]);                 (* DEFINE DYNAMIC MEMORY! *)
      read(evf,events[numevents]^);
      if (IOResult <> 0) then
        begin
          sysoplog('Warning: Bad events file format.');
          break;
        end;
    until (eof(evf));
  end;
  close(evf);

  assign(MBasesFile,general.datapath+'mbases.dat');
  reset(MBasesFile);
  if (ioresult = 2) then
    rewrite(MBasesFile);
  MaxMBases := filesize(MBasesFile);
  close(MBasesFile);

  assign(FBasesFile,general.datapath+'fbases.dat');
  reset(FBasesFile);
  if (ioresult = 2) then
     rewrite(FBasesFile);
  MaxFBases := filesize(FBasesFile);
  close(FBasesFile);

  assign(smf,general.datapath+'shortmsg.dat');

  cfo:=FALSE;

end;

Function ShareLoaded:boolean;
begin
  Regs.ah := $10;
  Regs.al := $0;
  intr($2F,Regs);
  ShareLoaded := (Regs.al = $FF);
end;

Function MSCDExLoaded:boolean;
begin
  Regs.AX := $1500;
  Regs.BX := 0;
  intr($2F, Regs);
  MSCDExLoaded := (Regs.BX <> 0);
end;

procedure init;
var
  junk:integer;
begin
  if (date='01/01/80') then begin
    clrscr;
    writeln('Please set the date & time.');
    halt(exiterrors);
  end;
  regs.AX := $2B01;
  regs.CX := $4445;  { DE }
  regs.DX := $5351;  { SQ }
  Intr($21,regs);
  if regs.AL <> $FF then
    Tasker := DesqView
  else
    begin
      regs.AX := $1600;
      Intr($2F,regs);
      if not (regs.AL in [$00,$01,$80,$FF]) then
        Tasker := Windows
      else
        begin
          regs.AX := $3001;
          intr($21,regs);
          if (regs.AL > 10) then
            Tasker := OS2;
        end;
    end;
  if general.multinode and not shareloaded then
    begin
      clrscr;
      writeln('WARNING: SHARE.EXE should be loaded for multinode operation.');
      delay(100);
    end;
  hangup:=FALSE; incom:=FALSE; outcom:=FALSE;
  echo:=TRUE; doneday:=FALSE;
  checkbreak:=FALSE;
  slogging:=TRUE; trapping:=FALSE;
  readingmail:=FALSE; sysopon:=FALSE;
  beepend:=FALSE;

  readp;

  directvideo:=not general.usebios;

  if General.Networkmode and (node = 0) then
    begin
      localioonly := TRUE;
      Junk := 1;
      while (Junk <= MaxNodes) and (Node = 0) do
        begin
          loadnode(Junk);
          if not (Nactive in Noder.Status) then
            Node := Junk;
          inc(Junk);
        end;
      if (Node = 0) then
        Node := Junk;
    end;

  if (node > 255) then node:=1;

  if general.multinode and (node = 0) then
    begin
      clrscr;
      writeln('WARNING: No node number specified. Defaulting to node 1.');
      node := 1;
      delay(1000);
    end
  else
    if (node = 0) then
      Node := 1;


  initp1;

  loadnode(node);
  with noder do
    begin
      user:=0;
      status:=[NActive,NAvail];
      activity:=0;
    end;

  savenode(node);

  regs.AX := $2B01;
  regs.CX := $4445;  { DE }
  regs.DX := $5351;  { SQ }
  Intr($21,regs);
  if regs.AL <> $FF then
    Tasker := DesqView
  else
    begin
      regs.AX := $1600;
      Intr($2F,regs);
      if not (regs.AL in [$00,$01,$80,$FF]) then
        Tasker := Windows
      else
        begin
          regs.AX := $3001;
          intr($21,regs);
          if (regs.AL > 10) then
            Tasker := OS2;
        end;
    end;
end;

end.
