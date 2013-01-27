{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit file10;

interface

uses crt,dos,overlay,myio,common;

procedure editfiles;
procedure validatefiles;

implementation

uses User, arcview, file0, file1, file2, file9, sysop3;

procedure creditfile(var u:userrec; un:integer; var f:ulfrec; credit:boolean;
                     gotpts:longint);
var rfpts:longint;
begin
  if (allcaps(f.stowner)<>allcaps(u.name)) then begin
     print('Uploader name does not match user name!');
     print('Cannot remove credit from user.'^M^J);
     exit;
  end;
  if (not general.filecreditratio) then
    gotpts:=0
  else
    if (gotpts = 0) then
      begin
        rfpts:=(f.blocks div 8) div general.filecreditcompbasesize;
        gotpts:=rfpts*general.filecreditcomp;
        if (gotpts<1) then gotpts:=1;
      end;
  if (credit) then
    prompt('^5Awarding upload credits: ')
  else
    prompt('^5Taking away upload credits: ');
  prompt('1 file, '+cstr(f.blocks div 8)+'k');
  if (credit) then begin
    if u.uploads < 65535 then inc(u.uploads);
    inc(u.uk, f.blocks div 8);
  end else begin
    if u.uploads > 0 then dec(u.uploads);
    dec(u.uk, f.blocks div 8);
  end;
  prompt(', '+cstr(gotpts)+' credits');
  if (credit) then
    inc(u.credit, GotPts)
  else
    dec(u.credit, GotPts);
  print('.');
  saveurec(u,un);
end;

procedure editfile(rn:integer;var c:char;noprompt,ispoints:boolean; var backup:boolean);
var oldconf,vfo,dontshowlist,done,ok,espace,nospace:boolean;
    f:ulfrec;
    s,s1,s2:string[80];
    u:userrec;
    v:verbrec;
    ff:file;
    i,x,dbn,oldfileboard:integer;
begin
  seek(DirFile,rn); read(DirFile,f);

  if (IOResult <> 0) then exit;

  if f.owner>maxusers then f.owner:=1;
  loadurec(u,f.owner);

  if (ispoints) then begin
    nl;
    fileinfo(f,TRUE);
    prt(^M^J'Credits for file ([Enter]=Skip,Q=Quit) : ');
    input(s,5);
    nl;
    if (s='Q') then abort:=TRUE;
    if ((s<>'') and (s<>'Q')) then begin
      f.credits:=value(s);
      f.filestat:=f.filestat-[notval];
      seek(DirFile,rn); write(DirFile,f);
      creditfile(u,f.owner,f,TRUE, f.credits);
      prt(^M^J+'Credits for ^5'+caps(f.stowner)+'^4 : ');
      input(s,5);
      if (s<>'') then
        begin
          if (f.owner=usernum) then
            AdjustBalance(-value(s))
          else
            if (value(s) > 0) then
              inc(u.debit, value(s))
            else
              dec(u.credit, value(s));
          saveurec(u,f.owner);
        end;
    end;
    nl;
    exit;
  end;
  if noprompt then begin
     f.filestat:=f.filestat-[notval];
     seek(DirFile,rn); write(DirFile,f);
     creditfile(u,f.owner,f,TRUE, 0);
     exit;
  end;
  dontshowlist:=FALSE;
  repeat
   abort:=FALSE; next:=FALSE;
   if not dontshowlist then begin
     nl;
     fileinfo(f,TRUE);
     abort:=FALSE;
   end else
     dontshowlist:=FALSE;
   nl;
   abort:=FALSE;
   if (next) then c:='N' else begin
     prt('Edit files (?=help) : ');
     onek(c,'Q?1234567DEGHIMRVWNTPU'^M); if c<>^M then nl;
   end;
   case c of
     ^M:c:='N';
     'P':BackUp := TRUE;
     '?':begin
           print('1-7:Edit file record');
           lcmds(18,3,'Move file','Delete file');
           lcmds(18,3,'Extended edit','Hatched toggle');
           lcmds(18,3,'Previous file','Next file');
           lcmds(18,3,'Resume toggle','Toggle availability');
           lcmds(18,3,'Validation toggle','Withdraw credit');
           lcmds(18,3,'Internal listing','Get Description');
           lcmds(18,3,'Uploader','Quit');
           dontshowlist:=TRUE;
         end;
     'U':if (CoSysOp) then uedit(f.owner);
     '1':begin
           prt('New filename: ');
           mpl(12);
           input(s,12);
           if (s<>'') then
             begin
              if (exist(memuboard.dlpath + s) or
                  exist(memuboard.ulpath + s)) and (not CoSysOp) then
                 print ('Can''t use that filename.')
               else
                 begin
                   if (exist(memuboard.dlpath + f.filename)) then
                     begin
                       assign (ff,memuboard.dlpath + f.filename);
                       rename (ff,memuboard.dlpath + s);
                     end
                   else
                     if (exist(memuboard.ulpath + f.filename)) then
                       begin
                         assign (ff,memuboard.ulpath + f.filename);
                         rename (ff,memuboard.ulpath + s);
                       end;
                   x := ioresult;
                   f.filename := align(s);
                 end;
             end;
         end;
     '3':begin
           print('Enter new description');
           prt(':'); mpl(50); inputl(s,50);
           if s<>'' then f.description:=s;
         end;
     '2':begin
           print('Change file size'^M^J);

           prt('New file size in bytes: ');
           mpl(12); input(s,12);
           if (s<>'') then begin
              f.blocks:=value(s) div 128;
              f.sizemod:=value(s) mod 128;
           end;
         end;
     '4':begin
           prt('New user name/# who uploaded it: ');
           finduser(x);
           if (x < 1) then print(^M^J'This user does not exist.');
           if (x<>0) then begin
             f.owner:=x;
             loadurec(u,x);
             f.stowner:=allcaps(u.name);
           end;
         end;
     '5':begin
           prt('New upload file date: ');
           inputformatted(s,'##/##/####',TRUE);
           if (s<>'') then begin f.date:=s; f.daten:=daynum(s); end;
         end;
     '6':begin
           prt('New number of downloads: '); mpl(5); input(s,5);
           if (s<>'') then f.downloaded:=value(s);
         end;
     '7':begin
           prt('Enter new amount of credits: '); mpl(5); input(s,5);
           if (s<>'') then f.credits:=value(s);
         end;
      'D':if pynq('Are you sure? ') then begin
            deleteff(rn,TRUE);
            dec(lrn);
            s:='Removed "'+sqoutsp(f.filename)+'" from Dir#'+cstr(fileboard);
            nl;
            if (exist(memuboard.dlpath + f.filename) or
                exist(memuboard.ulpath + f.filename)) and
                pynq('Erase file also? ') then
              begin
                kill(memuboard.dlpath + f.filename);
                kill(memuboard.ulpath + f.filename);
                s:=s+' [FILE DELETED]'
              end;

            nl;

            if not (notval in f.filestat) and pynq('Remove from ^5'+caps(u.name)+' #'+cstr(f.owner)+'^7''s ratio? ')
               then creditfile(u,f.owner,f,FALSE, f.credits);

            sysoplog(s);
            c:='N';
          end;
       'I':begin
             if exist(memuboard.dlpath + f.filename) then
               lfi(memuboard.dlpath+f.filename)
             else
               if exist(memuboard.ulpath + f.filename) then
                 lfi(memuboard.ulpath+f.filename);
             abort := FALSE;
           end;
       'M':begin
            oldconf := confsystem;
            if (oldconf = TRUE) then
              newcomptables;
             done:=FALSE;
             repeat
               prt('Move file (Q=Quit,?=List,#=Move-to base) : ');
               input(s,3);
               if s='' then s:='Q';
               dbn:=afbase(value(s));
               if (s='?') then
                 begin
                   fbaselist(FALSE);
                   abort := FALSE;
                   nl;
                 end
               else
                 if (s='Q') or ((dbn=0) and (s<>'0')) then done:=TRUE else
               if (dbn<0) or (dbn>MaxFBases) then print('Can''t move it there.')
               else
               if (dbn = readuboard) then print(^M^J'File is already there!'^M^J)
               else begin
                 oldfileboard:=fileboard;
                 changefileboard(dbn);
                 if (fileboard<>dbn) then print('Can''t move it there.')
                 else begin
                   fileboard:=oldfileboard;
                   done:=TRUE;
                   nl;
                   loadfileboard(fileboard);
                   if exist(memuboard.dlpath + f.filename) then
                     s:=memuboard.dlpath + f.filename
                   else
                     s := memuboard.ulpath + f.filename;
                   s1:=fexpand(copy(memuboard.dlpath,1,length(memuboard.dlpath)-1));
                   loadfileboard(dbn);
                   print('^5Moving file to '+memuboard.name+'^5');
                   s2:=fexpand(copy(memuboard.ulpath,1,length(memuboard.ulpath)-1));
                   ok:=TRUE;

                   if exist(memuboard.ulpath+f.filename) then
                     begin
                       print('There is already a file by that name there.'^M^J);
                       if not pynq('Overwrite it? ') then
                         begin
                           fileboard:=oldfileboard;
                           initfileboard;
                           exit;
                         end;
                     end;

                   if (s1=s2) then
                     begin
                       print('^7No move: directory paths are the same.');
                       espace:=TRUE;
                       ok:=TRUE;
                     end
                   else
                     if (exist(s)) then begin
                       espace:=TRUE;
                       assign(ff,s);
                       reset(ff,1);
                       i:=filesize(ff) div 1024;
                       close(ff);
                       ok := (IOResult = 0);
                       x:=ExtractDriveNumber(memuboard.ulpath);
                       prompt('^5Progress: ');
                       if ok then
                         movefile(ok,nospace,TRUE,s,memuboard.ulpath+f.filename);
                       if (ok) then nl;
                       if (not ok) then begin
                         prompt('^7Move Failed');
                         if (not nospace) then nl else
                           prompt(' - Insuffient space on drive '+chr(x+64)+':');
                         print('!');
                       end;
                     end else
                       print('File does not actually exist.');
                   if ((espace) and (ok)) or (not exist(s)) then begin
                     prompt('^5Moving file record ...');
                     deleteff(rn,FALSE);
                     fileboard:=dbn;

                     close(DirFile); initfileboard;
                     if (baddlpath) then exit;
                     seek(DirFile, filesize(DirFile));
                     write(DirFile, f);
                     close(DirFile);

                     fileboard:=oldfileboard;
                     initfileboard;
                     if (baddlpath) then exit;
                     sysoplog('Moved '+sqoutsp(f.filename)+' from Dir#'+
                              cstr(fileboard)+' to Dir#'+cstr(dbn));
                   end;
                   nl;
                   dec(lrn);
                   c:='N';
                 end;
               end;
             until ((done) or (hangup));
             confsystem := oldconf;
             if (oldconf = TRUE) then
               newcomptables;
           end;
     'T':with f do
           if (isrequest in filestat) then filestat:=filestat-[isrequest]
             else filestat:=filestat+[isrequest];
     'H':with f do
           if (hatched in filestat) then filestat:=filestat-[hatched]
             else filestat:=filestat+[hatched];
     'R':with f do
           if (resumelater in filestat) then filestat:=filestat-[resumelater]
             else filestat:=filestat+[resumelater];
     'V':begin
           with f do
             if (notval in filestat) then filestat:=filestat-[notval]
               else filestat:=filestat+[notval];

             creditfile(u,f.owner,f,not (notval in f.filestat), 0)
         end;
     'G':begin
           if (exist(memuboard.ulpath+f.filename)) then
             s := memuboard.ulpath+f.filename
           else
             s := memuboard.dlpath+f.filename;
           if DizExists(s) then
             begin
               getdiz(f, v);
               if (v.descr[1] <> '') then
                 begin
                   if (f.vpointer = -1) then
                     f.vpointer := NewVPointer;
                   vfo:=(filerec(verbf).mode<>fmclosed);
                   if not vfo then
                     reset(verbf);
                   seek(verbf,f.vpointer);
                   write(verbf,v);
                   if not vfo then
                     close(verbf);
                 end
               else
                 f.vpointer := -1;
             end
           else
             print('File has no internal description.');
         end;
     'E':begin
           vfo:=(filerec(verbf).mode<>fmclosed);
           if not vfo then
             reset(verbf);
           if (f.vpointer = -1) then begin
             print('There is no extended description for this file.');
             if pynq('Create one? ') then begin
               fillchar(v,sizeof(v),0);
               f.vpointer:=NewVPointer;
               seek(verbf,f.vpointer);
               write(verbf,v);
               reset(verbf);
             end;
           end;
           if (f.vpointer<>-1) then begin
             dontshowlist:=FALSE;
             repeat
               if (not dontshowlist) then begin
                 nl;
                 verbfileinfo(f.vpointer,TRUE);
                 seek(verbf,f.vpointer);
                 read(verbf,v);
                 nl;
               end;
               dontshowlist:=FALSE;
               s1:=^M'Q?DP';
               for x:=1 to MAXEXTDESC do
                 begin
                   s1:=s1+chr(x+48);
                   if (v.descr[x] = '') then
                     break;
                 end;
               prt('Extended edit: (1-'+s1[length(s1)]+',D,P,?,Q) :');
               onek(c,s1); nl;
               case c of
                 '?':begin
                       print('1-'+s1[length(s1)]+':Edit extended line');
                       lcmds(20,3,'Delete this entry','Pointer value change');
                       lcmds(20,3,'Quit','');
                       nl;
                       dontshowlist:=TRUE;
                     end;
                 '1'..'9':
                     begin
                       prt('Enter new line:'^M^J);
                       prt(':'); mpl(50); inputl(s,50);
                       if (s<>'') then begin
                         if (s=' ') then
                           if pynq('Set to NULL string? ') then s:='';
                         v.descr[ord(c) - 48] := s;
                         seek(verbf,f.vpointer);
                         if (ioresult=0) then write(verbf,v);
                       end;
                     end;
                 'D':if pynq('Are you sure? ') then begin
                       v.descr[1]:='';
                       seek(verbf,f.vpointer);
                       if (ioresult=0) then write(verbf,v);
                       f.vpointer:=-1;
                       c:='Q';
                     end;
                 'P':begin
                       print('Change pointer value.');
                       print('Pointer range: 0-'+cstr(filesize(verbf)-1));
                       print('(-1 makes inactive for this file without deleting any entries)');

                       prt(^M^J'New pointer value: ');
                       mpl(5); input(s,10);
                       if (s<>'') then begin
                         i:=value(s);
                         if ((i>=-1) and (i<=filesize(verbf)-1)) then
                           f.vpointer:=i;
                       end;
                     end;
               end;
             until (c in ['Q',' ',^M]) or (hangup) or (f.vpointer=-1);
             dontshowlist:=FALSE;
             Lasterror := IOResult;
           end;
           if not vfo then close(verbf);
           c:=' ';
         end;
     'Q':abort:=TRUE;
     'W':begin
           print('^8WARNING: ^5User may not have received credit for upload!'^M^J);
           if pynq('Withdraw credit?? ') then
             creditfile(u,f.owner,f,FALSE,f.credits);
         end;
   else
         next:=TRUE;
   end;
   if not (c in ['P','N','Q']) then begin
      seek(DirFile,rn); write(DirFile,f);
   end;
  until (c in ['P','Q','N']) or (hangup) or (abort) or (next);
end;

procedure editfiles;
var ff:file;
    u:userrec;
    fn,fd,s:astr;
    fsize:longint;
    rn,i,x:integer;
    c:char;
    BackUp:boolean;
begin
  print(^M^J'File editor:');
  gfn(fn); abort:=FALSE; next:=FALSE;
  recno(fn,rn);
  if (baddlpath) then exit;
  if (fn='') or (pos('.',fn)=0) or (rn=-1) then
    print('No matching files.')
  else begin
    lastcommandovr:=TRUE;
    while (rn<>-1) and (not abort) and (not hangup) do
      begin
        BackUp := FALSE;
        if (rn <> -1) then
          begin
            editfile(rn, c, FALSE, FALSE, BackUp);
            if (c='Q') then abort:=TRUE;
          end;
        if (BackUp) then
          lrecno(fn, rn)
        else
          nrecno(fn,rn);
      end;
    close(DirFile);
  end;
end;

procedure validatefiles;
var i:integer;
    c:char;
    isglobal,ispoints,noprompt,oldconf:boolean;

  procedure valfiles(b:integer);
  var u:userrec;
      f:ulfrec;
      s:astr;
      lng:longint;
      oldboard,rn:integer;
      BackUp, shownalready:boolean;
  begin
    oldboard:=fileboard;
    if (fileboard<>b) then changefileboard(b);
    if (fileboard=b) then begin
      recno('*.*',rn);
      shownalready:=FALSE; abort:=FALSE; next:=FALSE;
      while (rn <> -1) and (not abort) and (not hangup) do
        begin
          BackUp := FALSE;
          seek(DirFile,rn); read(DirFile,f);
          if (notval in f.filestat) and
             (not (resumelater in f.filestat)) then
            begin
              if (not shownalready) then
                begin
                  print(^M^J'^1Unvalidated files present in ^5'+memuboard.name+'^5 #'+
                  cstr(fileboard));
                  shownalready:=TRUE;
                end;
              editfile(rn,c,noprompt,ispoints, BackUp);
            end;
          if (BackUp) then
            begin
              repeat
                lrecno('*.*', rn);
              until (rn = -1) or ((notval in f.filestat) and not (resumelater in f.filestat));
            end
          else
            nrecno('*.*',rn);
          wkey;
        end;
      close(DirFile);
    end;
    fileboard:=oldboard;
  end;

begin
  prompt(^M^J'^4[^5M^4]anual, [^5A^4]utomatic, [^5P^4]oint entry, [^5Q^4]uit'^M^J);
  prt(^M^J'File validation: ');
  onek(c,'QMAP');
  nl;
  if (c='Q') then exit;

  oldconf:=confsystem;
  confsystem:=FALSE;
  if oldconf then
    newcomptables;
  ispoints:=(c='P');
  noprompt:=(c='A');
  TempPause := not NoPrompt;
  if inwfcmenu then isglobal:=TRUE
     else begin dyny:=TRUE; isglobal:=pynq('Search all directories? '); end;
  nl;

  abort:=FALSE; next:=FALSE;
  if (isglobal) then begin
    i:=0;
    while (i<=MaxFBases) and (not abort) and (not hangup) do begin
      if (fbaseac(i)) then valfiles(i);
      inc(i);
      wkey;
      if (next) then abort:=FALSE;
    end;
  end else
    valfiles(fileboard);
  confsystem:=oldconf;
  if oldconf then
    newcomptables;
end;

end.
