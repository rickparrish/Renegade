{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Protocol Editor }

unit sysop1;

interface

uses crt, dos, overlay, common;

procedure ee_help;
procedure exproedit;

implementation

uses file1, menus2;

var menuchanged:boolean;
    x:integer;

procedure ee_help;
begin
  print(' #:Modify item   <CR>Redisplay screen');
  lcmds(15,3,'[Back entry',']Forward entry');
  lcmds(15,3,'Jump to entry','First entry in list');
  lcmds(15,3,'Quit and save','Last entry in list');
end;

procedure exproedit;
var
  ii,xloaded:integer;
  c:char;

  procedure xed(i:integer);
  var x:integer;
  begin
    if (i>=0) and (i<=filesize(xf)-1) then begin
      if (i>=0) and (i<filesize(xf)-1) then
        for x:=i to filesize(xf)-2 do begin
          seek(xf,x+1); read(xf,protocol);
          seek(xf,x); write(xf,protocol);
        end;
      seek(xf,filesize(xf)-1); truncate(xf);
    end;
    Lasterror := IOResult;
  end;

  procedure xei(i:integer);
  var x:integer;
  begin
    if (i>=0) and (i<=filesize(xf)) and (filesize(xf)<maxprotocols) then begin
      for x:=filesize(xf)-1 downto i do begin
        seek(xf,x); read(xf,protocol);
        write(xf,protocol);  (* to next record *)
      end;
      with protocol do begin
        xbstat:=[xbxferokcode];
        ckeys:='!';
        descr:='^4(^3!^4) New Protocol';
        acs:='';
        templog:='';
        uloadlog:=''; dloadlog:='';
        ulcmd:='QUIT'; dlcmd:='QUIT';
        for x:=1 to 6 do begin ulcode[x]:=''; dlcode[x]:=''; end;
        envcmd:='';
        dlflist:='';
        maxchrs:=128;
        logpf:=0; logps:=0;
        for x:=1 to 11 do res[x]:=0;
      end;
      seek(xf,i); write(xf,protocol);
    end;
    Lasterror := IOResult;
  end;

  function udq:integer;
  var c:char;
  begin
    prt('What type? (U)pload (D)ownload : ');
    onek(c,'DU'); nl;
    if (c='U') then udq:=1 else udq:=2;
  end;

  procedure xem;
  var s:astr;
      i,j,ii:integer;
      c:char;
      changed:boolean;

    function cfip(pt:integer; s:astr):astr;
    begin
      if (pt<1) or (pt>5) then cfip:=s else cfip:='';
    end;

    function nnon(const s:astr):astr;
    begin
      if (s<>'') then nnon:='"'+s+'"' else nnon:='*None*';
    end;

  begin
    xloaded:=-1;
    prt('Begin editing at which? (0-'+cstr(filesize(xf)-1)+') : '); inu(ii);
    c:=' ';
    if (ii>=0) and (ii<=filesize(xf)-1) then begin
      while (c<>'Q') and (not hangup) do begin
        if (xloaded<>ii) then begin
          seek(xf,ii); read(xf,protocol);
          xloaded:=ii;
        end;
        with protocol do
          repeat
            if (c<>'?') then begin
              cls;
              abort:=FALSE; next:=FALSE; i:=1;
              while ((i<=15) and (not abort)) do begin
                case i of
                  1:print('^5Protocol #'+cstr(ii)+' of '+cstr(filesize(xf)-1) + ^M^J);
                  2:print('^1!. Type/protocl:'+
                      aonoff(xbactive in xbstat,'Active','INACTIVE')+' - '+
                      aonoff(xbisbatch in xbstat,'Batch','Single')+
                      aonoff(xbisresume in xbstat,' - Resume','')+
                      aonoff(xbbidirectional in xbstat,' - Bidirectional','')+
                      aonoff(xbreliable in xbstat,' - Reliable only','')
                      );
                  3:print('1. Keys/descrip:"'+ckeys+'" / "'+descr+'^1"');
                  4:print('2. ACS required: "'+acs+'"');
                  5:print('3. Temp. log   : '+nnon(templog));
                  6:print('4. <U>L log    : '+nnon(uloadlog));
                  7:print('   <D>L log    : '+nnon(dloadlog));
                  8:print('5. <U>L command: '+nnon(ulcmd));
                  9:print('   <D>L command: '+nnon(dlcmd));
                  10:print('6. Codes mean  :'+aonoff(xbxferokcode in xbstat,
                     'Transfer OK','Transfer bad'));
                  11:begin
                       s:='7. <U>L codes  :';
                       for j:=1 to 6 do
                         s:=s+mln('('+cstr(j)+')"'+ulcode[j]+'" ',10);
                       print(copy(s,1,length(s)-1));
                     end;
                  12:begin
                       s:='   <D>L codes  :';
                       for j:=1 to 6 do
                         s:=s+mln('('+cstr(j)+')"'+dlcode[j]+'" ',10);
                       print(copy(s,1,length(s)-1));
                     end;
                  13:print('E. Environ. cmd: '+nnon(envcmd));
                  14:print('I. DL File list: '+nnon(dlflist));
                  15:print('C. Max DOS chrs:'+cstr(maxchrs)+
                           '   P. Log position: Filename: '+cstr(logpf)+
                           ' - Status: '+cstr(logps));
                end;
                inc(i);
                wkey;
              end;
            end;
            prt(^M^J'Edit menu (?=help) : '); onek(c,'Q!1234567CEIP[]FJL?'^M);
            nl;
            case c of
              '!':begin
                    repeat
                      print('^11. Protocol active   :'+syn(xbactive in xbstat));
                      print('2. Is batch protocol :'+syn(xbisbatch in xbstat));
                      print('3. Is resume protocol:'+syn(xbisresume in xbstat));
                      print('4. Is bidirectional  :'+syn(xbbidirectional in xbstat));
                      print('5. For reliable only :'+syn(xbreliable in xbstat));
                      prt(^M^J'Select (1-5,Q=Quit) : '); onek(c,'Q12345'^M);
                      nl;
                      if (c in ['1'..'5']) then begin
                        case c of
                          '1':if (xbactive in xbstat) then
                                xbstat:=xbstat-[xbactive]
                              else xbstat:=xbstat+[xbactive];
                          '2':if (xbisbatch in xbstat) then
                                xbstat:=xbstat-[xbisbatch]
                              else xbstat:=xbstat+[xbisbatch];
                          '3':if (xbisresume in xbstat) then
                                xbstat:=xbstat-[xbisresume]
                              else xbstat:=xbstat+[xbisresume];
                          '4':if (xbbidirectional in xbstat) then
                                xbstat:=xbstat-[xbbidirectional]
                              else xbstat:=xbstat+[xbbidirectional];
                          '5':if (xbreliable in xbstat) then
                                xbstat:=xbstat-[xbreliable]
                              else xbstat:=xbstat+[xbreliable];
                        end;
                      end;
                    until ((not (c in ['1'..'5'])) or (hangup));
                    c:=#0;
                  end;
              '1':begin
                    prt('New command keys: '); mpl(14); input(s,14);
                    if (s<>'') then ckeys:=s;
                    print(^M^J'New description:');
                    prt(':'); UserColor(1); inputwc(s,40);
                    if (s<>'') then descr:=s;
                  end;
              '2':begin
                    prt('New ACS: '); mpl(20);
                    inputwn(acs,20,changed);
                  end;
              '3':begin
                    print('New temp. log:');
                    prt(':'); inputwn(templog,25,changed);
                  end;
              '4':case udq of
                    1:begin
                        print('New permanent upload log:');
                        prt(':'); inputwn(uloadlog,25,changed);
                      end;
                    2:begin
                        print('New permanent download log:');
                        prt(':'); inputwn(dloadlog,25,changed);
                      end;
                  end;
              '5':begin
                    s:=#0#0#0; j:=udq;
                    prt('Type: (C)ommand (E)xternal (O)ff : ');
                    onek(c,^M'CEO'); nl;
                    case c of
                      'C':begin
                            prt('(A)scii (B)atch (E)dit (N)ext (Q)uit : ');
                            onek(c,'ABENQ'^M);
                            case c of
                              'A':s:='ASCII';
                              'B':s:='BATCH';
                              'E':s:='EDIT';
                              'N':s:='NEXT';
                              'Q':s:='QUIT';
                            end;
                          end;
                      'E':begin
                            if (j=1) then print('New upload commandline:')
                              else print('New download commandline:');
                            prt(':'); inputwn(s,78,changed);
                          end;
                      'O':if pynq('Set to NULL string? ') then s:='';
                    end;
                    if (s<>#0#0#0) then begin
                      case j of
                        1:ulcmd:=s;
                        2:dlcmd:=s;
                      end;
                    end;
                    c:=#0;
                  end;
              '6':begin
                    if (xbxferokcode in xbstat) then
                      xbstat:=xbstat-[xbxferokcode]
                      else xbstat:=xbstat+[xbxferokcode];
                  end;
              '7':begin
                    case udq of
                      1:begin
                          print('New upload codes:'^M^J);
                          for i:=1 to 6 do begin
                            prt('Code #'+cstr(i)+' ["'+ulcode[i]+'"] : ');
                            inputwn(ulcode[i],6,changed);
                          end;
                        end;
                      2:begin
                          print('New download codes:'^M^J);
                          for i:=1 to 6 do begin
                            prt('Code #'+cstr(i)+' ["'+dlcode[i]+'"] : ');
                            inputwn(dlcode[i],6,changed);
                          end;
                        end;
                    end;
                  end;
              'C':begin
                    prt('New max DOS chrs in commandline: '); inu(i);
                    if (not badini) then maxchrs:=i;
                  end;
              'E':begin
                    print('New environment setup commandline:');
                    prt(':'); inputwn(envcmd,60,changed);
                  end;
              'I':begin
                    print('New batch file list:');
                    prt(':'); inputwn(dlflist,25,changed);
                  end;
              'P':begin
                    prt('New "Filename" log position? ['+cstr(logpf)+'] : ');
                    inu(i);
                    if (not badini) then logpf:=i;
                    prt('New "Status" log position? ['+cstr(logps)+'] : ');
                    inu(i);
                    if (not badini) then logps:=i;
                  end;
              '[':if (ii>0) then dec(ii) else c:=' ';
              ']':if (ii<filesize(xf)-1) then inc(ii) else c:=' ';
              'F':if (ii<>0) then ii:=0 else c:=' ';
              'J':begin
                    prt('Jump to entry: ');
                    input(s,3);
                    if ((value(s)>=0) and (value(s)<=filesize(xf)-1)) then
                      ii:=value(s) else c:=' ';
                  end;
              'L':if (ii=filesize(xf)-1) then c:=' ' else ii:=filesize(xf)-1;
              '?':ee_help;
            end;
          until (pos(c,'Q[]FJL')<>0) or (hangup);
          seek(xf,xloaded); write(xf,protocol);
      end;
    end;
    Lasterror := IOResult;
  end;

  procedure xep;
  var i,j,k:integer;
  begin
    prt('Move which protocol? (0-'+cstr(filesize(xf)-1)+') : '); inu(i);
    if ((not badini) and (i>=0) and (i<=filesize(xf)-1)) then begin
      prt('Move before which protocol? (0-'+cstr(filesize(xf))+') : '); inu(j);
      if ((not badini) and (j>=0) and (j<=filesize(xf)) and
          (j<>i) and (j<>i+1)) then begin
        xei(j);
        if (j>i) then k:=i else k:=i+1;
        seek(xf,k); read(xf,protocol);
        seek(xf,j); write(xf,protocol);
        if (j>i) then xed(i) else xed(i+1);
      end;
    end;
    Lasterror := IOResult;
  end;

  function nar(c:char):char;
  begin
    if c='@' then nar:=' ' else nar:=c;
  end;

begin
  reset(xf); xloaded:=-1; c:=#0;
  repeat
    if (c<>'?') then
    begin
      cls; abort:=FALSE;
      printacr('^3 NNN'+seperator+'ACS       '+seperator+'Description');
      printacr('^4 ===:==========:=============================================================');
      ii:=0;
      seek(xf,0);
      AllowContinue := TRUE;
      while (ii<=filesize(xf)-1) and (not abort) do begin
        read(xf,protocol);
        with protocol do begin
          printacr(aonoff((xbactive in xbstat),'^5+','^1-')+
                   '^0'+mn(ii,3)+' ^9'+mln(acs,10)+' ^1'+
                   descr);
          inc(ii);
        end;
      end;
    end;
    prt(^M^J'Protocol editor (?=help) : ');
    AllowContinue := FALSE;
    onek(c,'QDIMP?'^M);
    case c of
      '?':begin
            print(^M^J'<CR>Redisplay screen');
            lcmds(16,3,'Delete protocol','Insert protocol');
            lcmds(16,3,'Modify protocol','Position protocol');
            lcmds(16,3,'Quit','');
          end;
      'D':begin
            prt('Protocol to delete? (0-'+cstr(filesize(xf)-1)+') : '); inu(ii);
            if (ii>=0) and (ii<=filesize(xf)-1) then begin
              seek(xf,ii); read(xf,protocol);
              print(^M^J'Protocol: ^4'+protocol.descr);
              if pynq('Delete this? ') then
              begin
                sysoplog('* Deleted protocol: '+protocol.descr); xed(ii);
              end;
            end;
          end;
      'I':begin
            prt('Protocol to insert before? (0-'+cstr(filesize(xf))+') : '); inu(ii);
            if (ii>=0) and (ii<=filesize(xf)) then
            begin
              xei(ii); sysoplog('* Created protocol');
            end;
          end;
      'M':xem;
      'P':xep;
    end;
  until ((c='Q') or (hangup));
  close(xf);
  Lasterror := IOResult;
end;

end.
