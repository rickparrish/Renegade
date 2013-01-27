{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit file11;

interface

uses crt, dos, overlay, myio, common;

function cansee(const f:ulfrec):boolean;
procedure display_board_name;
procedure display_file(ts:astr; f:ulfrec; NormalPause:boolean);
procedure search;
procedure listfiles(fn:astr);
procedure searchd;
procedure newfiles(b:integer);
procedure gnfiles;
procedure nf(mstr:astr);
procedure fbasechange(var done:boolean; const mstr:astr);
procedure createtempdir;

implementation

uses file0, file1, file10, arcview, multnode, menus, menus2;

var
  lines:byte;
  lasttop:integer;

procedure pause_files;
var t:byte;
    done,obnp,cmdnothid,cmdexists:boolean;
    old_menu, cmd, newmenucmd:astr;
    i,j:integer;
begin
  lil := 0;
  if (lines < pagelength) or (hangup) then
    exit;
  obnp := bnp;
  lines := 2;
  t := 0;

  { newmenutoload should be true ONLY if FILEP is currently loaded }

  old_menu := curmenu;      { otherwise it fucks up calling other menus }
  curmenu := general.menupath + 'filep.mnu';

  if (not newmenutoload) then
    readin2;

  i:=1;
  newmenucmd:='';
  while ((i<=noc) and (newmenucmd='')) do
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
    newmenucmd := ''; j := 0;
    tfileprompt := 0;  done := FALSE;
    repeat
      fcmd(cmd, j, noc, cmdexists, cmdnothid);
      if (j <> 0) and (MenuCommand^[j].cmdkeys <> '-^') and
         (MenuCommand^[j].cmdkeys <> '-/') and (MenuCommand^[j].cmdkeys <> '-\') then
        begin
          domenucommand(done, MenuCommand^[j].cmdkeys + MenuCommand^[j].options, newmenucmd);
          inc(t);
        end;
    until (j = 0) or (done) or (hangup);
    abort := FALSE;  next := FALSE;
    case tfileprompt of
      1:;                   { L1 - Continue }
      2:abort := TRUE;      { L2 - Quit }
      3:next  := TRUE;      { L3 - Next }
      4:begin               { L4 - Toggle newscan }
          prompt(^M^J'^5'+memuboard.name+'^3');
          if (NewScanFBase) then
            print(' will NOT be scanned.')
          else
            print(' WILL be scanned.');

          reset(ScnFile);
          seek(ScnFile, Usernum - 1);
          NewScanFBase := not NewScanFBase;
          write(ScnFile, NewScanFBase);
          close(ScnFile);
        end;
    end;
  until (tfileprompt = 1) or (abort) or (next) or (hangup);
  if (t <= 1) then
    lasttop:=lrn
  else
    lrn := -1;
  initfileboard;
  bnp:=obnp;
  nl;
  curmenu := Old_menu;
  newmenutoload := TRUE;
end;

function cansee(const f:ulfrec):boolean;
begin
  cansee:=(not (notval in f.filestat)) or (usernum = f.owner) or (aacs(general.seeunval));
end;

procedure output_file_stuff(const s:astr);
begin
  if (textrec(newfilesf).mode = fmOutput) then
    begin
      writeln(newfilesf,stripcolor(s));
      lines := 0;
    end
  else
    printacr(s);
end;

procedure display_board_name;
var s:astr;
begin
  if bnp then exit;
  if not (textrec(newfilesf).mode = fmOutput) then cls;
  lasttop:=lrn-1;
  loadfileboard(fileboard);
  s:=stripcolor(memuboard.name) + ' #' + cstr(cfbase(fileboard));
  lines := 5;
  if (not general.filecreditratio) then
    begin
      output_file_stuff('ÚÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
      output_file_stuff('³ File Name  ³   Size   ³  Description        '+mln(s,32)+'³');
      output_file_stuff('ÀÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
    end
  else
    begin
      output_file_stuff('ÚÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
      output_file_stuff('³ÿFile Name  ³'^M' Crs ³ Size ³ Description     ÿ'+mln(s,32)+'³');
      output_file_stuff('ÀÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
    end;
  bnp := TRUE;
end;

procedure display_file(ts:astr; f:ulfrec; NormalPause:boolean);
var s,dd:astr;
    v:verbrec;
    li:longint;
    i:integer;
    vfo:boolean;

  function fsize:astr;
  var s:string[40];
  begin
    if (isrequest in f.filestat) then begin
         if (not general.filecreditratio) then
           s:='   Offline '
         else
           s:='  Offline  ';
      end else
      if (resumelater in f.filestat) then begin
        if (not general.filecreditratio) then
          s:='   ResLatr '
        else
          s:='  ResLatr  ';
      end else
        if (notval in f.filestat) then begin
            if (not general.filecreditratio) then
              s:='   Unvalid '
            else
              s:='  Unvalid  ';
        end else
          if (not general.filecreditratio)  then begin
            li:=f.blocks; li:=(li*128)+f.sizemod;
            s:=''+mrn(FormatNumber(li), 10) + ' ';
          end else begin
            if f.credits>0 then s:=''+mln(cstr(f.credits),6)
               else s:='Free  ';
            s:=s+''+mrn(cstr(f.blocks div 8)+'k',6);
          end;
          if not (not general.filecreditratio) then fsize:=mln(s,13) else fsize:=s;
  end;

  function substone(iscaps:boolean; src,old,new:astr):astr;
  var p:integer;
  begin
    if (old<>'') then begin
      if (iscaps) then new:=allcaps(new);
      p:=pos(allcaps(old),allcaps(src));
      if (p>0) then begin
        insert(new,src,p+length(old));
        delete(src,p,length(old));
      end;
    end;
    substone:=src;
  end;

begin
  if (ts<>'') then dd:=substone(TRUE,dd,ts,''+allcaps(ts)+'');
  if (f.daten>=daynum(newdate)) then s:='*' else s:=' ';
  dd:=f.filename;
  if (ts<>'') then dd:=substone(TRUE,dd,ts,''+allcaps(ts)+'');
  s:=s+''+dd+' '+fsize+'';
  dd:=f.description;
  if (ts<>'') then dd:=substone(TRUE,dd,ts,''+allcaps(ts)+'');
  if (lennmci(dd) > 50) then
    dd := copy(dd, 1, length(dd) - (lennmci(dd) - 50));

  s := s + dd;
  inc(lines);
  output_file_stuff(s);
  if (not NormalPause) then
    pause_files;
  if (f.vpointer<>-1) then begin
    vfo:=(filerec(verbf).mode<>fmclosed);
    if (not vfo) then
      reset(verbf);
    if (ioresult=0) then begin
      seek(verbf,f.vpointer); read(verbf,v);
      if (ioresult=0) then
        for i:=1 to MAXEXTDESC do
          if (v.descr[i]='') then
            break
          else
            begin
              dd:=substone(TRUE,v.descr[i],ts,''+allcaps(ts)+'');
              inc(lines);
              if (not general.filecreditratio) then
                s:=mln('',25)
              else
                s:=mln('',27);
              s:=s+''+dd;
              output_file_stuff(s);
              if (not NormalPause) then
                pause_files;
            end;
      if (not vfo) then close(verbf);
    end;
  end;
  s := '';
  if (fbshowname in memuboard.fbstat) then
    begin
      if (not general.filecreditratio) then
        s:=mln('',25)
      else
        s:=mln('',27);
      s := s + 'Uploaded by ' + caps(f.stowner);
    end;
  if (fbshowdate in memuboard.fbstat) then
    begin
      if (s = '') then
        begin
          if (not general.filecreditratio) then
            s:=mln('',25)
          else
            s:=mln('',27);
          s := s + 'Uploaded on ' + f.date;
        end
      else
        s := s + ' on ' + f.date;
      if (length(s) > 78) then
        s := copy(s,1,78);
    end;
  if (fbshowname in memuboard.fbstat) or (fbshowdate in memuboard.fbstat) then
    begin
      inc(lines);
      output_file_stuff(s);
      if (not NormalPause) then
        pause_files;
    end;
  if (resumelater in f.filestat) and (f.owner=usernum) and
    not (textrec(newfilesf).mode = fmOutput) then
    printacr('^8>^7'+'>> ^3'+'You ^5'+'MUST RESUME^3'+
             ' this file to receive credit for it');
end;

function searchb(b:integer; fn:astr):boolean;
var
  f:ulfrec;
  oldboard,rn,orn:integer;
  x:byte;
  found:boolean;
begin
  searchb := FALSE;
  oldboard:=fileboard;
  found:=false;
  abort:=false; next:=false;
  if (fileboard<>b) then changefileboard(b);
  if (fileboard=b) then begin
    recno(fn,rn);
    if (baddlpath) then exit;
    while ((rn < filesize(DirFile)) and (not next) and (not abort) and (not hangup) and (rn <> -1)) do begin
      seek(DirFile,rn); read(DirFile,f);
      if (cansee(f)) then begin
        found:=TRUE;
        searchb := TRUE;
        orn:=lrn;
        display_board_name;
        display_file('',f, FALSE);
        if (orn <> lrn) then
          begin
            lrn := lasttop;
            if (lrn < 0) then
              bnp := FALSE;
          end;
      end;
      lfn:=fn;
      nrecno(fn,rn);
      if (rn = -1) and (found) and (lines > 2) and (not abort) then
        begin
          lines := pagelength;
          pause_files;
          if (lasttop <> -1) then
            begin
              lrn := lasttop + 1;
              rn := lrn;
              if (lrn < 0) then
                bnp := FALSE;
            end;
        end;
    end;
    close(DirFile);
  end;
  fileboard:=oldboard;
end;

procedure search;
var fn:astr;
    bn:integer;
    oldconfsystem:boolean;
begin
  print(^M^J + fstring.searchline);
  gfn(fn);
  oldconfsystem := confsystem;
  nl;
  dyny := TRUE;
  confsystem := not pynq('Search all conferences? ');
  if (confsystem <> oldconfsystem) then
    newcomptables;
  nl;
  bn:=1; abort:=FALSE; next:=FALSE;
  while (not abort) and (bn<=MaxFBases) and (not hangup) do begin
    if (fbaseac(bn)) then
      begin
        prompt('^1Scanning ^5'+memuboard.name+' #'+cstr(cfbase(bn))+'^1...');
        if not searchb(bn,fn) or (textrec(newfilesf).mode = fmoutput) then
          backerase(14 + lennmci(memuboard.name) + length(cstr(cfbase(bn))));
      end;
    inc(bn);
    wkey;
    if (next) then begin abort:=FALSE; next:=FALSE; end;
  end;
  if (confsystem <> oldconfsystem) then
    begin
      confsystem := oldconfsystem;
      newcomptables;
    end;
end;

procedure listfiles(fn:astr);
begin
  if (fn = '') then
    begin
      print(^M^J + fstring.listline);
      gfn(fn);
    end
  else
    fn := align(fn);
  searchb(fileboard,fn);
end;

function searchbd(b:integer; ts:astr; var found:boolean):boolean;
var oldboard,orn,rn,i:integer;
    f:ulfrec;
    ok,vfo:boolean;
    v:verbrec;
begin
  searchbd := FALSE;
  oldboard:=fileboard;
  if (fileboard<>b) then changefileboard(b);
  if (fileboard=b) then begin
    vfo:=(filerec(verbf).mode<>fmclosed);
    if not vfo then reset(verbf);
    initfileboard;
    if (IOResult <> 0) or (baddlpath) then exit;
    rn:=0;
    while (rn < filesize(DirFile)) and (not abort) and (not next) and (not hangup) do begin
      seek(DirFile,rn); read(DirFile,f);
      if (IOResult = 0) and (cansee(f)) then begin
        ok:=((pos(ts,allcaps(f.description))<>0) or
             (pos(ts,allcaps(f.filename))<>0));
        if (not ok) then
          if (f.vpointer<>-1) then begin
            seek(verbf,f.vpointer); read(verbf,v);
            if (ioresult=0) then begin
              i:=1;
              while (v.descr[i]<>'') and (i<=MAXEXTDESC) and (not ok) do begin
                if pos(ts,allcaps(v.descr[i]))<>0 then ok:=TRUE;
                inc(i);
              end;
            end;
          end;
      end else ok:=FALSE;
      orn := rn; lrn := rn;
      if (ok) then begin
        found:=TRUE;
        searchbd := TRUE;
        display_board_name;
        display_file(ts,f, FALSE);
        if (orn <> lrn) then
          begin
            rn := lasttop;
            if (lrn < 0) then
              bnp := FALSE;
          end;
      end;
      inc(rn);
      if (rn = filesize(DirFile)) and (found) and (lines > 2) and (not abort) then
        begin
          lines := pagelength;
          pause_files;
          if (lasttop <> -1) then
            begin
              lrn := lasttop + 1;
              rn := lrn;
              if (lrn < 0) then
                bnp := FALSE;
            end;
        end;
    end;
    close(DirFile);
    reset(verbf); close(verbf);
  end;
  Lasterror := IOResult;
  fileboard:=oldboard;
end;

procedure searchd;
var s:astr;
    bn:integer;
    oldconfsystem,found:boolean;
begin
  found:=FALSE;
  print(^M^J + fstring.findline1 + ^M^J);
  print(fstring.findline2);
  prt(':'); mpl(20); input(s,20);
  nl;
  if (s<>'') then begin
    print(^M^J'Searching for "'+s+'"'^M^J);
    if pynq('Search all directories? ') then begin
      nl;
      dyny := TRUE;
      oldconfsystem := confsystem;
      confsystem := not pynq('Search all conferences? ');
      if (confsystem <> oldconfsystem) then
        newcomptables;
      nl;
      bn:=1; abort:=FALSE; next:=FALSE;
      while (not abort) and (bn<=MaxFBases) and (not hangup) do
        begin
          if (fbaseac(bn)) then
            begin
              prompt('^1Scanning ^5'+memuboard.name+' #'+cstr(cfbase(bn))+'^1...');
              if not searchbd(bn,s,found) or (textrec(newfilesf).mode = fmoutput) then
                backerase(14 + lennmci(memuboard.name) + length(cstr(cfbase(bn))));
            end;
          wkey;
          next := FALSE;
          inc(bn);
        end;
      if (confsystem <> oldconfsystem) then
        begin
          confsystem := oldconfsystem;
          newcomptables;
        end;
    end else begin
      abort:=FALSE; next:=FALSE;
      searchbd(fileboard,s,found);
    end;
  end;
  if not found then
    print (^M^J'No matching files.');
end;

procedure newfiles(b:integer);
var f:ulfrec;
    oldboard,rn,orn:integer;
    anyshown:boolean;
begin
  oldboard:=fileboard;
  anyshown:=FALSE;
  if (fileboard<>b) then changefileboard(b);
  if (fileboard=b) then begin
    initfileboard;
    if (baddlpath) then exit;
    prompt('^1Scanning ^5'+memuboard.name+' #'+cstr(cfbase(Fileboard))+'^1...');
    rn:=0;
    while (rn < filesize(DirFile)) and (not abort) and (not next) and (not hangup) do begin
      seek(DirFile,rn); read(DirFile,f);
      if ((cansee(f)) and (f.daten>=daynum(newdate))) or
         ((notval in f.filestat) and (cansee(f))) then begin
        anyshown:=TRUE;
        orn:=rn; lrn:=rn;
        display_board_name;
        display_file('',f, FALSE);
        if (rn = filesize(DirFile) - 1) then
         if anyshown and (lines > 2) then
           begin
             lines:=pagelength;
             pause_files;
           end
         else
           if anyshown and not (textrec(newfilesf).mode = fmOutput) then nl;
        if orn<>lrn then begin
           rn:=lasttop;
           if lrn<0 then bnp:=FALSE;
        end;
      end;
      if (rn = filesize(DirFile) - 1) then
       if anyshown and (lines > 2) then
         begin
           lines:=pagelength;
           pause_files;
         end;
      inc(rn);
    end;
    close(DirFile);
    if (not anyshown) or (textrec(newfilesf).mode = fmoutput) then
      backerase(14 + lennmci(memuboard.name) + length(cstr(cfbase(Fileboard))));
  end;
  fileboard:=oldboard;
end;

procedure gnfiles;
var
  oldboard:integer;
  x:integer;
begin
  oldboard := fileboard;
  sysoplog('NewScan of file bases');
  x := 1;
  nl;
  abort:=FALSE; next:=FALSE;
  while (not abort) and (x <= MaxFBases) and (not hangup) do
    begin
      if (cfbase(x) > 0) then
        begin
          changefileboard(x);
          initfileboard;
          if (fileboard = x) and (NewScanFBase) then
            newfiles(Fileboard);
          wkey;
          if (textrec(newfilesf).mode = fmOutput) then
            output_file_stuff('');
          next:=FALSE;
        end;
        inc(x);
    end;
  fileboard := oldboard;
  initfileboard;
  close(DirFile);
end;

procedure nf(mstr:astr);
begin
  if (mstr='C') then newfiles(fileboard)
  else if (mstr='G') then gnfiles
  else if (value(mstr)<>0) then newfiles(value(mstr))
  else begin
    print(^M^J + fstring.newline);
    abort:=FALSE; next:=FALSE;
    if pynq('Search all directories? ') then gnfiles
      else
        begin
          initfileboard;
          newfiles(fileboard);
        end;
  end;
end;

procedure fbasechange(var done:boolean; const mstr:astr);
var s:astr;
    i:integer;
begin
  if (mstr<>'') then
    case upcase(mstr[1]) of
      '+':begin
            i:=fileboard;
            if (fileboard>=MaxFBases) then i:=0 else
              repeat
                inc(i);
                if (fbaseac(i)) then changefileboard(i);
              until ((fileboard=i) or (i>MaxFBases));
            if (fileboard<>i) then print(^M^J'Highest accessible file base.')
              else lastcommandovr:=TRUE;
          end;
      '-':begin
            i:=fileboard;
            if (fileboard<=0) then i:=MaxFBases else
              repeat
                dec(i);
                if fbaseac(i) then changefileboard(i);
              until ((fileboard=i) or (i<=0));
            if (fileboard<>i) then print(^M^J'Lowest accessible file base.')
              else lastcommandovr:=TRUE;
          end;
      'L':begin
            fbaselist(FALSE);
            if (novice in thisuser.flags) then pausescr(FALSE);
          end;
      'N':;
    else
          begin
            i := value(mstr);
            changefileboard(i);
            if (pos(';',mstr) > 0) then begin
              s:=copy(mstr,pos(';',mstr)+1,length(mstr));
              curmenu:=general.menupath+s+'.mnu';
              newmenutoload:=TRUE;
              done:=TRUE;
            end;
            lastcommandovr:=TRUE;
          end;
    end
  else begin
    fbaselist(FALSE);
    s:='?';
    repeat
      prt('^1Change file base (^5?^1=^5List^1) : ');
      scaninput(s,'Q?'^M);
      i:=afbase(value(s));
      if (s='?') then
        fbaselist(FALSE)
      else
        if (((i>=1) and (i<=MaxFBases)) or
           ((i=0) and (s[1]='0'))) and
           (i<>fileboard) then
          changefileboard(i);
    until (s<>'?') or (hangup);
    lastcommandovr:=TRUE;
  end;
end;

procedure createtempdir;
var s:astr;
    i:integer;
begin
  print(^M^J'Enter file path for temporary directory');
  prt(':'); mpl(40); input(s,40);
  if (s<>'') then begin
    if (s[length(s)] <> '\') then
      s := s + '\';
    fileboard:=MaxFBases+1;
    sysoplog('Created temporary directory #'+cstr(fileboard)+
             ' in "'+s+'"');
    fillchar(tempuboard,sizeof(tempuboard),0);
    with tempuboard do begin
      name:='<< Temporary >>';
      filename:='TEMPFILE';
      dlpath:=s;
      ulpath:=s;
      maxfiles:=2000;
      cmttype:=1;
      acs:='s'+cstr(thisuser.sl)+'d'+cstr(thisuser.dsl);
      ulacs:=acs;
      dlacs:=acs;
    end;
    memuboard:=tempuboard;
  end;
end;

end.
