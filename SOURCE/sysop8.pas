{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Message base editor}

unit sysop8;

interface

uses crt, dos, overlay, common;

procedure boardedit;

implementation

uses file0, sysop1, mail0;

procedure boardedit;
const ltype:integer=1;
var f1:file;
    s,s1:astr;
    i1,i2,ii:integer;
    c:char;

  procedure bed(x:integer);
  var i,j:integer;
  begin
    if ((x>0) and (x<=MaxMBases)) then begin
      i:=x-1;
      reset(MBasesFile);
      if (i>=0) and (i<=filesize(MBasesFile)-2) then
        for j:=i to filesize(MBasesFile)-2 do begin
          seek(MBasesFile,j+1); read(MBasesFile,memboard);
          seek(MBasesFile,j); write(MBasesFile,memboard);
        end;
      seek(MBasesFile,filesize(MBasesFile)-1); truncate(MBasesFile);
      close(MBasesFile);
      dec(MaxMBases);
    end;
    Lasterror := IOResult;
  end;

  procedure bei(x:integer);
  var i,j,k,l,q,nq:integer;
    procedure getboard;
    begin
      fillchar(memboard,sizeof(memboard),0);
      with memboard do begin
        name:='<< Not used >>';
        filename:='NEWBOARD';
        inc(nq);
        QWKIndex:=nq;
        sysopacs:='s255';
        maxmsgs:=100;
        anonymous:=atno;
        if (General.origin<>'') then origin:=General.origin;
        text_color:=General.text_color;
        quote_color:=General.quote_color;
        tear_color:=General.tear_color;
        origin_color:=General.origin_color;
        if (General.skludge) then mbstat:=mbstat+[mbskludge];
        if (General.sseenby) then mbstat:=mbstat+[mbsseenby];
        if (General.sorigin) then mbstat:=mbstat+[mbsorigin];
        if (General.addtear) then mbstat:=mbstat+[mbaddtear];
      end;
    end;
  begin
    i := x - 1;
    reset(MBasesFile);
    if (i >= 0) and (i <= filesize(MBasesFile))  then begin
      prt('Insert how many bases? [1] : ');
      inu(q);
      if (badini) then
        q := 1;
      if (General.CompressBases) and ((filesize(MBasesFile) + q) > MAXBASES) then
        begin
          print('You cannot have more than '+FormatNumber(MAXBASES)+' bases with base number compression on.');
          pausescr(FALSE);
          q := 0;
        end;
      if (q >= 1) then
        begin
          seek(MBasesFile, 0);
          nq := 0;
          for j := 1 to filesize(MBasesFile) do
            begin
              read(MBasesFile, memboard);
              if (memboard.qwkindex > nq) then
                nq := memboard.qwkindex;
            end;
          seek(MBasesFile, filesize(MBasesFile));
          getboard;
          dec(nq);
          k := filesize(MBasesFile);
          for l := 1 to q do
            write(MBasesFile,memboard);
          inc(MaxMBases, q);
          for j:=k-1 downto i do begin
            seek(MBasesFile,j);
            read(MBasesFile,memboard);
            seek(MBasesFile, j + q);
            write(MBasesFile,memboard);                      { ...to next record }
          end;
          seek(MBasesFile, 0);
          k := 0;
          for j := 1 to filesize(MBasesFile) do
            begin
              read(MBasesFile, memboard);
              if (memboard.qwkindex > k) then
                k := memboard.qwkindex;
            end;
          inc(k);
          seek(MBasesFile,i);
          for i := 1 to q do
            begin
              getboard;
              write(MBasesFile,memboard);
            end;
        end;
    end;
    close(MBasesFile);
    Lasterror := IOResult;
  end;

  procedure bep(x,y:integer);
  var tempboard:boardrec;
      i,j,k:integer;
  begin
    k:=y; if (y>x) then dec(y);
    dec(x); dec(y);
    reset(MBasesFile);
    seek(MBasesFile,x); read(MBasesFile,tempboard);
    i:=x; if (x>y) then j:=-1 else j:=1;
    while (i<>y) do begin
      if (i+j<filesize(MBasesFile)) then begin
        seek(MBasesFile,i+j); read(MBasesFile,memboard);
        seek(MBasesFile,i); write(MBasesFile,memboard);
      end;
      inc(i,j);
    end;
    seek(MBasesFile,y); write(MBasesFile,tempboard);
    inc(x); inc(y); {y:=k;}
    close(MBasesFile);
    Lasterror := IOResult;
  end;

  function flagstate(const mb:boardrec):string;
  var s:string[5];
  begin
    s:='';
    with mb do begin
      if (mbrealname in mbstat) then s:=s+'R' else s:=s+'-';
      if (mbunhidden in mbstat) then s:=s+'U' else s:=s+'-';
      if (mbfilter in mbstat) then s:=s+'A' else s:=s+'-';
      if (mbprivate in mbstat) then s:=s+'P' else s:=s+'-';
      if (mbforceread in mbstat) then s:=s+'F' else s:=s+'-';
    end;
    flagstate:=s;
  end;

  function netflags(const mb:boardrec):string;
  var s:string[6];
  begin
    s:='';
    with mb do begin
      if (mbskludge in mbstat) then s:=s+'K' else s:=s+'-';
      if (mbsseenby in mbstat) then s:=s+'S' else s:=s+'-';
      if (mbsorigin in mbstat) then s:=s+'O' else s:=s+'-';
      s:=s+'/';
      if (mbaddtear in mbstat) then s:=s+'T' else s:=s+'-';
      if (mbinternet in mbstat) then s:=s+'I' else s:=s+'-';
    end;
    netflags:=s;
  end;

  procedure incolor(const msg:astr; var i:byte);
  begin
    prompt('^1Enter new '+msg+' color (0-9) : ');
    mpl(1);
    input(s,1);
    if ((s<>'') and (s[1] in ['0'..'9'])) then i:=ord(s[1])-48;
  end;

  procedure getbrdspec(var s:astr);
  begin
      s:=fexpand(general.msgpath+memboard.filename+'.HDR');
  end;

  procedure bem;
  var f:file;
      dirinfo:searchrec;
      s,s1,s2,s3:string[80];
      xloaded,i,i1,i2,ii:integer;
      c,c1:char;
      b:byte;
      changed,err:boolean;
  begin
    xloaded:=-1;
    reset(MBasesFile);
    prt('Begin editing at which? (1-'+cstr(MaxMBases)+') : '); inu(ii);
    c:=' ';
    if ((ii>0) and (ii<=MaxMBases)) then begin
      while (c<>'Q') and (not hangup) do begin
        if (xloaded<>ii) then begin
          seek(MBasesFile,ii-1); read(MBasesFile,memboard);
          xloaded:=ii;
        end;
        with memboard do
          repeat
            if (c<>'?') then begin
              abort:=FALSE; next:=FALSE; mciallowed:=FALSE;
              cls;
              printacr('^5Message base #'+cstr(ii)+' of '+cstr(MaxMBases) + ^M^J);

              printacr('^11. Name        : ^5' + name);
              printacr('^12. Filename    : ^5' + filename);
              case mbtype of
                0:s:='Local';
                1:s:='EchoMail';
                3:s:='QwkMail';
              end;
              printacr('^13. Base type   : ^5' + s);
              if (mbtype in [0, 3]) then s:='Unused' else s:=msgpath;
              printacr('^1   Message path: ^5' + s);
              mciallowed := FALSE;
              printacr('^14. ACS req.    : ^5' + acs);
              printacr('^15. Post/MCI ACS: ^5' + postacs+' / '+mciacs);
              printacr('^16. Sysop ACS   : ^5' + sysopacs);
              mciallowed := TRUE;
              printacr('^17. Max Mess    : ^5' + cstr(maxmsgs));
              case anonymous of
              atyes:s:='Yes';
               atno:s:='No';
           atforced:s:='Forced';
         atdearabby:s:='Dear Abby';
          atanyname:s:='Any Name';
              end;
              printacr('^18. Anonymous   : ^5' + s);
              printacr('^19. Password    : ^5' + password);
              if (mbtype in [0, 3]) then
                s:='Unused'
              else
                begin
                  s := cstr(General.aka[aka].zone) + ':' +
                       cstr(General.aka[aka].net)  + '/' +
                       cstr(General.aka[aka].node);
                  if (General.aka[aka].point > 0) then
                    s := s + '.' + cstr(General.aka[aka].point);
                end;

              printacr('^1N. Net Address : ^5' + s);
              s:='^1Text=^' + cstr(text_color) + cstr(text_color)+
                 '^1, Quote=^' + cstr(quote_color)+cstr(quote_color)+
                 '^1, Tear=^' + cstr(tear_color)+cstr(tear_color)+
                 '^1, Origin=^' + cstr(origin_color)+cstr(origin_color);
              printacr('^1C. Colors      : ^5' + s);
              if (mbtype in [0, 3]) then
                s := 'Unused'
              else
                s := netflags(memboard);
              printacr('^1M. Mail flags  : ^5' + s);
              if (mbtype = 0) then s:='Unused' else s:=origin;
              printacr('^1O. Origin line : ^5' + s);
              printacr('^1T. Toggles     : ^5' + flagstate(memboard));
              printacr('^1P. QWK Index   : ^5' + cstr(QWKIndex));
              printacr('^1Q. Quit');
            end;
            mciallowed:=TRUE;
            prt(^M^J'Edit menu (?=help) : ');
            onek(c,^M'?[]FIJLQ123456789CMNOTP'); nl;
            case c of
              '1':begin
                    prt('New name: ');
                    inputwnwc(name,40,changed);
                  end;
              '2':begin
                    getbrdspec(s1);
                    prt('New filename: '); mpl(8); input(s,8); s:=sqoutsp(s);
                    if (pos('.',s)>0) then filename:=copy(s,1,pos('.',s)-1);
                    if (s<>'') then begin
                      filename:=s;
                      getbrdspec(s2);
                      if exist(s1) and (not exist(s2)) then begin
                        print(^M^J'Old HDR/DAT filenames: "'+copy(s1,1,pos('.',s1)-1)+'.*"');
                        print('New HDR/DAT filenames: "'+copy(s2,1,pos('.',s2)-1)+'.*"'^M^J);

                        if pynq('Rename old filenames to new filenames? ') then begin
                          s3:=s1;
                          err:=FALSE;
                          assign(f,s1);
                          rename(f,s2);
                          if (ioresult<>0) then begin
                            print('error renaming *.HDR filename.');
                            err:=TRUE;
                          end;
                          s1:=copy(s3,1,pos('.',s3)-1)+'.DAT';
                          s2:=copy(s2,1,pos('.',s2)-1)+'.DAT';
                          assign(f,s1);
                          rename(f,s2);
                          if (ioresult<>0) then begin
                            print('error renaming *.DAT filename.');
                            err:=TRUE;
                          end;
                          s1:=copy(s3,1,pos('.',s3)-1)+'.SCN';
                          s2:=copy(s2,1,pos('.',s2)-1)+'.SCN';
                          assign(f,s1);
                          rename(f,s2);
                          if (ioresult<>0) then begin
                            print('error renaming *.SCN filename.');
                            err:=TRUE;
                          end;
                          if err then pausescr(FALSE);
                        end;
                      end;
                    end;
                  end;
              '3':begin
                    prt('[L]ocal [E]choMail [G]roupMail [Q]wkMail: ');
                    onek(c,'LEGQ'^M);
                    case c of
                      'L':mbtype:=0;
                      'E':mbtype:=1;
                      'G':mbtype:=2;
                      'Q':mbtype:=3;
                    end;
                    c := #0;
                    if (mbtype = 1) then begin
                      prompt(^M^J'Current message path: ');
                      if (msgpath<>'') then print(msgpath)
                         else print('*NONE*');
                      s:=General.defechopath+filename+'\';
                      if msgpath<>'' then s:=msgpath;
                      print(^M^J'Press [Enter] to use default of '+s);
                      inputpath(^M^J'Enter new message path',s);
                      msgpath:=s;
                      if (not existdir(msgpath)) then begin
                        print(^M^J'"'+msgpath+'" does not exist.');
                        if (pynq('Create message directory now? ')) then begin
                          mkdir(copy(msgpath,1,length(msgpath)-1));
                          if (ioresult<>0) then begin
                            print('errors creating directory.');
                            pausescr(FALSE);
                          end;
                        end;
                      end else begin
                        print(^M^J'Note: "'+msgpath+'" already exists.'^M^J);
                        pausescr(FALSE);
                      end;
                    end;
                  end;
              '4':begin
                    prt('New ACS: '); mpl(20);
                    inputwn(acs,20,changed);
                  end;
              '5':begin
                    prt('New Post ACS: '); mpl(20);
                    inputwn(postacs,20,changed);
                    prt('New MCI ACS: '); mpl(20);
                    inputwn(mciacs,20,changed);
                  end;
              '6':begin
                    prt('New SysOp ACS: '); mpl(20);
                    inputwn(sysopacs,20,changed);
                  end;
              '7':begin
                    prt('Max messages: '); mpl(5); inu(i);
                    if (not badini) then maxmsgs:=i;
                  end;
              '8':begin
                    prt('Anonymous types:'^M^J^M^J);
                    lcmds(40,3,'Yes, anonymous allowed, selectively','');
                    lcmds(40,3,'No, anonymous not allowed','');
                    lcmds(40,3,'Forced anonymous','');
                    lcmds(40,3,'Dear Abby','');
                    lcmds(40,3,'Any Name','');
                    prt(^M^J'New Anon. type (YNFDA) : ');
                    onek(c,'QYNFDA'^M);
                    if (pos(c,'YNFDA')<>0) then begin
                      case c of
                        'Y':anonymous:=atyes;
                        'N':anonymous:=atno;
                        'F':anonymous:=atforced;
                        'D':anonymous:=atdearabby;
                        'A':anonymous:=atanyname;
                      end;
                    end;
                  end;
              '9':begin
                    prt('New PW: ');
                    mpl(20); inputwn1(password,20,'u',changed);
                  end;
              'N':if (mbtype in [1, 2]) then begin
                      UserColor(1);
                      for i := 0 to 19 do
                         if (General.aka[i].net > 0) then
                           begin
                             s := cstr(General.aka[i].zone) + ':' +
                                  cstr(General.aka[i].net)  + '/' +
                                  cstr(General.aka[i].node);
                             if (General.aka[i].point > 0) then
                               s := s + '.' + cstr(General.aka[i].point);
                             printacr(mn(i+1,2)+'. ' + s);
                           end;
                      prt(^M^J'Use which aka: '); mpl(5); inu(i);
                      if (i>0) and (i < 21) then aka := i-1;
                  end;
              'C':begin
                    incolor('standard text',text_color);
                    incolor('quoted text',quote_color);
                    incolor('tear line',tear_color);
                    incolor('origin line',origin_color);
                  end;
              'T':repeat
                    prt('Flags ['+flagstate(memboard)+'] [?]Help [Q]uit :');
                    onek(c1,'RPUAF?Q'^M);
                    case c1 of
                      ^M,'Q': ;
                      '?':begin
                            nl;
                            lcmds(15,3,'Real names','AFilter ANSI/8-bit ASCII');
                            lcmds(15,3,'Unhidden','Private msgs allowed');
                            lcmds(15,3,'Force read','');
                            nl
                          end;
                      'R':if (mbrealname in mbstat) then mbstat:=mbstat-[mbrealname]
                              else mbstat:=mbstat+[mbrealname];
                      'P':if (mbprivate in mbstat) then mbstat:=mbstat-[mbprivate]
                              else mbstat:=mbstat+[mbprivate];
                      'U':if (mbunhidden in mbstat) then mbstat:=mbstat-[mbunhidden]
                              else mbstat:=mbstat+[mbunhidden];
                      'A':if (mbfilter in mbstat) then mbstat:=mbstat-[mbfilter]
                              else mbstat:=mbstat+[mbfilter];
                      'F':if (mbforceread in mbstat) then mbstat:=mbstat-[mbforceread]
                              else mbstat:=mbstat+[mbforceread];
                    end;
                  until ((c1 in [^M,'Q']) or (hangup));
              'P':begin
                    prt('Permanent Index: '); mpl(5); inu(i);
                    if (not badini) then QWKIndex := i;
                  end;
              'M':if (mbtype in [1, 2]) then repeat
                      prt('Flags ['+netflags(memboard)+'] [?]Help [Q]uit :');
                      onek(c1,'IKSOCBMT?Q'^M);
                      case c1 of
                        ^M,'Q': ;
                        '?':begin
                              nl;
                              lcmds(22,3,'Kludge line strip','SEEN-BY line strip');
                              lcmds(22,3,'Origin line strip','Tear/origin line add');
                              lcmds(22,3,'Internet flag','');
                              nl;
                            end;
                        'K':if (mbskludge in mbstat) then
                              mbstat:=mbstat-[mbskludge]
                              else mbstat:=mbstat+[mbskludge];
                        'S':if (mbsseenby in mbstat) then
                              mbstat:=mbstat-[mbsseenby]
                              else mbstat:=mbstat+[mbsseenby];
                        'O':if (mbsorigin in mbstat) then
                              mbstat:=mbstat-[mbsorigin]
                              else mbstat:=mbstat+[mbsorigin];
                        'T':if (mbaddtear in mbstat) then
                              mbstat:=mbstat-[mbaddtear]
                              else mbstat:=mbstat+[mbaddtear];
                        'I':begin
                              if (mbinternet in mbstat) then mbstat:=mbstat-[mbinternet]
                                else mbstat:=mbstat+[mbinternet];
                            end;
                      end;
                    until ((c1 in [^M,'Q']) or (hangup));
              'O':if (mbtype > 0) then begin
                    print('Enter new origin line');
                    prt(':'); mpl(50); inputwn1(origin,50,'',changed);
                  end;
              'R':if (mbrealname in mbstat) then mbstat:=mbstat-[mbrealname]
                      else mbstat:=mbstat+[mbrealname];
{$IFDEF MSDOS}
              'P':if (mbprivate in mbstat) then mbstat:=mbstat-[mbprivate]
                      else mbstat:=mbstat+[mbprivate];
{$ENDIF}					  
{$IFDEF WIN32}
  // REETODO This 'P' and possibly others appear to be bad copypasta from the 'T' case above
{$ENDIF}
              'U':if (mbunhidden in mbstat) then mbstat:=mbstat-[mbunhidden]
                      else mbstat:=mbstat+[mbunhidden];
              'A':if (mbfilter in mbstat) then mbstat:=mbstat-[mbfilter]
                      else mbstat:=mbstat+[mbfilter];
              '[':if (ii>1) then dec(ii) else c:=' ';
              ']':if (ii<MaxMBases) then inc(ii) else c:=' ';
              'F':if (ii<>1) then ii:=1 else c:=' ';
              'J':begin
                    prt('Jump to entry: ');
                    input(s,3);
                    if (value(s)>=1) and (value(s)<=MaxMBases) then ii:=value(s) else c:=' ';
                  end;
              'L':if (ii<>MaxMBases) then ii:=MaxMBases else c:=' ';
              '?':begin
                    print(' #:Modify item   <CR>Redisplay screen');
                    lcmds(15,3,'[Back entry',']Forward entry');
                    lcmds(15,3,'Jump to entry','First entry in list');
                    lcmds(15,3,'Quit and save','Last entry in list');
                  end;
            end;
          until (pos(c,'Q[]FJL')<>0) or (hangup);
        seek(MBasesFile,xloaded-1); write(MBasesFile,memboard);
      end;
    end;
    close(MBasesFile);
    Lasterror := IOResult;
  end;

  procedure bepi;
  var i,j:integer;
  begin
    prt('Move which message base? (1-'+cstr(MaxMBases)+') : '); inu(i);
    if ((not badini) and (i>=1) and (i<=MaxMBases)) then begin
      prt('Move before which message base? (1-'+cstr(MaxMBases+1)+') : ');
      inu(j);
      if ((not badini) and (j>=1) and (j<=MaxMBases+1) and
          (j<>i) and (j<>i+1)) then begin
        nl;
        bep(i,j);
      end;
    end;
  end;

  function anont(a:anontyp):string;
  begin
    case a of
      atyes     :anont:='Y';
      atno      :anont:='N';
      atforced  :anont:='F';
      atdearabby:anont:='D';
      atanyname :anont:='A';
    end;
  end;

begin
  c:=#0;
  repeat
    if (c<>'?') then begin
      cls; abort:=FALSE; next:=FALSE;
      s:='^0Num '+seperator+'Base name                   '+seperator;
      case ltype of
        1:begin
            printacr(s+'Flag '+seperator+'ACS       '+seperator+'Post ACS '+
              seperator+'MCI ACS  '+seperator+'MaxM  '+seperator+'A');
            s:='=====:==========:=========:=========:======:=';
          end;
        2:begin
            printacr(s+'Address    '+seperator+'Message path');
            s:='===========:=================================';
          end;
      end;
      printacr('^4====:============================:'+s);
(*
NNN:Base name                    :Flag :ACS       :Post ACS  :MCI ACS   :MaxM:An
===:=============================:=====:==========:==========:==========:====:==

NNN:Base name                    :Address    :Message path
===:=============================:===========:=================================
*)
      ii:=1;
      mciallowed := FALSE;
      reset(MBasesFile);
      mciallowed := FALSE;
      AllowContinue := TRUE;
      while (ii<=MaxMBases) and (not abort) and (not hangup) do begin
        seek(MBasesFile,ii-1); read(MBasesFile,memboard);
        s:='^0' + mn(ii,4)+' '+'^5'+mln(memboard.name,28)+' ^3';
        with memboard do begin
          case ltype of
            1:s:=s+copy('LEGQ',mbtype+1,1)+flagstate(memboard)+' ^9'+
                mln(acs,10)+' '+mln(postacs,9)+' '+mln(mciacs,9)+' ^3'+
                mn(maxmsgs,5)+' '+anont(anonymous);
            2:begin
                if (mbtype in [0, 3]) then
                  s1 := 'None'
                else
                  begin
                    s1 := cstr(General.aka[aka].zone) + ':' +
                          cstr(General.aka[aka].net)  + '/' +
                          cstr(General.aka[aka].node);
                    if (General.aka[aka].point > 0) then
                      s1 := s1 + '.' + cstr(General.aka[aka].point);
                  end;
                  s := s + mln(s1, 11) + ' ' + msgpath;
              end;
          end;
          printacr(s);
          inc(ii);
        end;
      end;
      mciallowed := TRUE;
      close(MBasesFile);
      readboard:=-1; {loadboard(1);  not needed }
      mciallowed := TRUE;
      AllowContinue := FALSE;
    end;

    prt(^M^J'Message base editor (?=help) : ');
    onek(c,'QDIMPT?'^M);
    case c of
      '?':begin
            print(^M^J'<CR>Redisplay screen');
            lcmds(12,3,'Delete base','Insert base');
            lcmds(12,3,'Modify base','Position base');
            lcmds(12,3,'Quit','Toggle display format');
          end;
      'D':begin
            prt('Board number to delete? (1-'+cstr(MaxMBases)+') : '); inu(ii);
            if ((not badini) and (ii>=1) and (ii<=MaxMBases)) then begin
              readboard:=-1; loadboard(ii);
              s:=general.msgpath+memboard.filename;
              print(^M^J'Message base: ^5' + memboard.name);
              if pynq('Delete this? ') then begin
                if (memboard.mbtype in [1, 2]) {and (existdir(memboard.msgpath))} and
                   pynq('Remove directory '+memboard.msgpath+ ' ? ') then
                    purgedir(memboard.msgpath, TRUE);
                sysoplog('* Deleted message base: '+memboard.name);
                bed(ii);
                if (pynq('Delete message files? ')) then
                  begin
                    kill(s+'.DAT');
                    kill(s+'.HDR');
                    kill(s+'.SCN');
                  end;
              end;
            end;
          end;
      'I':begin
            prt('Board number to insert before? (1-'+cstr(MaxMBases+1)+') : '); inu(ii);
            if (not badini) and (ii>0) and (ii<=MaxMBases+1) then
              begin
                sysoplog('* Created message base');
                bei(ii);
              end;
          end;
      'M':bem;
      'P':bepi;
      'T':ltype:=ltype mod 2 + 1;
    end;
  until ((c='Q') or (hangup));
  newcomptables;

  if ((board<1) or (board>MaxMBases)) then board:=1;
  readboard:=-1; loadboard(board);
  Lasterror := IOResult;
end;

end.

