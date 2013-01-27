{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ SysOp functions: File base editor }

unit sysop9;

interface

uses crt, dos, overlay, common;

procedure dlboardedit;

implementation

uses file0, file2, sysop1, sysop8;

var zc:integer;

procedure dlboardedit;
const ltype:integer=1;
var i1,ii,culb,i2:integer;
    c:char;
    s0:astr;
    f:file;
    done:boolean;

  procedure dlbed(x:integer);
  var
    i,j:integer;
    memuboard:ulrec; { avoids messing up the global one }
  begin
    if ((x>=0) and (x<=MaxFBases)) then begin
      i:=x-1;
      reset(FBasesFile);
      if (i>=0) and (i<=filesize(FBasesFile)-2) then
        for j:=i to filesize(FBasesFile)-2 do begin
          seek(FBasesFile,j+1); read(FBasesFile,memuboard);
          seek(FBasesFile,j); write(FBasesFile,memuboard);
        end;
      seek(FBasesFile,filesize(FBasesFile)-1); truncate(FBasesFile);
      close(FBasesFile);
      dec(MaxFBases);
    end;
    Lasterror := IOResult;
  end;

  procedure dlbei(x:integer);
  var s:string[40];
      i,j,k,l,q:integer;

    procedure getboard;
    begin
      fillchar(memuboard, sizeof(memuboard),0);
      with memuboard do begin
        getdir(0,s);
        name:='<< Not Used >>';
        filename:='NEWDIR';
        dlpath:=s[1]+':DLS\';
        ulpath:=dlpath;
        maxfiles:=2000;
        arctype:=1; cmttype:=1;
      end;
    end;

  begin
    i:=x-1;
    reset(FBasesFile);
    if (i>=0) and (i<=filesize(FBasesFile)) then begin
      prt('Insert how many bases? (1-'+cstr(MAXBASES - filesize(FBasesFile))+') [1] : ');
      inu(q);
      if (badini) or (q < 1) or (q > MAXBASES - filesize(FBasesFile)) then q:=1;
      seek(FBasesFile, filesize(FBasesFile));
      getboard;
      k := filesize(FBasesFile);
      for l := 1 to q do
        write(FBasesFile,memuboard);
      inc(MaxFBases,q);
      for j:=k-1 downto i do begin
        seek(FBasesFile,j);
        read(FBasesFile,memuboard);
        seek(FBasesFile, j + q);
        write(FBasesFile,memuboard); { ...to next record }
      end;
      fillchar(memuboard, sizeof(memuboard), 0);
      with memuboard do begin
        getdir(0,s);
        name:='<< Not Used >>';
        filename:='NEWDIR';
        dlpath:=s[1]+':DLS\';
        ulpath:=dlpath;
        maxfiles:=2000;
        arctype:=1; cmttype:=1;
      end;
      getboard;
      seek(FBasesFile,i);
      for i := 1 to q do
        write(FBasesFile,memuboard);
    end;
    close(FBasesFile);
    Lasterror := IOResult;
  end;

  procedure dlbep(x,y:integer);
  var tempuboard:ulrec;
      i,j,k:integer;
  begin
    reset(FBasesFile);
    k:=y; if (y>x) then dec(y);
    dec(x); dec(y);
    seek(FBasesFile,x); read(FBasesFile,tempuboard);
    i:=x; if (x>y) then j:=-1 else j:=1;
    while (i<>y) do begin
      if (i+j<filesize(FBasesFile)) then begin
        seek(FBasesFile,i+j); read(FBasesFile,memuboard);
        seek(FBasesFile,i); write(FBasesFile,memuboard);
      end;
      inc(i,j);
    end;
    seek(FBasesFile,y); write(FBasesFile,tempuboard);
    inc(x); inc(y); {y:=k;}

    close(FBasesFile);
    Lasterror := IOResult;
  end;

  function flagstate(const fb:ulrec):astr;
  var s:astr;
  begin
    s:='';
    with fb do begin
      if (fbusegifspecs in fbstat) then s:=s+'G' else s:=s+'-';
      if (fbdirdlpath in fbstat) then s:=s+'I' else s:=s+'-';
      if (fbnoratio in fbstat) then s:=s+'N' else s:=s+'-';
      if (fbunhidden in fbstat) then s:=s+'U' else s:=s+'-';
      if (fbcdrom in fbstat) then s:=s+'C' else s:=s+'-';
      if (fbshowname in fbstat) then s:=s+'S' else s:=s+'-';
      if (fbshowdate in fbstat) then s:=s+'D' else s:=s+'-';
      if (fbnodupecheck in fbstat) then s:=s+'P' else s:=s+'-';
    end;
    flagstate:=s;
  end;

  procedure getdirspec(var s:astr);
  begin
    with memuboard do
      if (fbdirdlpath in fbstat) then
        s:=fexpand(dlpath+filename+'.DIR')
      else
        s:=fexpand(general.datapath+filename+'.DIR');
  end;

  procedure dlbem;
  var f:file;
      dirinfo:searchrec;
      xloaded,i,ii:integer;
      c:char;
      s,s1,s2:astr;
      b:byte;
      changed,nospace,ok:boolean;

  begin
    reset(FBasesFile);
    xloaded:=-1;
    prt('Begin editing at which? (1-'+cstr(MaxFBases)+') : '); inu(ii);
    c:=' ';
    if (ii>0) and (ii<=MaxFBases) and (not badini) then begin
      while (c<>'Q') and (not hangup) do begin
        if (xloaded<>ii) then begin
          seek(FBasesFile,ii-1); read(FBasesFile,memuboard);
          xloaded:=ii;
        end;
        with memuboard do
          repeat
            if (c<>'?') then begin
              cls;
              abort:=FALSE; next:=FALSE; mciallowed:=FALSE;
              printacr('^5File base #'+cstr(ii)+' of '+cstr(MaxFBases) + ^M^J);

              printacr('^11. Name        : ^5' + name);
              printacr('^12. Filename    : ^5' + filename);
              printacr('^13. DL/UL path  : ^5' + dlpath+' / '+ulpath);
              mciallowed := FALSE;
              printacr('^14. ACS req''d   : ^5' + acs);
              printacr('^15. UL/DL ACS   : ^5' + ulacs+' / '+dlacs);
              mciallowed := TRUE;
              printacr('^16. Max files   : ^5' + cstr(maxfiles));
              printacr('^17. Password    : ^5' + password);
              if arctype=0 then s:='None' else s:=general.filearcinfo[arctype].ext;
              s:=s+'/'; if cmttype=0 then s:=s+'None' else s:=s+cstr(cmttype);
              printacr('^18. Arc/cmt type: ^5' + s);
              printacr('^1   Flags       : ^5' + flagstate(memuboard));
              printacr('^1Q. Quit');
              mciallowed:=TRUE;
            end;
            prt(^M^J'Edit menu (?=help) : ');
            onek(c,'Q12345678DGICNPUR[]FJLS?'^M);
            nl;
            case c of
              '?':begin
                    print('<CR>Redisplay screen');
                    print('1-8:Modify item');
                    lcmds(15,3,'[Back entry',']Forward entry');
                    lcmds(15,3,'Jump to entry','First entry in list');
                    lcmds(15,3,'Quit and save','Last entry in list');

                    print(^M^J'Toggles:');
                    lcmds(15,3,'NoRatio','Unhidden');
                    lcmds(15,3,'GifSpecs','I*.DIR file in DLPATH');
                    lcmds(15,3,'CD-ROM','Show uploader name');
                    print('(^3D^1)ate uploaded  du(^3P^1)e checking off');
                  end;
              '1':begin
                    prt('New name: ^5');
                    inputwnwc(name,40,changed);
                  end;
              '2':begin
                    getdirspec(s1);
                    prt('New filename: '); mpl(8); input(s,8); s:=sqoutsp(s);
                    if (pos('.',s)>0) then
                      filename:=copy(s,1,pos('.',s)-1);
                    if (s<>'') then begin
                      filename:=s;
                      getdirspec(s2);
                      if ((exist(s1)) and (not exist(s2))) then begin
                        print(^M^J'Old DIR filename: "'+s1+'"');
                        print('New DIR filename: "'+s2+'"'^M^J);
                        if pynq('Rename data files? ') then begin
                          assign(f,s1);
                          rename(f,s2);
                          if (ioresult<>0) then begin
                            print('error renaming files.');
                            pausescr(FALSE);
                          end;
                        end;
                      end;
                    end;
                  end;
              '3':begin
                    inputpath('Enter new download path',dlpath);
                    if (dlpath<>'') then begin
                      if (not existdir(dlpath)) then begin
                        print(^M^J + dlpath+' does not exist.');
                        if (pynq('Create directory now? ')) then begin
                          mkdir(copy(dlpath,1,length(dlpath)-1));
                          if (ioresult<>0) then begin
                            print('error creating directory.');
                            pausescr(FALSE);
                          end;
                        end;
                      end;
                    end;
                    nl;
                    inputpath('Enter new upload path',ulpath);
                    if (ulpath<>'') then begin
                      if (not existdir(ulpath)) then begin
                        print(^M^J + ulpath+' does not exist.');
                        if (pynq('Create directory now? ')) then begin
                          mkdir(copy(ulpath,1,length(ulpath)-1));
                          if (ioresult<>0) then begin
                            print('error creating directory.');
                            pausescr(FALSE);
                          end;
                        end;
                      end;
                    end;
                  end;
              '4':begin
                    prt('New ACS: '); mpl(20);
                    inputwn(acs,20,changed);
                  end;
              '5':begin
                    prt('New UL ACS: '); mpl(20);
                    inputwn(ulacs,20,changed);
                    prt('New DL ACS: '); mpl(20);
                    inputwn(dlacs,20,changed);
                  end;
              '6':begin
                    prt('New max files: '); mpl(4); inu(i);
                    if (not badini) then begin
                      if (i>2000) then i:=2000;
                      maxfiles:=i;
                    end;
                  end;
              '7':begin
                    prt('New PW: ');
                    mpl(10); inputwn1(password,10,'u',changed);
                  end;
              '8':begin
                    if (arctype=0) then s:='None'
                      else s:=general.filearcinfo[arctype].ext;
                    prt('New archive type ("0" for none) ['+s+'] : ');
                    input(s,3);
                    if (s<>'') then begin
                      if (value(s) in [1..maxarcs]) then arctype:=value(s)
                      else
                        for i:=1 to maxarcs do
                          if s=general.filearcinfo[i].ext then arctype:=i;
                      if (value(s)=0) and (s[1]='0') then arctype:=0;
                    end;
                    prt('New comment type ['+cstr(cmttype)+'] : '); ini(b);
                    if (not badini) and (b in [0..3]) then
                      cmttype:=b;
                  end;
              'G','I','N','U','C','S','D','P':
                  begin
                    case c of
                      'D':if (fbshowdate in fbstat) then
                            fbstat := fbstat - [fbshowdate]
                          else
                            fbstat := fbstat + [fbshowdate];
                      'S':if (fbshowname in fbstat) then
                            fbstat := fbstat - [fbshowname]
                          else
                            fbstat := fbstat + [fbshowname];
                      'C':if (fbcdrom in fbstat) then
                            fbstat := fbstat - [fbcdrom]
                          else
                            fbstat := fbstat + [fbcdrom];
                      'G':if (fbusegifspecs in fbstat) then
                            fbstat := fbstat - [fbusegifspecs]
                          else
                            fbstat := fbstat + [fbusegifspecs];
                      'I':begin
                            getdirspec(s1);
                            if (fbdirdlpath in fbstat) then
                              fbstat:=fbstat-[fbdirdlpath]
                            else fbstat:=fbstat+[fbdirdlpath];
                            getdirspec(s2);
                            if ((exist(s1)) and (not exist(s2))) then begin
                              print('Old DIR filename: '+ s1);
                              print('New DIR filename: '+ s2 + ^M^J);
                              if pynq('Move old DIR file to new directory? ') then begin
                                prompt(^M^J'^5Progress: ');
                                movefile(ok,nospace,TRUE,s1,s2);
                                if (nospace) then
                                if (ok) then nl;
                                if (not ok) then begin
                                  prompt('^7Move Failed');
                                  if (not nospace) then nl else
                                    prompt(' - Insuffient space on drive '+
                                            chr(ExtractDriveNumber(s2)+64)+':');
                                  print('!');
                                end;
                              end;
                            end;
                          end;
                      'N':if (fbnoratio in fbstat) then
                            fbstat:=fbstat-[fbnoratio]
                          else fbstat:=fbstat+[fbnoratio];
                      'U':if (fbunhidden in fbstat) then
                            fbstat:=fbstat-[fbunhidden]
                          else fbstat:=fbstat+[fbunhidden];
                      'P':if (fbnodupecheck in fbstat) then
                            fbstat:=fbstat-[fbnodupecheck]
                          else fbstat:=fbstat+[fbnodupecheck];
                    end;
                  end;
              '[':if (ii>1) then dec(ii) else c:=' ';
              ']':if (ii<MaxFBases) then inc(ii) else c:=' ';
              'F':if (ii<>1) then ii:=1 else c:=' ';
              'J':begin
                    prt('Jump to entry: ');
                    input(s,3);
                    if (value(s)>0) and (value(s)<=MaxFBases) then ii:=value(s) else c:=' ';
                  end;
              'L':if (ii<>MaxFBases) then ii:=MaxFBases else c:=' ';
            end;
          until (pos(c,'Q[]FJL')<>0) or (hangup);
          seek(FBasesFile,xloaded-1); write(FBasesFile,memuboard);
      end;
    end;
    close(FBasesFile);
    Lasterror := IOResult;
  end;

  procedure dlbepi;
  var i,j:integer;
  begin
    prt('Move which base? (1-'+cstr(MaxFBases)+'): '); inu(i);
    if ((not badini) and (i>=1) and (i<=MaxFBases)) then begin
      prt('Move before which file base? (1-'+cstr(MaxFBases+1)+') : ');
      inu(j);
      if ((not badini) and (j>=1) and (j<=MaxFBases+1) and
          (j<>i) and (j<>i+1)) then begin
        nl;
        dlbep(i,j);
      end;
    end;
  end;

  function rnr(b:boolean):astr;
  begin
    if b then rnr:='Active' else rnr:='';
  end;

  function atyp(i:integer):astr;
  begin
    if i in [1..6] then atyp:=mln(cstr(i)+'-'+general.filearcinfo[i].ext,5)
      else atyp:='None ';
  end;

begin
  c:=#0;
  repeat
    if (c<>'?') then begin
      cls; done:=FALSE; abort:=FALSE; mciallowed := FALSE;
      case ltype of

(*
                                                                            :
NNN:File base name           :Flags:ACS       :UL ACS    :Name ACS  :Maxf:Dep
===:=========================:=====:==========:==========:==========:====:===

NNN:File base name  :Filename:Download path          :Upload path
===:================:========:=======================:=======================
*)
        1:begin
            printacr('^0NNNN'+seperator+'File base name           '+seperator+
                     'Flags   '+seperator+'ACS       '+seperator+'UL ACS    '+seperator+
                     'DL ACS    '+seperator+'Maxf');
            printacr('^4====:=========================:========:==========:==========:==========:====');
          end;
        2:begin
            printacr('^0NNNN'+seperator+'File base name  '+seperator+'Filename'+
                     seperator+'Download path           '+seperator+'Upload path');
            printacr('^4====:================:========:========================:=======================');
          end;
      end;
      ii:=1;
      reset(FBasesFile);
      AllowContinue := TRUE;
      while (ii<=MaxFBases) and (not abort) and (not hangup) do begin
        seek(FBasesFile,ii-1); read(FBasesFile,memuboard);
        with memuboard do
          case ltype of
            1:printacr('^0'+mn(ii,4)+' ' + '^5' + mln(name,25)+' ^3'+
                       flagstate(memuboard) + '^9' + ' '+mln(acs,10)+' '+
                       mln(ulacs,10)+' '+mln(dlacs,10)+' ^3' + mn(maxfiles,4));
            2:printacr('^0' + mn(ii,4) + ' ' + '^5' + mln(name,16)+' ^3'+
                       mln(filename,8)+' '+mln(dlpath,24)+' '+
                       mln(ulpath,23));
          end;
        inc(ii);
      end;
      AllowContinue := FALSE;
      close(FBasesFile);
      mciallowed := TRUE;
      readuboard:=-1; {loadfileboard(1);   Don't need?}
    end;
    prt(^M^J'File base editor (?=help) : ');
    onek(c,'QDIMPT?'^M);
    case c of
      '?':begin
            print(^M^J'<CR>Redisplay screen');
            lcmds(12,3,'Delete base','Insert base');
            lcmds(12,3,'Modify base','Position base');
            lcmds(12,3,'Quit','Toggle display format');
          end;
      'Q':done:=TRUE;
      'D':begin
            prt('File base to delete? (1-'+cstr(MaxFBases)+') : '); inu(ii);
            if ((ii>=1) and (ii<=MaxFBases) and (not badini)) then begin
              readuboard:=-1; loadfileboard(ii);
              if (fbdirdlpath in memuboard.fbstat) then
                s0:=memuboard.dlpath
              else
                s0:=general.datapath;
              print(^M^J'File base: ^5' + memuboard.name);
              if pynq('Delete this? ') then begin
                sysoplog('* Deleted file base: '+memuboard.name);
                dlbed(ii);
                if pynq('Delete data file? ') then begin
                  writeln; writeln('Deleting: ' + s0 + memuboard.filename+'.DIR');
                  kill(s0 + memuboard.filename+'.DIR');
                  kill(s0 + memuboard.filename+'.SCN');
                  pausescr(FALSE);
                end;
              end;
            end;
          end;
      'I':begin
            prt('File base to insert before? (1-'+cstr(MaxFBases+1)+') : '); inu(ii);
            if (ii>=1) and (ii<= MaxFBases+1) then
              begin
                sysoplog('* Created file base');
                dlbei(ii);
              end;
          end;
      'M':dlbem;
      'P':dlbepi;
      'T':ltype:=ltype mod 2+1;   { toggle between 1, 2 }
    end;
  until (done) or (hangup);
  if ((general.compressbases) and (useron)) then newcomptables;

  if ((fileboard<1) or (fileboard>MaxFBases)) then fileboard:=1;
  readuboard:=-1; loadfileboard(fileboard);
  Lasterror := IOResult;
end;

end.
