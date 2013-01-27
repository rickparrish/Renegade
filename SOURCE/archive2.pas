{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit archive2;

interface

uses crt, dos, overlay, myio, common;

procedure doarccommand(cc:char);

implementation

uses archive1, archive3, file0, file1, arcview, file9, file11, execbat;

const
  maxdoschrline=127;

procedure doarccommand(cc:char);
const maxfiles=100;
var fl:array[1..maxfiles] of astr;
    fn,s,s1,s2,os1,dstr,nstr,estr:astr;
    atype,numfl,rn,i,j,x:integer;
    junk,bb:byte;
    c:char;
    done,ok,ok1:boolean;
    fnx:boolean;          {* whether fn points to file out of Renegade .DIR list *}
    wenttosysop,delbad:boolean;
    f:ulfrec;
    fi:file of byte;
    v:verbrec;
    c_files,c_oldsiz,c_newsiz,oldsiz,newsiz:longint;

  function stripname(i:astr):astr;

    function nextn:integer;
    var n:integer;
    begin
      n:=pos(':',i);
      if (n=0) then n:=pos('\',i);
      if (n=0) then n:=pos('/',i);
      nextn:=n;
    end;

  begin
    while (nextn <> 0) do
      i := copy(i,nextn + 1,80);
    stripname := i;
  end;

  procedure addfl(fn:astr; b:boolean);
  var rn,oldnumfl:integer;
      f:ulfrec;
      s,dstr,nstr,estr:astr;
      dirinfo:searchrec;
  begin
    if (not b) then begin
      oldnumfl:=numfl;
      recno(fn,rn);
      if (fn<>'') and (pos('.',fn)<>0) and (rn<>-1) then
        while (fn<>'') and (rn<>-1) and (numfl<maxfiles) do begin
          seek(DirFile,rn); read(DirFile,f);
          inc(numfl);
          fl[numfl]:=f.filename;
          nrecno(fn,rn);
        end;
      if (numfl=oldnumfl) then print('No matching files.');
      if (numfl>=maxfiles) then print('File records filled.');
    end else begin
      oldnumfl:=numfl;
      fsplit(fn,dstr,nstr,estr); s:=dstr;
      while s[length(s)] = '\' do
        dec(s[0]);
      chdir(s);
      if ioresult<>0 then print('Path not found.')
      else begin
        findfirst(fn,AnyFile-Directory-VolumeID,dirinfo);
        while (doserror=0) and (numfl<maxfiles) do begin
          inc(numfl);
          fl[numfl]:=fexpand(dstr+dirinfo.name);
          findnext(dirinfo);
        end;
        if (numfl>=maxfiles) then print('File records filled.');
        if (numfl=oldnumfl) then print('No matching files.');
      end;
      chdir(start_dir);
    end;
  end;

  procedure testfiles(b:integer; fn:astr; delbad:boolean);
  var fi:file of byte;
      f:ulfrec;
      oldboard,rn,atype:integer;
      ok:boolean;
  begin
    oldboard:=fileboard;
    if (fileboard<>b) then changefileboard(b);
    if (fileboard=b) then begin
      recno(fn,rn); { loads in memuboard }
      abort:=FALSE; next:=FALSE;
      while (fn<>'') and (rn<>-1) and (not abort) and (not hangup) do begin
        seek(DirFile,rn); read(DirFile,f);
        if exist(memuboard.dlpath+f.filename) then
          fn:=memuboard.dlpath+f.filename
        else
          fn:=memuboard.ulpath+f.filename;
        atype:=arctype(fn);
        if (atype<>0) then begin
          display_board_name;
          star('Testing "'+sqoutsp(fn)+'"');
          ok:=TRUE;
          if (not exist(fn)) then begin
            star('File "'+sqoutsp(fn)+'" doesn''t exist.');
            ok:=FALSE;
          end else begin
            arcintegritytest(ok,atype,sqoutsp(fn));
            if (not ok) then begin
              star('File "'+sqoutsp(fn)+'" didn''t pass integrity test.');
              if (delbad) then begin
                deleteff(rn,TRUE);
                kill(fn);
              end;
            end;
          end;
        end;
        nrecno(fn,rn);
        wkey;
      end;
      close(DirFile);
    end;
    fileboard:=oldboard;
    Lasterror := IOResult;
  end;

  procedure cmtfiles(b:integer; fn:astr);
  var
    f:ulfrec;
    oldboard,rn,atype:integer;
    ok:boolean;
  begin
    oldboard:=fileboard;
    if (fileboard<>b) then changefileboard(b);
    if (fileboard=b) then begin
      recno(fn,rn); { loads in memuboard }
      abort:=FALSE; next:=FALSE;
      while (fn<>'') and (rn<>-1) and (not abort) and (not hangup) do begin
        seek(DirFile,rn); read(DirFile,f);
        if exist(memuboard.dlpath+f.filename) then
          fn:=memuboard.dlpath+f.filename
        else
          fn:=memuboard.ulpath+f.filename;
        atype:=arctype(fn);
        if (atype<>0) then begin
          display_board_name;
          nl;
          star('Commenting "'+sqoutsp(fn)+'"');
          ok:=TRUE;
          if (not exist(fn)) then begin
            star('File "'+sqoutsp(fn)+'" doesn''t exist.');
            ok:=FALSE;
          end
          else arccomment(ok,atype,memuboard.cmttype,sqoutsp(fn));
        end;
        nrecno(fn,rn);
        wkey;
      end;
      close(DirFile);
    end;
    fileboard:=oldboard;
  end;

  procedure cvtfiles(b:integer; fn:astr; toa:integer;
                     var c_files,c_oldsiz,c_newsiz:longint);
  var fi:file of byte;
      f:ulfrec;
      s:astr;
      oldboard,rn,atype:integer;
      ok:boolean;
  begin
    oldboard:=fileboard;
    if (fileboard<>b) then changefileboard(b);
    if (fileboard=b) then begin
      recno(fn,rn); { loads in memuboard }
      abort:=FALSE; next:=FALSE;
      while (fn<>'') and (rn<>-1) and (not abort) and (not hangup) do begin
        seek(DirFile,rn); read(DirFile,f);
        if exist(memuboard.dlpath+f.filename) then
          fn:=memuboard.dlpath+f.filename
        else
          fn:=memuboard.ulpath+f.filename;
        atype:=arctype(fn);
        if (atype<>0) and (atype<>toa) then begin
          display_board_name;
          nl;
          star('Converting "'+sqoutsp(fn)+'"');
          ok:=FALSE;
          if (not exist(fn)) then
            begin
              star('File "'+sqoutsp(fn)+'" doesn''t exist - changing extension.');
              s:=copy(fn,1,pos('.',fn))+general.filearcinfo[toa].ext;
              f.filename:=align(stripname(sqoutsp(s)));
              seek(DirFile,rn); write(DirFile,f);
            end
          else begin
            ok:=TRUE;
            s:=copy(fn,1,pos('.',fn))+general.filearcinfo[toa].ext;
            conva(ok,atype,bb,sqoutsp(fn),sqoutsp(s));
            if (ok) then begin
              assign(fi,sqoutsp(fn));
              reset(fi);
              ok:=(ioresult=0);
              if (ok) then begin
                oldsiz:=filesize(fi);
                close(fi);
              end else
                star('Unable to access "'+sqoutsp(fn)+'"');
              if (ok) then
                if (not exist(sqoutsp(s))) then begin
                  star('Unable to access "'+sqoutsp(s)+'"');
                  sysoplog('Unable to access '+sqoutsp(s));
                  ok:=FALSE;
                end;
            end;
            if (ok) then begin
              f.filename:=align(stripname(sqoutsp(s)));
              seek(DirFile,rn); write(DirFile,f);
              kill(sqoutsp(fn));

              assign(fi,sqoutsp(s));
              reset(fi);
              ok:=(ioresult=0);
              if (not ok) then begin
                star('Unable to access '+sqoutsp(s));
                sysoplog('Unable to access '+sqoutsp(s));
              end else begin
                newsiz:=filesize(fi);
                f.blocks:=filesize(fi) div 128;
                close(fi);
                seek(DirFile,rn); write(DirFile,f);
              end;

              if (ok) then begin
                inc(c_oldsiz,oldsiz);
                inc(c_newsiz,newsiz);
                inc(c_files);
                star('Old total space took up  : '+cstr(oldsiz)+' bytes');
                star('New total space taken up : '+cstr(newsiz)+' bytes');
                if (oldsiz-newsiz>0) then
                  star('Space saved              : '+cstr(oldsiz-newsiz)+' bytes')
                else
                  star('Space wasted             : '+cstr(newsiz-oldsiz)+' bytes');
              end;
            end else begin
              sysoplog('Unable to convert '+sqoutsp(fn));
              star('Unable to convert '+sqoutsp(fn));
            end;
          end;
        end;
        nrecno(fn,rn);
        wkey;
      end;
      close(DirFile);
    end;
    fileboard:=oldboard;
    Lasterror := IOResult;
  end;

begin
  TempPause := FALSE;
  numfl:=0;
  initfileboard; { loads in memuboard }
  case cc of
    'A':begin
          print(^M^J'Add file(s) to archive (up to '+cstr(maxfiles)+') -'^M^J);
          print('Archive filename: ');
          prt(':'); mpl(78); input(fn,78);
          if isul(fn) and not FileSysOp then
            fn := '';
          if (fn<>'') then
            begin
              if (pos('.',fn)=0) and (memuboard.arctype<>0) then
                fn:=fn+'.'+general.filearcinfo[memuboard.arctype].ext;
              fnx:=isul(fn);
              if (not fnx) then
                begin
                  if exist(memuboard.dlpath+fn) then
                    fn:=memuboard.dlpath+fn
                  else
                    fn:=memuboard.ulpath+fn
                end;
            fn:=fexpand(fn); atype:=arctype(fn);
            if (atype=0) then begin
              print('Archive format not supported.');
              listarctypes;
            end else begin
              done:=FALSE; c:='A';
              repeat
                if (c='A') then
                  repeat
                    print(^M^J'Add files to list - <CR> to end');
                    prt(cstr(numfl + 1)+':'); mpl(70); input(s,70);
                    if (s <> '') and (not isul(s) or FileSysOp) then
                      begin
                        if pos('.',s)=0 then s:=s+'*.*';
                        addfl(s, isul(s));
                      end;
                  until (s='') or (numfl>=maxfiles) or (hangup);
                prt(^M^J'Add files to list (?=help) : '); onek(c,'QADLR?');
                nl;
                case c of
                  '?':begin
                        lcmds(19,3,'Add more to list','Do it!');
                        lcmds(19,3,'List files in list','Remove files from list');
                        lcmds(19,3,'Quit','');
                      end;
                  'D':begin
                        i:=0;
                        repeat
                          inc(i); j:=1;
                          s2:=sqoutsp(fl[i]);
                          if not isul(s2) then
                            s2:=memuboard.dlpath+s2;
                          s1:=FunctionalMCI(general.filearcinfo[atype].arcline,fn,s2);
                          os1:=s1;
                          while (length(s1)<=maxdoschrline) and (i<numfl) do begin
                            inc(i); inc(j);
                            s2:=sqoutsp(fl[i]);
                            if (not isul(s2)) then
                              s2:=memuboard.dlpath+s2;
                            os1:=s1;
                            s1:=s1+' '+s2;
                          end;
                          if (length(s1)>maxdoschrline) then begin
                            dec(i); dec(j);
                            s1:=os1;
                          end;
                          ok:=TRUE;
                          star('Adding '+cstr(j)+' files to archive...');
                          execbatch(ok,
                                    tempdir + 'UP\',general.arcspath+s1,
                                    general.filearcinfo[atype].succlevel,junk,FALSE);
                          if (not ok) then begin
                            star('errors in adding files');
                            ok:=pynq('Continue anyway? ');
                            if (hangup) then ok:=FALSE;
                          end;
                        until (i>=numfl) or (not ok);
                        arccomment(ok,atype,memuboard.cmttype,fn);
                        nl;
                        if (not fnx) then begin
                          s1:=stripname(fn);
                          recno(s1,rn);
                          if (rn<>-1) then
                            print('^5NOTE: File already exists in listing!');
                          if pynq('Add archive to listing? ') then begin
                            assign(fi,fn);
                            reset(fi);
                            if ioresult=0 then begin
                              f.blocks:=filesize(fi) div 128;
                              close(fi);
                            end;
                            f.filename:=align(s1);
                            ok1:=TRUE;
                            if pynq('Replace a file in directory? ') then begin
                              repeat
                                prt(^M^J'Enter filename: '); mpl(12); input(s2,12);
                                recno(s2,rn);
                                if rn=-1 then print('File not found!');
                                if s2='' then print('Aborted!');
                              until (rn<>-1) or (s2='') or (hangup);
                              if s2<>'' then begin
                                seek(DirFile,rn); read(DirFile,f);
                                kill(memuboard.ulpath + sqoutsp(f.filename));
                                f.filename := align(s1);
                                {
                                with f do begin
                                  description:=f1.description;
                                  vpointer:=f1.vpointer;
                                  downloaded:=f1.downloaded;
                                  owner:=f1.owner;
                                  stowner:=f1.stowner;
                                  date:=f1.date;
                                  daten:=f1.daten;
                                end;
                                f1.vpointer:=-1;
                                }
                                seek(DirFile,rn); write(DirFile,f);
                              end else
                                ok1:=FALSE;
                            end else
                              ok1:=FALSE;

                            if (not ok1) then begin
                              wenttosysop:=FALSE;
                              dodescrs(f,v,wenttosysop);
                              f.downloaded:=0;
                              f.owner:=usernum;
                              f.stowner:=allcaps(thisuser.name);
                              f.date:=date;
                              f.daten:=daynum(date);
                            end;

                            f.filestat:=[];
                            if (not FileSysOp) and (not general.validateallfiles) then
                              f.filestat:=f.filestat+[notval];

                            if (not general.filecreditratio) then
                              f.credits:=0
                            else
                              f.credits:=(f.blocks div 8) div general.filecreditcompbasesize;

                            if (rn=-1) then writefv(filesize(DirFile),f,v) else writefv(rn,f,v);
                          end;
                        end;
                        if pynq('Delete original files? ') then
                          for i:=1 to numfl do begin
                            s2:=sqoutsp(fl[i]);
                            if not isul(fl[i]) then begin
                              recno(s2,rn);
                              if rn<>-1 then deleteff(rn,TRUE);
                              s2:=memuboard.dlpath+s2;
                            end;
                            kill(s2);
                          end;
                        if ok then done:=TRUE;
                      end;
                  'L':if (numfl=0) then print('No files in list!')
                      else begin
                        abort:=FALSE; next:=FALSE;
                        s:=''; j:=0;
                        i:=0;
                        repeat
                          inc(i);
                          if isul(fl[i]) then s:=s+'^3' else s:=s+'^1';
                          s:=s+align(stripname(fl[i]));
                          inc(j);
                          if j<5 then s:=s+'    '
                          else begin
                            printacr(s);
                            s:=''; j:=0;
                          end;
                        until (i=numfl) or (abort) or (hangup);
                        if (j in [1..4]) and (not abort) then
                          printacr(s);
                      end;
                  'R':begin
                        prt('Remove filename: '); mpl(12); input(s,12);
                        i:=0;
                        repeat
                          inc(i);
                          if align(stripname(fl[i]))=align(s) then begin
                            s1:=sqoutsp(fl[i]); prompt('^3'+s1);
                            if pynq('   Remove it? ') then begin
                              for j:=i to numfl-1 do fl[j]:=fl[j+1];
                              dec(numfl); dec(i);
                            end;
                          end;
                        until (i>=numfl);
                      end;
                  'Q':done:=TRUE;
                end;
              until (done) or (hangup);

            end;
          end;
        end;
    'C':begin
          print(^M^J'Convert archive formats -'^M^J);
          print('Filespec:');
          prt(':'); mpl(78); input(fn,78);
          c_files:=0; c_oldsiz:=0; c_newsiz:=0;
          if (fn<>'') then begin
            nl;
            abort:=FALSE; next:=FALSE;
            repeat
              prt('Archive type to use? (?=List) : '); input(s,3);
              if (s='?') then begin nl; listarctypes; nl; end;
            until (s<>'?');
            if (value(s)<>0) then bb:=value(s)
              else bb:=arctype('F.'+s);
            if (bb<>0) then begin
              sysoplog('Conversion process initiated at '+date+' '+time+'.');
              if (isul(fn)) then begin
                fsplit(fn,dstr,nstr,estr); s:=dstr;
                findfirst(fn,AnyFile-Directory-VolumeID,dirinfo);
                abort:=FALSE; next:=FALSE;
                while (doserror=0) and (not abort) and (not hangup) do begin
                  fn:=fexpand(sqoutsp(dstr+dirinfo.name));
                  atype:=arctype(fn);
                  if (atype<>0) and (atype<>bb) then begin
                    star('Converting "'+fn+'"');
                    ok:=TRUE;
                    s:=copy(fn,1,pos('.',fn))+general.filearcinfo[bb].ext;
                    conva(ok,atype,bb,fn,s);
                    if (ok) then begin
                      assign(fi,sqoutsp(fn));
                      reset(fi);
                      ok:=(ioresult=0);
                      if (ok) then begin
                        oldsiz:=filesize(fi);
                        close(fi);
                      end else
                        star('Unable to access '+sqoutsp(fn));
                      if (ok) then
                        if (not exist(sqoutsp(s))) then begin
                          star('Unable to access '+sqoutsp(s));
                          sysoplog('Unable to access '+sqoutsp(s));
                          ok:=FALSE;
                        end;
                    end;
                    if (ok) then begin
                      kill(sqoutsp(fn));

                      assign(fi,sqoutsp(s));
                      reset(fi);
                      ok:=(ioresult=0);
                      if (ok) then begin
                        newsiz:=filesize(fi);
                        close(fi);
                      end else
                        star('Unable to access "'+sqoutsp(s)+'"');

                      if (ok) then begin
                        inc(c_oldsiz,oldsiz);
                        inc(c_newsiz,newsiz);
                        inc(c_files);
                        star('Old total space took up  : '+cstr(oldsiz)+' bytes');
                        star('New total space taken up : '+cstr(newsiz)+' bytes');
                        if (oldsiz-newsiz>0) then
                          star('Space saved              : '+cstr(oldsiz-newsiz)+' bytes')
                        else
                          star('Space wasted             : '+cstr(newsiz-oldsiz)+' bytes');
                      end;
                    end else begin
                      sysoplog('Unable to convert '+sqoutsp(fn));
                      star('Unable to convert '+sqoutsp(fn));
                    end;
                  end;
                  findnext(dirinfo);
                  wkey;
                end;
              end else begin
                ok1:=pynq('Search all directories? ');
                nl;
                if (ok1) then begin
                  i:=1; abort:=FALSE; next:=FALSE;
                  while (not abort) and (i<=MaxFBases) and (not hangup) do begin
                    if (fbaseac(i)) then
                      cvtfiles(i,fn,bb,c_files,c_oldsiz,c_newsiz);
                    inc(i);
                    wkey;
                    if (next) then abort:=FALSE;
                  end;
                end else
                  cvtfiles(fileboard,fn,bb,c_files,c_oldsiz,c_newsiz);
                reset(DirFile);
              end;
              sysoplog('Conversion process completed at '+date+' '+time+'.');
              nl;
              nl;
              star('Total archives converted : '+cstr(c_files));
              star('Old total space took up  : '+cstr(c_oldsiz)+' bytes');
              star('New total space taken up : '+cstr(c_newsiz)+' bytes');
              if (c_oldsiz-c_newsiz>0) then
                star('Space saved              : '+cstr(c_oldsiz-c_newsiz)+' bytes')
              else
                star('Space wasted             : '+cstr(c_newsiz-c_oldsiz)+' bytes');
              sysoplog('Converted '+cstr(c_files)+' archives; old size='+
                       cstr(c_oldsiz)+' bytes, new size='+cstr(c_newsiz)+' bytes');
            end;
          end;
        end;
    'M':begin
          print(^M^J'Comment field update -'^M^J);
          print('Filespec:');
          prt(':'); mpl(78); input(fn,78);
          if (fn<>'') then begin
            nl;
            abort:=FALSE; next:=FALSE;
            if (isul(fn)) then begin
              prt('Comment to use? (1-3,0=None) [1] : ');
              ini(bb);
              if (badini) or (bb<0) or (bb>3) then bb:=1;
              fsplit(fn,dstr,nstr,estr); s:=dstr;
              findfirst(fn,AnyFile-Directory-VolumeID,dirinfo);
              abort:=FALSE; next:=FALSE;
              while (doserror=0) and (not abort) and (not hangup) do begin
                fn:=fexpand(sqoutsp(dstr+dirinfo.name));
                atype:=arctype(fn);
                if (atype<>0) then begin
                  star('Commenting "'+fn+'"');
                  ok:=TRUE;
                  arccomment(ok,atype,bb,fn);
                end;
                findnext(dirinfo);
                wkey;
              end;
            end else begin
              ok1:=pynq('Search all directories? ');
              nl;
              if (ok1) then begin
                i:=0; abort:=FALSE; next:=FALSE;
                while (not abort) and (i<=MaxFBases) and (not hangup) do begin
                  if (fbaseac(i)) then cmtfiles(i,fn);
                  inc(i);
                  wkey;
                  if (next) then abort:=FALSE;
                end;
              end else
                cmtfiles(fileboard,fn);
              reset(DirFile);
            end;
          end;
        end;
    'T':begin
          print(^M^J'File integrity testing -'^M^J);
          print('Filespec:');
          prt(':'); mpl(78); input(fn,78);
          if (fn<>'') then begin
            nl;
            delbad:=pynq('Delete files that don''t pass the test? ');
            nl;
            abort:=FALSE; next:=FALSE;
            if (isul(fn)) then begin
              fsplit(fn,dstr,nstr,estr); s:=dstr;
              findfirst(fn,AnyFile-Directory-VolumeID,dirinfo);
              abort:=FALSE; next:=FALSE;
              while (doserror=0) and (not abort) and (not hangup) do begin
                fn:=fexpand(sqoutsp(dstr+dirinfo.name));
                atype:=arctype(fn);
                if (atype<>0) then begin
                  star('Testing "'+fn+'"');
                  ok:=TRUE;
                  arcintegritytest(ok,atype,fn);
                  writeln(ok);
                  if (not ok) then
                    begin
                      star('File "'+fn+'" didn''t pass integrity test.');
                      if (delbad) then
                        kill(fn);
                    end
                  else
                    star('Passed integrity test.');
                end;
                findnext(dirinfo);
                wkey;
              end;
            end else begin
              ok1:=pynq('Search all directories? ');
              nl;
              if (ok1) then begin
                i:=0; abort:=FALSE; next:=FALSE;
                while (not abort) and (i<=MaxFBases) and (not hangup) do begin
                  if (fbaseac(i)) then testfiles(i,fn,delbad);
                  inc(i);
                  wkey;
                  if (next) then abort:=FALSE;
                end;
              end else
                testfiles(fileboard,fn,delbad);
              reset(DirFile);
            end;
          end;
        end;
  end;
  close(DirFile);
  Lasterror := IOResult;
end;

end.
