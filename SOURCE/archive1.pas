{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit archive1;

interface

uses crt, dos, overlay, myio, common;

procedure arcdecomp(var ok:boolean; atype:byte; const fn,fspec:astr);
procedure arccomp(var ok:boolean; atype:byte; const fn,fspec:astr);
procedure arccomment(var ok:boolean; atype:byte; cnum:integer; const fn:astr);
procedure arcintegritytest(var ok:boolean; atype:byte; const fn:astr);
procedure conva(var ok:boolean; otype,ntype:byte; const ofn,nfn:astr);
function arctype(s:astr):byte;
procedure listarctypes;
procedure invarc;
procedure extracttotemp;
procedure userarchive;

implementation

uses arcview, file0, file1, file2, file9, file11, execbat;

const
  maxdoschrline=127;

procedure arcdecomp(var ok:boolean; atype:byte; const fn,fspec:astr);
var i:byte;
begin
  purgedir(tempdir + 'ARC\', FALSE);

  execbatch(ok,tempdir + 'ARC\',general.arcspath+
            FunctionalMCI(general.filearcinfo[atype].unarcline,fn,fspec),
            general.filearcinfo[atype].succlevel,i,FALSE);

  if (not ok) and (pos('.diz',fspec) = 0) then
    sysoplog(fn+': errors during de-compression');
end;

procedure arccomp(var ok:boolean; atype:byte; const fn,fspec:astr);
var i:byte;
begin
  if (general.filearcinfo[atype].arcline = '') then
    ok := TRUE
  else
    with general do
      execbatch(ok,tempdir + 'ARC\',arcspath+
                FunctionalMCI(filearcinfo[atype].arcline,fn,fspec),
                filearcinfo[atype].succlevel,i,FALSE);

  if (not ok) then
    sysoplog(fn+': errors during compression');

end;

procedure arccomment(var ok:boolean; atype:byte; cnum:integer; const fn:astr);
var b:boolean;
    i:byte;
    s:astr;
begin
  if (cnum>0) and (general.filearccomment[cnum]<>'') then begin
    b:=general.swapshell;
    general.swapshell:=FALSE;
    s := substitute(general.filearcinfo[atype].cmtline,'%C',general.filearccomment[cnum]);
    s := substitute(s,'%c',general.filearccomment[cnum]);
    execbatch(ok,tempdir + 'ARC\',general.arcspath + FunctionalMCI(s,fn,''),
              general.filearcinfo[atype].succlevel,i,FALSE);
    general.swapshell:=b;
  end;
end;

procedure arcintegritytest(var ok:boolean; atype:byte; const fn:astr);
var i:byte;
begin
  if (general.filearcinfo[atype].testline<>'') then begin
    execbatch(ok,tempdir + 'ARC\',general.arcspath+
              FunctionalMCI(general.filearcinfo[atype].testline,fn,''),
              general.filearcinfo[atype].succlevel,i,FALSE);
  end;
end;

procedure conva(var ok:boolean; otype,ntype:byte; const ofn,nfn:astr);
var f:file;
    nofn,ps,ns:string[80];
    es:string[3];
    eq:boolean;
    FileTime:longint;
begin
  star('Converting archive - stage one.');
  eq:=(otype=ntype);
  if (eq) then begin
    fsplit(ofn,ps,ns,es);
    nofn:=ps+ns+'.#$%';
  end;
  assign(f, ofn);  reset(f); getftime(f, FileTime); close(f);
  Lasterror := IOResult;
  arcdecomp(ok,otype,ofn,'*.*');
  if (not ok) then star('errors in decompression!')
  else begin
    star('Converting archive - stage two.');
    if (eq) then
      begin
        assign(f,ofn);
        rename(f,nofn);
      end;
    arccomp(ok, ntype, nfn, '*.*');
    if (not ok) then
      begin
        star('errors in compression!');
        if (eq) then begin
          assign(f,nofn);
          rename(f,ofn);
        end;
      end
    else
      begin
        assign(f, nfn); reset(f); setftime(f, FileTime); close(f);
        Lasterror := IOResult;
      end;
    if (not exist(sqoutsp(nfn))) then
      ok:=FALSE;
  end;
  if (exist(nofn)) then
    kill(nofn);
end;

function arctype(s:astr):byte;
var atype:byte;

begin
  atype:=1;
  s:=align(stripname(s));
  s:=copy(s,length(s)-2,3);
  while (general.filearcinfo[atype].ext<>'') and
        (general.filearcinfo[atype].ext<>s) and
        (atype<=maxarcs) do
    inc(atype);
  if (atype=maxarcs+1) or (general.filearcinfo[atype].ext='') or
     (not general.filearcinfo[atype].active) then atype:=0;
  arctype:=atype;
end;

procedure listarctypes;
var i:byte;
    j:byte;
begin
  i:=1;
  j:=0;
  while (general.filearcinfo[i].ext<>'') and (i<=maxarcs) do begin
    if (general.filearcinfo[i].active) then begin
      inc(j);
      if (j=1) then prompt('Available archive formats: ') else prompt(',');
      prompt(general.filearcinfo[i].ext);
    end;
    inc(i);
  end;
  if (j=0) then prompt('No archive formats available.');
  nl;
end;

procedure invarc;
begin
  print('Unsupported archive format.'^M^J);
  listarctypes;
  nl;
end;

procedure extracttotemp;
var fi:file of byte;
    f:ulfrec;
    s,fn,ps,ns,es:astr;
    lng,numfiles,tsiz:longint;
    rn:integer;
    atype,i:byte;
    c:char;
    didsomething,done,ok,toextract,tocopy,nospace:boolean;

begin
  didsomething:=FALSE;
  numfiles:=0;
  tsiz:=0;
  print(^M^J'Extract to temporary directory -'^M^J);
  prompt('Already in TEMP: ');
  findfirst(tempdir + 'ARC\*.*',anyfile-dos.directory,dirinfo);
  while (Doserror = 0) do
    begin
      inc(tsiz,dirinfo.size);
      inc(numfiles);
      findnext(dirinfo);
    end;
  if (numfiles=0) then print('Nothing.')
    else print(cstr(numfiles)+' files totalling '+cstr(tsiz)+' bytes.');

  if (not FileSysOp) then begin
    print('The limit is '+cstr(general.maxintemp)+'k bytes.');
    lng:=general.maxintemp; lng:=lng*1024;
    if (tsiz>lng) then
      begin
        print(^M^J'You have exceeded this limit.'^M^J);
        print('Please remove some files from the TEMP directory using');
        print('the user-archive command to free up some space.');
        exit;
      end;
  end;

  prt(^M^J'Filename: ');
  if (FileSysOp) then input(s,69) else input(s,12);
  s:=sqoutsp(s);
  if (hangup) then exit;
  if (s<>'') then begin
    if ((isul(s)) and (not FileSysOp)) then
      print(^M^J'Invalid filename.')
    else
      begin
        if (pos('.',s)=0) then s:=s+'*.*';

        ok:=TRUE; abort:=FALSE; next:=FALSE;
        if (not isul(s)) then begin
          recno(s,rn);
          ok:=(rn <> -1);
          if not aacs(memuboard.dlacs) then
            begin
              print('You do not have access to manipulate that file.');
              ok := FALSE;
            end
          else
            if (ok) then
              begin
                seek(DirFile,rn); read(DirFile,f);
                if exist(memuboard.dlpath+sqoutsp(f.filename)) then
                  fn:=fexpand(memuboard.dlpath+sqoutsp(f.filename))
                else
                  fn:=fexpand(memuboard.ulpath+sqoutsp(f.filename))
              end
            else
              print('File not found: "'+s+'"');
        end else begin
          fn:=fexpand(s);
          ok:=(exist(fn));
          if (ok) then begin
            assign(fi,fn);
            reset(fi);
            if (ioresult<>0) then print('error accessing file.')
            else begin
              fillchar(f, sizeof(f), 0);
              with f do begin
                filename:=align(stripname(fn));
                description:='Unlisted file.';
                blocks:=filesize(fi) div 128;
                owner:=usernum;
                stowner:=caps(thisuser.name);
                vpointer:=-1;
              end;
              f.date:=date;
              f.daten:=daynum(date);
            end;
          end else
            print('File not found: "'+fn+'"');
        end;
        fsplit(fn,ps,ns,es);

      if (ok) then begin
        toextract:=TRUE; tocopy:=FALSE;
        atype:=arctype(fn);
        if (atype=0) then begin
          print(^M^J'Unsupported archive format.');
          listarctypes;
          toextract:=FALSE;
        end;
        print(^M^J'You can (C)opy this file into the TEMP directory,');
        if (toextract) then begin
          print('or (E)xtract files FROM it into the TEMP directory.');
          prt(^M^J'Which? (CE,Q=Quit) : '); onek(c,'QCE');
        end else begin
          print('but you can''t extract files from it.');
          prt(^M^J'Which? (C,Q=Quit) : '); onek(c,'QC');
        end;
        nl;
        if (hangup) then exit;
        case c of
          'C':tocopy:=TRUE;
          'E':toextract:=TRUE;
        else  begin
                tocopy:=FALSE;
                toextract:=FALSE;
              end;
        end;
        if (tocopy) then toextract:=FALSE;
        if (toextract) then begin
          nl; fileinfo(f,FALSE); nl;
          done:=FALSE;
          repeat
            prt('Extract files ([Enter]=All,V=View,Q=Quit) : '); input(s,12);
            if (hangup) then exit;
            abort:=FALSE; next:=FALSE;
            if isul(s) then s := 'Q';
            if (s='') then s:='*.*';
            if (s='V') then begin
              abort:=FALSE; next:=FALSE;
              if (isul(fn)) then lfi(fn) else lfin(rn);
            end
            else
            if (s='Q') then done:=TRUE
            else begin
              if (isul(s)) then print('Illegal filespec.')
              else begin
                ok:=TRUE;
                s:=sqoutsp(s);
                execbatch(ok,tempdir + 'ARC\',general.arcspath+
                          FunctionalMCI(general.filearcinfo[atype].unarcline,fn,s),
                          general.filearcinfo[atype].succlevel,i,FALSE);

                if (not ok) then begin
                  sysoplog(fn+': errors during user decompression');
                  star('errors in decompression!^M^J');
                end else
                  sysoplog('User decompressed '+s+' into TEMP from '+fn);
                if (ok) then didsomething:=TRUE;
              end;
            end;
          until (done) or (hangup);
        end;
        if (tocopy) then begin
          s:=tempdir + 'ARC\' + ns + es;
          prompt('^5Progress: ');
          copyfile(ok,nospace,TRUE,fn,s);
          if (ok) then
            print('^5 - Copy successful.')
          else
            if (nospace) then
              print('^7Copy unsuccessful - insufficient space!')
            else
              print('^7Copy unsuccessful!');
          sysoplog('Copied '+fn+' into TEMP directory.');
          if (ok) then didsomething:=TRUE;
        end;
        if (didsomething) then begin
          print(^M^J'Use the user archive menu command to access');
          print('files in the TEMP directory.');
        end;
      end;
    end;
  end;
  Lasterror := IOResult;
end;

procedure userarchive;
var fi:file of byte;
    f:ulfrec;
    s,s1,fn,savpath:astr;
    gotpts,oldnumbatchfiles,oldfileboard:integer;
    i,atype:byte;
    c:char;
    ok,done,savefilecreditratio:boolean;
    su:ulrec;

  function okname(s:astr):boolean;
  begin
    okname:=TRUE;
    okname:=not iswildcard(s);
    if (isul(s)) then okname:=FALSE;
  end;

begin
  done:=FALSE;
  nl;
  repeat
    prt('Temp archive menu (?=help) : ');
    onek(c,'QADLRVT?');
    case c of
      'Q':done:=TRUE;
      '?':begin
            nl;
            listarctypes;
            nl;
            lcmds(30,3,'Add to archive','');
            lcmds(30,3,'Download files','');
            lcmds(30,3,'List files in directory','');
            lcmds(30,3,'Remove files','');
            lcmds(30,3,'Text view file','');
            lcmds(30,3,'View archive','');
            lcmds(30,3,'Quit','');
            nl;
          end;
      'A':begin
            prt(^M^J'Archive name: '); input(fn,12);
            if (hangup) then exit;
            fn:=tempdir  + 'ARC\' + fn;
            loadfileboard(fileboard);
            if (pos('.',fn)=0) and (memuboard.arctype<>0) then
              fn:=fn+'.'+general.filearcinfo[memuboard.arctype].ext;
            atype:=arctype(fn);
            if (atype=0) then begin
              print(^M^J'Archive format not supported.');
              listarctypes;
              nl;
            end else begin
              prt('File mask: '); input(s,12);
              if (hangup) then exit;
              if (isul(s)) or (pos('@', s) > 0) then print('Illegal file mask.')
              else
              if (s<>'') then begin
                nl;
                ok:=TRUE;
                execbatch(ok,tempdir + 'ARC\',general.arcspath+
                          FunctionalMCI(general.filearcinfo[atype].arcline,fn,s),
                          general.filearcinfo[atype].succlevel,i,FALSE);
                if (not ok) then begin
                  sysoplog(fn+': errors during user compression');
                  star('errors in compression!'^M^J);
                end else
                  sysoplog('Compressed '+s+' into '+fn);
              end;
            end;
          end;
      'D':begin
            prt(^M^J'Filename: '); input(s,12);
            if (hangup) then exit;
            if (not okname(s)) then print('Illegal filename.')
            else begin
              s:=tempdir + 'ARC\' + s;
              assign(fi,s);
              reset(fi);
              if (ioresult=0) then begin
                f.blocks:=filesize(fi) div 128;
                close(fi);
                if (f.blocks<>0) then begin
                  savefilecreditratio:=general.filecreditratio;
                  if ((not general.uldlratio) and
                      (not general.filecreditratio)) then
                    general.filecreditratio:=TRUE;

                  doffstuff(f,stripname(s),gotpts);

                  general.filecreditratio:=savefilecreditratio;

                  with f do begin
                    description:='Temporary file';
                    vpointer:=-1;
                    owner:=0;
                    filestat:=[];
                  end;

                  initfileboard;

                  su:=memuboard;
                  with memuboard do begin
                    dlpath:=tempdir + 'ARC\';
                    ulpath:=tempdir + 'ARC\';
                    name:='Temporary directory';
                    fbstat:=[];
                  end;

                  oldnumbatchfiles:=numbatchfiles;

                  oldfileboard:=fileboard;
                  fileboard:=-1;

                  dlx(f,-1,false);

                  fileboard:=oldfileboard;

                  memuboard:=su;
                  {close(DirFile);}

                  if (numbatchfiles<>oldnumbatchfiles) then begin
                    print(^M^J'^5REMEMBER: If you delete this file from the temporary directory,');
                    print('you will not be able to download it in your batch queue.');
                  end;
                end;
              end;
              nl;
            end;
          end;
      'L':begin
            nl;
            dir(tempdir + 'ARC\','*.*',TRUE);
            nl;
          end;
      'R':begin
            prt(^M^J'File mask: '); input(s,12);
            if (hangup) then exit;
            if (isul(s)) then print('Illegal filename.')
            else begin
              s:=tempdir + 'ARC\' + s;
              findfirst(s, anyfile, dirinfo);
              if (Doserror <> 0) then
                print('File not found.')
              else
                repeat
                  if not ((dirinfo.attr and VolumeID=VolumeID) or
                          (dirinfo.attr and Directory=Directory)) then begin
                    s:=dirinfo.name;
                    kill(tempdir + 'ARC\' + s);
                    sysoplog('Removed from temp dir: '+s);
                  end;
                  findnext(dirinfo);
                until (Doserror <> 0);
            end;
            nl;
          end;
      'T':begin
            prt(^M^J'Filename: '); input(s,12);
            if (hangup) then exit;
            if (not okname(s)) then print('Illegal filename.')
            else begin
              s1:=tempdir + 'ARC\' + s;
              if (not exist(s1)) then
                print(^M^J'File not found.'^M^J)
              else begin
                sysoplog('Viewed in temp dir: '+s);
                nl;
                printf(s1);
              end;
            end;
          end;
      'V':begin
            prt(^M^J'File mask: '); input(fn,12);
            if (hangup) then exit;
            abort:=FALSE; next:=FALSE;
            findfirst(tempdir + 'ARC\' + fn, anyfile, dirinfo);
            if (Doserror <> 0) then
              print('File not found.')
            else
              repeat
                lfi(tempdir + 'ARC\' + dirinfo.name);
                findnext(dirinfo);
              until (Doserror <> 0) or (abort) or (hangup);
            nl;
          end;
    end;
  until ((done) or (hangup));
  lastcommandovr:=TRUE;
  Lasterror := IOResult;
end;

end.
