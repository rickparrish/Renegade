{$A+,B-,D-,E-,F+,I+,L-,N-,O+,R-,S+,V-}

{ Text file base editor }

unit sysop5;

interface

uses crt, dos, overlay, common;

procedure tfileedit;

implementation

var f1:file of byte;

procedure tfileedit;
var b,b1:tfilerec;
    gfil:file of tfilerec;
    s:astr;
    ok,done,changed:boolean;
    gftit:array[1..150] of record
      tit:string[40];
      filen:string[12];
      arn:integer;
      gfile:boolean;
      acs,ulacs:acstring;
      gdate:string[10];
    end;
    gfs:array[0..100] of record
      tit:string[40];
      arn:integer;
      acs,ulacs:acstring;
      gdate:string[10];
    end;
    numgentrys,numgsecs,lgftn,numgft:integer;
    c1,c2,c3,c4:integer;
    s1,s2,s3,s4:astr;
    ch:char;
    c:char;
    bb:byte;
    i,i2:integer;

function align(const fn:astr):astr;
var
  f,e:astr;
  c,c1:integer;
begin
  c:=pos('.',fn);
  if c=0 then begin
    f:=fn; e:='   ';
  end else begin
    f:=copy(fn,1,c-1); e:=copy(fn,c+1,3);
  end;
  while length(f)<8 do f:=f+' ';
  while length(e)<3 do e:=e+' ';
  if length(f)>8 then f:=copy(f,1,8);
  if length(e)>3 then e:=copy(e,1,3);
  c:=pos('*',f); if c<>0 then for c1:=c to 8 do f[c1]:='?';
  c:=pos('*',e); if c<>0 then for c1:=c to 3 do e[c1]:='?';
  c:=pos(' ',f); if c<>0 then for c1:=c to 8 do f[c1]:=' ';
  c:=pos(' ',e); if c<>0 then for c1:=c to 3 do e[c1]:=' ';
  align:=f+'.'+e;
end;

  procedure gettit(n:integer);
  var r:integer; b:tfilerec;
  begin
    numgft:=0;
    r:=n+1;
    if r<=numgentrys then begin
      seek(gfil,r); read(gfil,b);
      while (r<=numgentrys) and (b.filen[1]<>#1) do begin
        inc(numgft);
        gftit[numgft].tit:=b.title;
        gftit[numgft].filen:=b.filen;
        gftit[numgft].arn:=r;
        gftit[numgft].gfile:=TRUE;
        gftit[numgft].acs:=b.acs;
        gftit[numgft].ulacs:=b.ulacs;
        gftit[numgft].gdate:=b.gdate;
        inc(r);
        if (r<=numgentrys) then begin seek(gfil,r); read(gfil,b); end;
      end;
    end;
    gftit[numgft+1].arn:=r;
  end;

  procedure getsec;
  var r:integer; b:tfilerec;
  begin
    numgsecs:=0;
    gfs[0].tit:='Main Section';
    gfs[0].arn:=0;
    for r:=1 to numgentrys do begin
      seek(gfil,r); read(gfil,b);
      if b.filen[1]=#1 then begin
        inc(numgsecs);
        gfs[numgsecs].tit:=b.title;
        gfs[numgsecs].arn:=r;
        gfs[numgsecs].acs:=b.acs;
        gfs[numgsecs].ulacs:=b.ulacs;
        gfs[numgsecs].gdate:=b.gdate;
      end;
    end;
    gfs[numgsecs+1].arn:=numgentrys+1;
  end;

  procedure lgft;
  var b:tfilerec;
      s:astr;
      i:integer;

  begin
    i:=1;
    if numgft=0 then print('** No text files **')
    else begin
      abort:=FALSE; next:=FALSE;
(*
NNN:Description                             :Filename    :SL :AR:Date
===:========================================:============:===:==:========

NNN:Description                             :Filename    :Date    :ACS
===:========================================:============:========:==========
*)
      printacr(#3#0+'NNN'+seperator+'Description                             '+
               seperator+'Filename    '+seperator+'Date    '+seperator+'ACS');
      printacr(#3#4+'===:========================================:============:========:==========');
      while (i<=numgft) and (not abort) do begin
        seek(gfil,gftit[i].arn); read(gfil,b);
        s:=#3#0+mn(i,3)+' '+#3#3+mln(b.title,40)+' '+#3#3+align(b.filen)+' '+
           mln(b.gdate,10)+' '+mln(b.acs,10);
        printacr(s);
        inc(i);
      end;
    end;
  end;

  procedure gfed;
  var sel,i,j,k:integer;
  begin
    prt('Section number to delete? (1-'+cstr(numgsecs)+') : '); inu(sel);
    if ((sel>=1) and (sel<=numgsecs)) then begin
      nl;
      prompt(#3#3+gfs[sel].tit);
      if pynq('   Delete it? ') then begin
        if sel=numgsecs then j:=numgentrys+1 else j:=gfs[sel+1].arn;
        i:=(j-gfs[sel].arn);
        for k:=j to numgentrys do begin
          seek(gfil,k); read(gfil,b);
          seek(gfil,k-i); write(gfil,b);
        end;
        seek(gfil,0);
        dec(numgentrys,i); b.gdaten:=numgentrys;
        write(gfil,b);
      end;
    end
    else print('Illegal section number.');
  end;

  procedure gfei;
  var
    sel,i:integer;
  begin
    prt('Section number to insert before? (1-'+cstr(numgsecs+1)+') : '); inu(sel);
    if (sel>=1) and (sel<=(numgsecs+1)) then begin
      if (sel<=numgsecs) then sel:=gfs[sel].arn else sel:=numgentrys+1;
      b.gdate:=date;
      b.gdaten:=daynum(date);
      b.tbstat:=[];
      prt('Section title: '); inputwc(b.title,40);
      prt('Section ACS: '); inputl(b.acs,20);

      b.filen:=#1#0#0#0#0#0;
      for i:=numgentrys downto sel do begin
        seek(gfil,i); read(gfil,b1);
        seek(gfil,i+1); write(gfil,b1);
      end;
      seek(gfil,sel); write(gfil,b);
      inc(numgentrys); b.gdaten:=numgentrys;
      seek(gfil,0); write(gfil,b);
    end
    else print('Illegal section number.');
  end;

  procedure gfem;
  var
    ii:integer;

    procedure gfedi(i:integer);
    var j:integer;
    begin
      i:=gftit[i].arn;
      for j:=i+1 to numgentrys do begin
        seek(gfil,j); read(gfil,b);
        seek(gfil,j-1); write(gfil,b);
      end;
      seek(gfil,0); read(gfil,b);
      dec(b.gdaten);
      seek(gfil,0); write(gfil,b);
      dec(numgentrys);
      getsec;
    end;

    procedure gfeii(i:integer; b:tfilerec);
    var j,k:integer;
    begin
      j:=gftit[i].arn;
      for k:=numgentrys downto j do begin
        seek(gfil,k); read(gfil,b1);
        seek(gfil,k+1); write(gfil,b1);
      end;

      seek(gfil,j); write(gfil,b);
      inc(numgentrys);
      seek(gfil,0); read(gfil,b);
      inc(b.gdaten);
      seek(gfil,0); write(gfil,b);
      getsec;

      seek(gfil,gfs[ii].arn); read(gfil,b);
      b.gdate:=date;
      b.gdaten:=daynum(date);
      seek(gfil,gfs[ii].arn); write(gfil,b);          {* update section date *}
      getsec;
    end;

    procedure gfepi;
    var
      i,j:integer;
    begin
      prt('Move which entry? (1-'+cstr(numgft)+') : '); inu(i);
      if (i>=1) and (i<=numgft) then begin
        prt('Move before which entry? (1-'+cstr(numgft+1)+') : '); inu(j);
        if (j>=1) and (j<=numgft+1) and (j<>i) and (j<>i+1) then begin
          seek(gfil,gftit[i].arn); read(gfil,b);
          gfeii(j,b);
          if j>i then gfedi(i) else gfedi(i+1);
        end;
      end;
    end;

  begin
    prt('Begin editing at which? (1-'+cstr(numgsecs)+') : '); inu(ii);
    c:=' ';
    if (ii>=1) and (ii<=numgsecs) then begin
      getsec;
      while (c<>'Q') and (not hangup) do begin
        repeat
          if c<>'?' then begin
            cls;
            print('Text file section #'+cstr(ii)+' of '+cstr(numgsecs));
            nl;
            abort:=FALSE; next:=FALSE;
            printacr(#3#1'1. Section title: '+#3#3+gfs[ii].tit);
            printacr(#3#1'2. Section ACS  : "'+gfs[ii].acs+'"');
            printacr(#3#1'3. Upload ACS   : "'+gfs[ii].ulacs+'"');
            printacr(#3#1'4. Section date : '+gfs[ii].gdate);
            nl;
            gettit(gfs[ii].arn);
            lgft;
          end;
          nl;
          prt('Text file edit (?=help) : ');
          onek(c,'Q?[]DFIJLMPT1234'^M);
          nl;
          case c of
            '?':begin
                  print(#3#1+'<CR>Redisplay screen');
                  lcmds(25,3,'[Back section',']Forward section');
                  lcmds(25,3,'Jump to section','First section in list');
                  lcmds(25,3,'Quit and save','Last section in list');
                  lcmds(25,3,'1Title change','2Section ACS change');
                  lcmds(25,3,'3Upload ACS change','4Date change');
                  lcmds(25,3,'Insert text file','Delete text file');
                  lcmds(25,3,'Position text file','Modify individual entries');
                  lcmds(25,3,'Type file to screen','');
                end;
            'M':begin
                  prt('Begin editing at which? (1-'+cstr(numgft)+') : '); ini(bb);
                  if (not badini) and (bb>=1) and (bb<=numgft) then begin
                    i2:=bb;
                    while (c<>'Q') and (not hangup) do begin
                      repeat
                        if (c<>'?') then begin
                          cls;
                          print(#3#1'Text file section #'+cstr(ii)+' of '+cstr(numgsecs));
                          print('Text file #'+cstr(i2)+' of '+cstr(numgft));
                          nl;
                          with gftit[i2] do begin
                            print('1. Title       : '+#3#3+tit);
                            print(#3#1'2. Filename    : '+filen);
                            print(#3#1'3. ACS required: "'+acs+'"');
                            print('4. Date        : '+gdate);
                          end;
                        end;
                        nl;
                        prt('Edit menu: (?=help) : ');
                        onek(c,'Q?1234[]'^M);
                        nl;
                        case c of
                          '?':begin
                                print(#3#1' #:Modify item  <CR>Redisplay screen');
                                lcmds(14,3,'[Back text file',']Forward text file');
                                lcmds(14,3,'Quit and save','');
                              end;
                          '1'..'4':begin
                                seek(gfil,gftit[i2].arn); read(gfil,b);
                                case c of
                                  '1':begin
                                        prt('New title: ');
                                        inputwnwc(b.title,40,changed);
                                      end;
                                  '2':begin
                                        prt('New filename: ');
                                        input(b.filen,12);
                                      end;
                                  '3':begin
                                        prt('New ACS: ');
                                        inputwn(b.acs,20,changed);
                                      end;
                                  '4':begin
                                        prt('New date: '); input(s,10);
                                        if (s<>'') and (daynum(s)>0) then begin
                                          b.gdate:=s;
                                          b.gdaten:=daynum(s);
                                        end;
                                      end;
                                end;
                                seek(gfil,gftit[i2].arn); write(gfil,b);
                                gettit(gfs[ii].arn);
                              end;
                          '[':if i2>1 then dec(i2) else c:=' ';
                          ']':if i2<numgft then inc(i2) else c:=' ';
                        end;
                      until (c in ['Q','[',']']) or (hangup);
                    end;
                  end;
                  c:=' ';
                end;
            'D':begin
                  gettit(gfs[ii].arn);
                  prt('Delete which? (1-'+cstr(numgft)+') : '); inu(c1);
                  if (c1>=1) and (c1<=(numgft)) then begin
                    nl;
                    prompt(#3#3+gftit[c1].tit);
                    if pynq('   Delete it? ') then begin
                      seek(gfil,gftit[c1].arn); read(gfil,b);
                      assign(f1,general.textpath+b.filen);
                      {$I-} reset(f1); {$I+}
                      if ioresult=0 then begin
                        close(f1);
                        if pynq('"'+b.filen+'" - Erase file too? ') then erase(f1);
                      end;

                      gfedi(c1);
                    end;
                  end;
                end;
            'I':begin
                  gettit(gfs[ii].arn);
                  prt('Insert before which (1-'+cstr(numgft+1)+') ['+
                      cstr(numgft+1)+'] : ');
                  input(s1,3);
                  if (s1='') then c1:=numgft+1 else c1:=value(s1);
                  if (c1>=1) and (c1<=numgft+1) then begin
                    nl;
                    prt('Enter filename : ');
                    mpl(12); input(b.filen,12);

                    ok:=TRUE;
                    if b.filen='' then ok:=FALSE;
                    if pos('.',b.filen)<>0 then begin
                      ok:=FALSE;
                      assign(f1,general.textpath+b.filen);
                      {$I-} reset(f1); {$I+}

                      ok:=(ioresult=0);
                      if ok then close(f1);
                    end;

                    if ok then begin
                      nl;
                      b.gdate:=date;
                      b.gdaten:=daynum(date);
                      b.tbstat:=[];
                      prt('Enter title : '); inputwc(b.title,40);
                      prt('Enter ACS : '); inputl(b.acs,20);

                      gfeii(c1,b);

                      general.tfiledate:=date;
                      savegeneral(FALSE);
                    end else begin
                      print('Illegal filename.');
                      pausescr;
                    end;
                  end;
                end;
            'P':gfepi;
            'T':begin
                  gettit(gfs[ii].arn);
                  prt('Type which? (1-'+cstr(numgft)+') : '); inu(c1);
                  if (c1>=1) and (c1<=(numgft)) then begin
                    seek(gfil,gftit[c1].arn); read(gfil,b);
                    nofile:=FALSE;
                    if pos('.',b.filen)=0 then
                      printf(general.textpath+b.filen)
                    else begin
                      assign(f1,general.textpath+b.filen);
                      {$I-} reset(f1); {$I+}
                      nofile:=(ioresult<>0);
                      if (not nofile) then begin
                        close(f1);
                        pfl(general.textpath+b.filen);
                      end;
                    end;
                    if nofile then print('File not found!');
                    pausescr;
                  end;
                end;
            '1'..'4':begin
                  seek(gfil,gfs[ii].arn); read(gfil,b);
                  case c of
                    '1':begin
                          prt('New title: ');
                          inputwnwc(b.title,40,changed);
                        end;
                    '2':begin
                          prt('New ACS: ');
                          inputwn(b.acs,20,changed);
                        end;
                    '3':begin
                          prt('New Upload ACS: ');
                          inputwn(b.ulacs,20,changed);
                        end;
                    '4':begin
                          prt('New date: '); mpl(8); input(s,10);
                          if (daynum(s)>0) then begin
                            b.gdate:=s;
                            b.gdaten:=daynum(s);
                          end;
                        end;
                  end;
                  seek(gfil,gfs[ii].arn); write(gfil,b);
                  getsec;
                end;
            '[':if (ii>1) then dec(ii) else c:=' ';
            ']':if (ii<numgsecs) then inc(ii) else c:=' ';
            'F':if (ii<>1) then ii:=1 else c:=' ';
            'J':begin
                  prt('Jump to entry: ');
                  input(s,3);
                  if ((value(s)>=1) and (value(s)<=numgsecs)) then
                    ii:=value(s) else c:=' ';
                end;
            'L':if (ii<>numgsecs) then ii:=numgsecs else c:=' ';
          end;
        until ((c in ['Q','[',']','F','J','L']) or (hangup));
      end;
    end;
  end;

begin
  assign(gfil,general.datapath+'tbases.dat');
  {$I-} reset(gfil); {$I+}
  if (ioresult = 2) then begin
    rewrite(gfil);
    b.gdaten:=0;
    write(gfil,b);
  end;
  seek(gfil,0); read(gfil,b);
  numgentrys:=b.gdaten;

  repeat
    if (ch<>'?') then begin
      getsec;
      cls; done:=FALSE; abort:=FALSE; next:=FALSE;

(*
NNN:Section Name                            :SL :AR:Date
===:========================================:===:==:========

NNN:Section Name                            :Date    :ACS       :UL ACS
===:========================================:========:==========:==========
*)

      printacr(#3#0+'NNN'+seperator+'Section Name                            '+
               seperator+'Date    '+seperator+'ACS       '+seperator+'UL ACS');
      printacr(#3#4+'===:========================================:========:==========:==========');
      i:=1;
      while (i<=numgsecs) and (not abort) do
        with gfs[i] do begin
          s:=#3#0+mn(i,3)+' '+#3#3+mln(tit,40)+' '+#3#3+mln(gdate,10)+' '+
             #3#9+mln(acs,10)+' '+mln(ulacs,10);
          printacr(s);
          inc(i);
        end;
    end;
    nl;
    prt('Text-file base editor (?=help) : ');
    onek(ch,'QDIM?'^M);
    case ch of
      '?':begin
            nl;
            print(#3#1'<CR>Redisplay screen');
            lcmds(12,3,'Delete base','Insert base');
            lcmds(12,3,'Modify base','Quit');
          end;
      'Q':done:=TRUE;
      'D':gfed;
      'I':gfei;
      'M':gfem;
    end;
  until (done) or (hangup);
  close(gfil);
end;

end.
