{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit archive3;

interface

uses crt, dos, overlay, common;

procedure rezipstuff;

implementation

uses archive1, execbat, file0, file11;

var rezipcmd:string[100];

procedure cvtfiles(b:integer; fn:astr; var c_files,c_oldsiz,c_newsiz:longint);
var fi:file of byte;
    f:ulfrec;
    s,ps,ns,es:astr;
    oldsiz,newsiz:longint;
    oldboard,rn:integer;
    atype,i:byte;
    ok:boolean;
begin
  oldboard:=fileboard;
  if (fileboard<>b) then changefileboard(b);
  if (fileboard=b) and not (fbcdrom in memuboard.fbstat) then begin
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
        star('Converting "'+sqoutsp(fn)+'"');
        ok:=FALSE;
        if (not exist(fn)) then
          star('File "'+sqoutsp(fn)+'" doesn''t exist.')
        else begin
          if (rezipcmd<>'') then begin
            assign(fi,sqoutsp(fn));
            reset(fi);
            if (ioresult=0) then begin
              oldsiz:=filesize(fi);
              close(fi);
            end;
            execbatch(ok,tempdir + 'ARC\',
                      rezipcmd+' '+sqoutsp(fn),-1,i,FALSE);
            assign(fi,sqoutsp(fn));
            reset(fi);
            if (ioresult=0) then begin
              newsiz:=filesize(fi);
              f.blocks:=filesize(fi) div 128;
              close(fi);
              seek(DirFile,rn); write(DirFile,f);
            end;
          end else begin
            ok:=TRUE;
            s:=fn;
            assign(fi, sqoutsp(fn));
            reset(fi);
            if (ioresult = 0) then
              begin
                oldsiz := filesize(fi);
                close(fi);
              end;
            conva(ok,atype,atype,sqoutsp(fn),sqoutsp(s));
            if (ok) then
              if (not exist(sqoutsp(s))) then begin
                star('Unable to access "'+sqoutsp(s)+'"');
                sysoplog('Unable to access '+sqoutsp(s));
                ok:=FALSE;
              end;
            if (ok) then begin
              f.filename:=align(stripname(sqoutsp(s)));
              seek(DirFile,rn); write(DirFile,f);

              fsplit(fn,ps,ns,es); fn:=ps+ns+'.#$%';
              kill(fn);

              if (ioresult<>0) then begin
                star('Unable to erase '+sqoutsp(fn));
                sysoplog('Unable to erase '+sqoutsp(fn));
              end;

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
                arccomment(ok,atype,memuboard.cmttype,sqoutsp(s));
              end;
            end else begin
              sysoplog('Unable to convert '+sqoutsp(fn));
              star('Unable to convert '+sqoutsp(fn));
            end;
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

procedure rezipstuff;
var fn:astr;
    c_files,c_oldsiz,c_newsiz:longint;
    i:integer;
    ok1:boolean;
begin
  print(^M^J'Re-compress archives -'^M^J);
  print('Filespec:');
  prt(':'); mpl(78); input(fn,78);
  c_files:=0; c_oldsiz:=0; c_newsiz:=0;
  if (fn<>'') then begin
    print(^M^J'^7Do you wish to use a REZIP external utility?');
    if pynq('(such as REZIP.EXE) ? (Y/N) : ') then begin
      prt(^M^J'Enter commandline (example: "REZIP") : ');
      input(rezipcmd,sizeof(rezipcmd)-1);
      if (rezipcmd='') then exit;
    end else
      rezipcmd:='';
    nl;
    abort:=FALSE; next:=FALSE;
    ok1:=pynq('Search all directories? ');
    sysoplog('Conversion process initiated: '+date+' '+time+'.');
    print(^M^J'Conversion process initiated: '+date+' '+time+'.'^M^J);
    if (ok1) then begin
      i:=0; abort:=FALSE; next:=FALSE;
      while ((not abort) and (i<=MaxFBases) and (not hangup)) do begin
        if (fbaseac(i)) then
          cvtfiles(i,fn,c_files,c_oldsiz,c_newsiz);
        inc(i);
        wkey;
        if (next) then abort:=FALSE;
      end;
    end else
      cvtfiles(fileboard,fn,c_files,c_oldsiz,c_newsiz);
  end;
  sysoplog('Conversion process complete at '+date+' '+time+'.');
  print(^M^J'Conversion process complete at '+date+' '+time+'.'^M^J);
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

end.
