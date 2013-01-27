{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ user editor }

unit sysop3;

interface

uses crt, dos, overlay, common;


function pickval:char;
procedure restric_list;
procedure autoval(var u:userrec; un:integer);
procedure showuserinfo(typ,usern:integer; const user1:userrec);
procedure uedit(usern:integer);

implementation

uses mail0, Script, ShortMsg, cuser, timefunc, user;

procedure restric_list;
begin
  begin
    print(^M^J'^3Restrictions:'^M^J);

    lcmds(27,3,'LCan logon ONLY once/day','CCan''t page SysOp');
    lcmds(27,3,'VPosts marked unvalidated','UCan''t list users');
    lcmds(27,3,'ACan''t add to BBS list','*Can''t post/send anon.');
    lcmds(27,3,'PCan''t post at all','ECan''t send email');
    lcmds(27,3,'KCan''t vote','Manditory mail deletion');

    print(^M^J'^3Special:'^M^J);

    lcmds(27,3,'1No UL/DL ratio check','2No post/call ratio check');
    lcmds(27,3,'3No credits check','4Protection from deletion');
    nl;
  end;
end;

function spflags(u:userrec):astr;
var r:uflags;
    s:astr;
begin
  s:='';
  for r:=rlogon to rmsg do
    if r in u.flags then
      s:=s+copy('LCVUA*PEKM',ord(r)+1,1)
    else s:=s+'-';
  s:=s+'/';
  for r:=fnodlratio to fnodeletion do
    if r in u.flags then
      s:=s+copy('1234',ord(r)-19,1)
    else s:=s+'-';
  spflags:=s;
end;

function pickval:char;
var
  Choice:char;
  Index:char;
  c:char;
begin
  Choice := #0;
  repeat
    prompt(^M^J'Validation level (A-Z)? : ');
    onek(Index,'ABCDEFGHIJKLMNOPQRSTUVWXYZ?'^M);
    if (Index = '?') then
      begin
        abort := FALSE;
        cls;
        Index := '?';
        while (Index <= 'X') and (not abort) and (not hangup) do
          begin
            inc(Index,2);
            c:=Index; inc(c);
            printacr(Index + '. ' + mln(general.validation[Index].description,30) +
                     c + '. ' + general.validation[c].description);
          end;
        nl;
      end
    else
      if (Index >= 'A') and (Index <= 'Z') then
        begin
          Choice := Index;
          if (general.validation[Choice].newsl > thisuser.sl) then
            Choice := #0;
        end;
  until (Choice > #0) or (Index = 'Q') or (Index = ^M) or (hangup);
  pickval := Choice;
end;

procedure autoval(var u:userrec; un:integer);
var
  c:char;
begin
  c := pickval;
  if (c in ['A'..'Z']) then
    begin
      autovalidate(u,un,c);
      saveurec(u,un);
      print('User Validated.');
    end;
end;

procedure showuserinfo(typ,usern:integer; const user1:userrec);
var
  ii:astr;
  i:integer;

  procedure shi1(var i:integer);
  var c:char;
  begin
    with user1 do
      case i of
        1:begin
            ii:='^5Renegade user editor ^1['+cstr(usern)+' of '+cstr(maxusers-1)+']';
            if not (onnode(usern) in [0,node]) then ii:=mln(ii,45)+'^8Note: ^3User is on node '+cstr(onnode(usern));
            ii:=ii+#13#10;
          end;
        2:ii:='^1A. User name : ^3'+mln(name,29)+'^1 L. Security  : ^3'+cstr(sl);
        3:ii:='^1B. Real name : ^3'+mln(realname,29)+'^1 M. D Security: ^3'+cstr(dsl);
        4:begin
            ii:='^1C. Address   : ^3'+mln(street,29)+'^1 N. AR:^3';
            for c:='A' to 'Z' do
              if c in ar then ii:=ii+c else ii:=ii+'-';
          end;
        5:ii:='^1D. City/State: ^3'+mln(citystate,29)+'^1 O. AC:^3'+spflags(user1);
        6:ii:='^1E. Zip code  : ^3'+mln(zipcode,29)+'^1 P. Sex/Age   : ^3'+
              sex+cstr(ageuser(birthdate))+' ('+todate8(pd2date(birthdate))+')';
        7:ii:='^1F. SysOp note: ^3'+mln(note,29)+'^1 R. Phone num : ^3'+ph;
        8:ii:='^1G. '+mln(fstring.userdefed[1],10)+': ^3'+mln(usrdefstr[1],29)+
              '^1 T. Last/1st  : ^3'+todate8(pd2date(laston))+' ('+todate8(pd2date(firston))+')';
        9:begin
            ii:='^1H. '+mln(fstring.userdefed[2],10)+': ^3'+mln(usrdefstr[2],29)+'^1 V. Locked out: ^3';
            if (lockedout in sflags) then ii:=ii + '^7' + lockedfile+'.ASC' else
              ii:=ii+'Inactive';
          end;
        10:begin
            ii:='^1I. '+mln(fstring.userdefed[3],10)+': ^3' + mln(usrdefstr[3],29)+
                '^1 W. Password  : [Not Shown]';
          end;
        11:begin
             if (deleted in sflags) then ii:='^8' else ii:='^1';
             ii:=ii+'[DEL] ';
             if (trapactivity in sflags) and ((usern<>usernum) or (usernum=1)) then
                if (trapseparate in sflags) then
                  ii:=ii+'^8[TRP SEP] '
                else
                  ii:=ii+'^8[TRP COM] '
             else
               ii:=ii+'^1[TRP OFF] ';
             if (lockedout in sflags) then ii:=ii+'^8'
                else ii:=ii+'^1';
             ii:=ii+'[LOCK] ';
             if (alert in flags) then ii:=ii+'^8'
                else ii:=ii+'^1';
             ii:=ii+'[ALRT] ';
             ii:='^1J. Status    : ^3'+mln(ii,29)+'^1 X. Caller ID : ^3' + CallerID;
          end;
       12:ii:='^1K. QWK setup : ^3'+mln(general.filearcinfo[defarctype].ext,29)+
              '^1 Y. Start Menu: ^3'+userstartmenu+#13#10;

       13:ii:='^11. Call records- TC:^3'+mn(loggedon,8)+
                              '^1 TT:^3'+mln(cstr(ttimeon),8)+
                              '^1 CT:^3'+mn(ontoday,8)+
                              '^1 TL:^3'+mn(tltoday,8)+
                              '^1 TB:^3'+cstr(timebank);
       14:ii:='^12. Mail records- PB:^3'+mn(msgpost,8)+
                              '^1 PV:^3'+mn(emailsent,8)+
                              '^1 FB:^3'+mn(feedback,8)+
                              '^1 WT:^3'+cstr(waiting);
       15:ii:='^13. File records- DL:^3'+mln(cstr(downloads)+'-'+cstr(dk)+'k',20)+
                              '^1 UL:^3'+mln(cstr(uploads)+'-'+cstr(uk)+'k',20)+
                              '^1 DT:^3'+cstr(dltoday)+'-'+cstr(dlktoday)+'k';
       16:begin
          ii:='^14. Pref records- EM:^3';
          if (AutoDetect in sflags) then ii:=ii+'Auto    ' else
            if (rip in sflags) then ii:=ii+'RIP     ' else
            if (avatar in flags) then ii:=ii+'Avatar  ' else
               if (ansi in flags) then ii:=ii+'Ansi    ' else
                 if (okvt100) then ii:=ii+'VT-100  ' else
                  ii:=ii+'None    ';
          ii:=ii+'^1 CS:^3'+mln(syn(clsmsg in sflags),8)+
                 '^1 PS:^3'+mln(syn(pause in flags),8)+
                 '^1 CL:^3'+mln(syn(color in flags),8)+
                 '^1 ED:^3'+aonoff((fseditor in sflags),'F/S','Reg');
          end;
       17:begin
            if (expiration > 0) then
              ii := todate8(pd2date(expiration))
            else
              ii := 'Never   ';
            ii:='^15. Subs records- CR:^3'+mn(credit,8)+
                                '^1 DB:^3'+mn(debit,8)+
                                '^1 BL:^3'+mn(Credit - Debit,8)+
                                '^1 ED:^3'+ii+
                                '^1 ET:^3'+expireto;
          end;
      end;
    printacr(ii);
    inc(i);
  end;

  procedure shi2(var i:integer);
  begin
    shi1(i);
  end;

begin
  abort:=FALSE;
  i:=1;
  cls;
  case typ of
    1:while (i<=17) and (not abort) do shi1(i);
    2:while (i<=5) and (not abort) do shi2(i);
  end;
end;

procedure uedit(usern:integer);
type f_statusflagsrec=(fs_deleted,fs_trapping,fs_chatbuffer,
                       fs_lockedout,fs_alert,fs_slogging);
const autolist:boolean=TRUE;
      userinfotyp:byte=1;
      f_state:array[0..14] of boolean=
        (FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,
         FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE);
      f_gentext:string[30]='';
      f_acs:string[50]='';
      f_sl1:word=0; f_sl2:word=255;
      f_dsl1:word=0; f_dsl2:word=255;
      f_ar:set of acrq=[];
      f_ac:set of uflags=[];
      f_status:set of f_statusflagsrec=[];
      f_laston1:longint=0; f_laston2:longint=$FFFFFFF;
      f_firston1:longint=0; f_firston2:longint=$FFFFFFF;
      f_numcalls1:word=0; f_numcalls2:word=65535;
      f_age1:word=0; f_age2:word=65535;
      f_gender:char='M';
      f_postratio1:word=0; f_postratio2:word=65535;
      f_dlkratio1:word=0; f_dlkratio2:word=65535;
      f_dlratio1:word=0; f_dlratio2:word=65535;
var user,user1:userrec;
    r:uflags;
    f:file;
    ii,is,s:astr;
    i,i1,x,oldusern:integer;
    byt:byte;
    c:char;
    save,save1:boolean;

  function unam:astr;
  begin
    unam:=caps(user.name)+' #'+cstr(usern);
  end;

  function searchtype(i:integer):string;
  begin
    case i of
      0:searchtype:='General text';           1:searchtype:='Search ACS';
      2:searchtype:='User SL';                3:searchtype:='User DSL';
      4:searchtype:='User AR flags';          5:searchtype:='User AC flags';
      6:searchtype:='User status';            7:searchtype:='Date since last on';
      8:searchtype:='Date since first on';    9:searchtype:='Number of calls';
     10:searchtype:='User age';               11:searchtype:='User gender';
     12:searchtype:='# 1/10''s call/post';    13:searchtype:='#k DL/1k UL';
     14:searchtype:='# DLs/1 UL';
    end;
  end;

  function find_fs:string;
  var fsf:f_statusflagsrec;
      s:astr;
  begin
    s:='';
    for fsf:=fs_deleted to fs_slogging do
      if (fsf in f_status) then
        case fsf of
          fs_deleted   :s:=s+'deleted,';
          fs_trapping  :s:=s+'trapping,';
          fs_chatbuffer:s:=s+'chat buffering,';
          fs_lockedout :s:=s+'locked out,';
          fs_alert     :s:=s+'alert,';
          fs_slogging  :s:=s+'sep. SysOp Log,';
        end;
    if (s<>'') then s:=copy(s,1,length(s)-1) else s:='None.';
    find_fs:=s;
  end;

  procedure pcuropt;
  var r:uflags;
      s:astr;
      c:char;
      i:integer;
  begin
    i:=-1;
    print(^M^J'^5Search Criterea:^1');
    abort:=FALSE; next:=FALSE;
    while ((i<14) and (not abort) and (not hangup)) do begin
      inc(i);
      if (i in [0..9]) then c:=chr(i+48) else
        case i of 10:c:='A'; 11:c:='G'; 12:c:='P'; 13:c:='K'; 14:c:='N'; end;
      prompt('^1'+c+'. '+mln(searchtype(i),19)+': '); s:='';
      if (not f_state[i]) then
        s:='Inactive!'
      else begin
        case i of
          0:s:='"'+f_gentext+'"';
          1:s:='"'+f_acs+'"';
          2:s:=cstr(f_sl1)+' SL ... '+cstr(f_sl2)+' SL';
          3:s:=cstr(f_dsl1)+' DSL ... '+cstr(f_dsl2)+' DSL';
          4:for c:='A' to 'Z' do
              if (c in f_ar) then s:=s+c else s:=s+'-';
          5:begin
              for r:=rlogon to rmsg do
                if (r in f_ac) then s:=s+copy('LCVUA*PEKM',ord(r)+1,1)
                else s:=s+'-';
              s:=s+'/';
              for r:=fnodlratio to fnodeletion do begin
                if (r in f_ac) then s:=s+copy('1234',ord(r)-19,1)
                else s:=s+'-';
              end;
            end;
          6:s:=find_fs;
          7:s:=pd2date(f_laston1)+' ... '+pd2date(f_laston2);
          8:s:=pd2date(f_firston1)+' ... '+pd2date(f_firston2);
          9:s:=cstr(f_numcalls1)+' calls ... '+cstr(f_numcalls2)+' calls';
         10:s:=cstr(f_age1)+' years ... '+cstr(f_age2)+' years';
         11:s:=aonoff(f_gender='M','Male','Female');
         12:s:=cstr(f_postratio1)+' ... '+cstr(f_postratio2);
         13:s:=cstr(f_dlkratio1)+' ... '+cstr(f_dlkratio2);
         14:s:=cstr(f_dlratio1)+' ... '+cstr(f_dlratio2);
        end;
        UserColor(3);
      end;
      print(s);
      wkey;
    end;
    nl;
  end;

  function okusr(x:integer):boolean;
  var fsf:f_statusflagsrec;
      u:userrec;
      i,j:integer;
      ok:boolean;

    function nofindit(s:astr):boolean;
    begin
      nofindit:=(pos(allcaps(f_gentext),allcaps(s))=0);
    end;

  begin
    i:=-1;
    with u do begin
      loadurec(u,x);
      ok:=TRUE;
      while ((ok) and (i<14)) do begin
        inc(i);
        if (f_state[i]) then
          case i of
            0:if ((nofindit(name)) and (nofindit(realname)) and
                  (nofindit(street)) and (nofindit(citystate)) and
                  (nofindit(zipcode)) and (nofindit(usrdefstr[1])) and
                  (nofindit(ph)) and (nofindit(note)) and
                  (nofindit(usrdefstr[2])) and (nofindit(usrdefstr[3]))) then
                ok:=FALSE;
            1:if (not aacs1(u,x,f_acs)) then ok:=FALSE;
            2:if ((sl<f_sl1) or (sl>f_sl2)) then ok:=FALSE;
            3:if ((dsl<f_dsl1) or (dsl>f_dsl2)) then ok:=FALSE;
            4:if (not (ar>=f_ar)) then ok:=FALSE;
            5:if (not (flags>=f_ac)) then ok:=FALSE;
            6:for fsf:=fs_deleted to fs_slogging do
                if (fsf in f_status) then
                  case fsf of
                    fs_deleted   :if not (deleted in u.sflags) then ok:=FALSE;
                    fs_trapping  :if not (trapactivity in u.sflags) then ok:=FALSE;
                    fs_chatbuffer:if not (chatauto in u.sflags) then ok:=FALSE;
                    fs_lockedout :if not (lockedout in u.sflags) then ok:=FALSE;
                    fs_alert     :if not ((alert in flags)) then ok:=FALSE;
                    fs_slogging  :if not (slogseparate in u.sflags) then ok:=FALSE;
                  end;
            7:if ((laston < f_laston1) or
                  (laston > f_laston2)) then ok:=FALSE;
            8:if ((firston < f_firston1) or
                  (firston > f_firston2)) then ok:=FALSE;
            9:if ((loggedon<f_numcalls1) or (loggedon>f_numcalls2)) then ok:=FALSE;
           10:if (((ageuser(birthdate)<f_age1) or (ageuser(birthdate)>f_age2)) and
                  (ageuser(birthdate)<>0)) then
                ok:=FALSE;
           11:if (sex<>f_gender) then ok:=FALSE;
           12:begin
                if loggedon > 0 then
                  j := (msgpost div loggedon) * 100
                else
                  j := 1;
                if ((j<f_postratio1) or (j>f_postratio2)) then ok:=FALSE;
              end;
           13:begin
                j:=uk; if (j=0) then j:=1; j:=dk div j;
                if ((j<f_dlkratio1) or (j>f_dlkratio2)) then ok:=FALSE;
              end;
           14:begin
                j:=uploads; if (j=0) then j:=1; j:=downloads div j;
                if ((j<f_dlratio1) or (j>f_dlratio2)) then ok:=FALSE;
              end;
          end;
      end;
    end;
    okusr:=ok;
  end;

  procedure search(i:integer);
  var n:integer;
  begin
    n:=usern;
    reset(uf);
    repeat
      inc(usern,i);
      if (usern<=0) then usern:=maxusers-1;
      if (usern>=maxusers) then usern:=1;
    until ((okusr(usern)) or (usern=n));
    close(uf);
  end;

  procedure clear_f;
  var i:integer;
  begin
    for i:=0 to 14 do f_state[i]:=FALSE;

    f_gentext:=''; f_acs:='';
    f_sl1:=0; f_sl2:=255; f_dsl1:=0; f_dsl2:=255;
    f_ar:=[]; f_ac:=[]; f_status:=[];
    f_laston1:=0; f_laston2:=$FFFFFFF; f_firston1:=0; f_firston2:=$FFFFFFF;
    f_numcalls1:=0; f_numcalls2:=65535; f_age1:=0; f_age2:=65535;
    f_gender:='M';
    f_postratio1:=0; f_postratio2:=65535; f_dlkratio1:=0; f_dlkratio2:=65535;
    f_dlratio1:=0; f_dlratio2:=65535;
  end;

  procedure stopt;
  var fsf:f_statusflagsrec;
      i,usercount:integer;
      c,ch:char;
      done:boolean;
      s:astr;

    procedure chbyte(var x:integer);
    var s:astr;
        i:integer;
    begin
      input(s,3); i:=x;
      if (s<>'') then i:=value(s);
      if ((i>=0) and (i<=255)) then x:=i;
    end;

    procedure chword(var x:word);
    var s:astr;
        w:word;
    begin
      input(s,5);
      if (s<>'') then begin
        w:=value(s);
        if ((w>=0) and (w<=65535)) then x:=w;
      end;
    end;

    procedure inp_range(var w1,w2:word; r1,r2:word);
    begin
      print('Range: '+cstr(r1)+'..'+cstr(r2));
      prt('Lower limit ['+cstr(w1)+'] : '); chword(w1);
      prt('Upper limit ['+cstr(w2)+'] : '); chword(w2);
    end;
  
    function get_f_ac:string;
    var r:uflags;
        s:string[30];
    begin
    s:='';
      for r:=rlogon to rmsg do
        if (r in f_ac) then s:=s+copy('LCVUA*PEKM',ord(r)+1,1)
        else s:=s+'-';
      s:=s+'/';
      for r:=fnodlratio to fnodeletion do begin
        if (r in f_ac) then s:=s+copy('1234',ord(r)-19,1)
        else s:=s+'-';
      end;
      get_f_ac:=s;
    end;

  begin
    done:=FALSE;
    pcuropt;
    repeat
      prt('Change (?=help) : '); onek(c,'Q0123456789AGPKN?CLTU'^M);
      nl;
      case c of
        '0'..'9':i:=ord(c)-48;
        'A':i:=10; 'G':i:=11; 'P':i:=12; 'K':i:=13; 'N':i:=14;
      else
            i:=-1;
      end;
      if (i<>-1) then begin
        prompt('^5[>^0 ');
        if (f_state[i]) then
          print(searchtype(i))
        else begin
          f_state[i]:=TRUE;
          print(searchtype(i)+' is now *ON*');
        end;
      end;

      case c of
        '0':begin
              print('General text ["'+f_gentext+'"]');
              prt(':'); input(s,30);
              if (s<>'') then f_gentext:=s;
            end;
        '1':begin
              prt('Search ACS ["'+f_acs+'"]');
              prt(':'); inputl(s,50);
              if (s<>'') then f_acs:=s;
            end;
        '2':begin
              prt('Lower limit ['+cstr(f_sl1)+'] : ');
              chword(f_sl1);
              prt('Upper limit ['+cstr(f_sl2)+'] : ');
              chword(f_sl2);
            end;
        '3':inp_range(f_dsl1,f_dsl2,0,255);
        '4':repeat
              prt('Which AR flag? <CR>=Quit : ');
              onek(ch,^M'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
              if (ch<>^M) then
                if (ch in ['A'..'Z']) then
                  if (ch in f_ar) then f_ar:=f_ar-[ch] else f_ar:=f_ar+[ch];
            until ((ch=^M) or (hangup));
        '5':begin
              repeat
                prt('Restrictions ['+get_f_ac+'] [?]Help [Q]uit :');
                onek(c,'Q LCVUA*PEKM1234?'^M);
                case c of
                  ^M,' ','Q': ;
                  '?':restric_list;
                else
                      if (tacch(c) in f_ac) then f_ac:=f_ac-[tacch(c)]
                      else f_ac:=f_ac+[tacch(c)];
                end;
              until ((c in [^M,' ','Q']) or (hangup));
            end;
        '6':repeat
              s:=find_fs;
              print('^4Current flags: ^3'+s);
              prt('Toggle (?=help) : '); onek(ch,'QACDLST? '^M);
              if (pos(ch,'ACDLST')<>0) then begin
                case ch of
                  'A':fsf:=fs_alert;
                  'C':fsf:=fs_chatbuffer;
                  'D':fsf:=fs_deleted;
                  'L':fsf:=fs_lockedout;
                  'S':fsf:=fs_slogging;
                  'T':fsf:=fs_trapping;
                end;
                if (fsf in f_status) then f_status:=f_status-[fsf]
                  else f_status:=f_status+[fsf];
              end else
                if (ch='?') then begin
                  nl;
                  lcmds(15,3,'Alert','Chat-buffering');
                  lcmds(15,3,'Deleted','Locked-out');
                  lcmds(15,3,'Separate SysOp logging','Trapping');
                  nl;
                end;
            until ((ch in ['Q',' ',^M]) or (hangup));
        '7':begin
              prt('Starting date: ');
              inputformatted(s, '##/##/####', TRUE);
              f_laston1 := date2pd(s);
              prt('Ending date: ');
              inputformatted(s, '##/##/####', TRUE);
              f_laston2 := date2pd(s);
            end;
        '8':begin
              prt('Starting date: ');
              inputformatted(s, '##/##/####', TRUE);
              f_firston1 := date2pd(s);
              prt('Ending date: ');
              inputformatted(s, '##/##/####', TRUE);
              f_firston2 := date2pd(s);
            end;
        '9':inp_range(f_numcalls1,f_numcalls2,0,65535);
        'A':inp_range(f_age1,f_age2,0,65535);
        'G':begin
              prt('Gender ['+f_gender+'] : ');
              onek(c,'QMF'^M); nl;
              if (c in ['F','M']) then f_gender:=c;
            end;
        'P':inp_range(f_postratio1,f_postratio2,0,65535);
        'K':inp_range(f_dlkratio1,f_dlkratio2,0,65535);
        'N':inp_range(f_dlratio1,f_dlratio2,0,65535);
        'C':if pynq('Are you sure? ') then clear_f;
        ^M,'L':pcuropt;
        'T':begin
              prt('Which? '); onek(ch,'Q0123456789AGPKN'^M);
              case ch of
                '0'..'9':i:=ord(ch)-48;
                'A':i:=10; 'G':i:=11; 'P':i:=12; 'K':i:=13; 'N':i:=14;
              else
                    i:=-1;
              end;
              if (i<>-1) then begin
                f_state[i]:=not f_state[i];
                prompt('^5[>^0 '+searchtype(i)+' is now *');
                if (f_state[i]) then print('ON*') else print('OFF*');
              end;
              nl;
            end;
        'U':begin
              abort:=FALSE; usercount:=0;
              reset(uf);
              x:=filesize(uf);
              for i:=1 to x-1 do begin
                if (okusr(i)) then begin
                  loadurec(user1,i);
                  printacr('^3'+caps(user1.name)+' #'+cstr(i));
                  inc(usercount);
                end;
                if (abort) then i:=x-1;
              end;
              close(uf);
              if (not abort) then
                print(^M^J'^7 ** ^5'+cstr(usercount)+' Users.'^M^J);
            end;
        'Q':done:=TRUE;
        '?':begin
              print('^30-9,AGPKN^1: Change option');
              lcmds(14,3,'List options','Toggle options on/off');
              lcmds(14,3,'Clear options','User''s who match');
              lcmds(14,3,'Quit','');
              nl;
            end;
      end;
      if (pos(c,'C0123456789AGPKN')<>0) then nl;
    until ((done) or (hangup));
  end;

  procedure killusermail;
  var mheader:mheaderrec;
      i,xbread:word;
      u:userrec;
  begin
    xbread:=readboard;
    initboard(-1);
    reset(msghdrf);
    for i:=1 to himsg do begin
      loadheader(i,mheader);
      if (not (mdeleted in mheader.status)) and
         ((mheader.mto.usernum=usern) or (mheader.from.usernum=usern)) then
            begin
              mheader.status := mheader.status + [mdeleted];
              saveheader(i, mheader);
              loadurec(u, mheader.mto.usernum);
              if (u.waiting > 255) then
                inc(u.waiting);
              saveurec(u, mheader.mto.usernum);
              reset(msghdrf);
            end;
    end;
    close(msghdrf);
    initboard(xbread);
  end;

  procedure killuservotes;
  var vfile:file of votingr;
      topic:votingr;
      i:integer;
  begin
    assign(vfile,general.datapath+'voting.dat');
    reset(vfile);
    if (ioresult=0) then begin
      for i:=1 to filesize(vfile) do
        if (user.vote[i]>0) then begin
          seek(vfile,i-1); read(vfile,topic);
          dec(topic.choices[user.vote[i]].numvoted);
          dec(topic.numvoted);
          seek(vfile,i-1); write(vfile,topic);
          user.vote[i]:=0;
        end;
      close(vfile);
    end;
    Lasterror := IOResult;
  end;

  procedure delusr;
  var i:integer;
  begin
    if not (deleted in user.sflags) then begin
      save:=TRUE; user.sflags:=user.sflags+[deleted];
      InsertIndex(user.name, usern, FALSE, TRUE);
      InsertIndex(user.realname, usern, TRUE, TRUE);
      dec(Todaynumusers);
      savegeneral(TRUE);
      sysoplog('* Deleted user: '+caps(user.name)+' #'+cstr(usern));
      i:=usernum; usernum:=usern;
      rsm;
      usernum:=i;
      user.waiting:=0;

      killusermail;
      killuservotes;
    end;
  end;

  procedure renusr;
  begin
    if (deleted in user.sflags) then print('Can''t rename deleted users.')
    else begin
      prt(^M^J'Enter new name: '); input(ii,36);
      i := Searchuser(ii, TRUE);
      if ((i = 0) or (i = usern)) and (ii<>'') then
        begin
          InsertIndex(user.name, usern, FALSE, TRUE);
          user.name := ii;
          InsertIndex(user.name, usern, FALSE, FALSE);
          save:=TRUE;
          if (usern=usernum) then thisuser.name:=ii;
        end
      else
        print('Illegal name.');
    end;
  end;

  procedure chhflags;
  var c:char;
      done:boolean;
  begin
    done:=FALSE;
    nl;
    repeat
      prt('Restrictions ['+spflags(user)+'] [?]Help [Q]uit :');
      onek(c,'Q LCVUA*PEKM1234?'^M);
      case c of
        ^M,' ','Q':done:=TRUE;
        '?':restric_list;
      else
            begin
              if (c='4') and (not so) then print('You can''t change that!')
              else begin
                acch(c,user);
                save:=TRUE;
              end;
            end;
      end;
    until (done) or (hangup);
    save:=TRUE;
  end;

  procedure chhsl;
  begin
    prt('Enter new SL: '); ini(byt);
    if (not badini) then begin
      save:=TRUE;
      if (byt<thisuser.sl) or (usernum=1) then begin
        if (usernum=usern) and (byt<thisuser.sl) then
          if not pynq('Lower your own SL level? ') then exit;
        user.sl:=byt;
      end else begin
        sysoplog('Illegal SL edit attempt: '+caps(user.name)+' #'+cstr(usern)+
                 ' to '+cstr(byt));
        print('Access denied.'^G);
      end;
    end;
  end;

  procedure chhdsl;
  begin
    prt('Enter new DSL: '); ini(byt);
    if (not badini) then begin
      save:=TRUE;
      if (byt<thisuser.dsl) or (usernum=1) then begin
        if (usernum=usern) and (byt<thisuser.sl) then
          if not pynq('Lower your own DSL level? ') then exit;
        user.dsl:=byt;
      end else begin
        sysoplog('Illegal DSL edit attempt: '+caps(user.name)+' #'+cstr(usern)+
                 ' to '+cstr(byt));
        print('Access denied.'^G);
      end;
    end;
  end;

  procedure chrecords(beg:byte);
  var on:byte;
      c:char;
      i:longint;
      done:boolean;

  begin
    done:=FALSE;
    on:=beg;
    with user do
      repeat
        nl;
        case on of
          1:begin
              print('^5Call records:^1');
              print('(1)Total calls: '+mn(loggedon,5)+' (2)Total time on:   '+mn(ttimeon,8));
              print('(3)Calls today: '+mn(ontoday,5)+ ' (4)Time left today: '+mn(tltoday,5));
              print('(5)Ill. logons: '+mn(illegal,5)+ ' (6)Time Bank: '+cstr(timebank) + ^M^J);

              prt('Select: (1-6) [M]ail [F]ile [P]refs [S]ubs [Q]uit:');
              onek(c,'Q123456MFPS'^M);
            end;
          2:begin
              print('^5Mail records:^1');
              print('(1)Pub. posts: '+mn(msgpost,5)+ ' (2)Priv. posts:  '+mn(emailsent,5));
              print('(3)Fback sent: '+mn(feedback,5)+' (4)Mail waiting: '+mn(waiting,5));

              prt(^M^J'Select: (1-4) [C]all [F]ile [P]refs [S]ubs [Q]uit:');
              onek(c,'Q1234CFPS'^M);
            end;
          3:begin
              print('^5File records:^1');
              print('(1)# of DLs   : '+mn(downloads,5)+' (2)DL k      : '+cstr(dk));
              print('(3)# of ULs   : '+mn(uploads,5) + ' (4)UL k      : '+cstr(uk));
              print('(5)# DLs today: '+mn(dltoday,5) + ' (6)DL k today: '+cstr(dlktoday));

              prt(^M^J'Select: (1-6) [C]all [M]ail [P]refs [S]ubs [Q]uit:');
              onek(c,'Q123456CMPS'^M);
            end;
          4:begin
              print('^5Preference records:^1');
              if (AutoDetect in sflags) then s:='Auto  ' else
                if (rip in sflags) then s:= 'RIP   ' else
                  if (avatar in flags) then s:='Avatar' else
                    if (ansi in flags) then s:='Ansi  ' else
                      if (vt100 in flags) then s:='VT-100' else
                        s:='None    ';
              print('(1)Emulation:'+s+
                    ' (2)Clr Scrn:'+aonoff((clsmsg in sflags),'On  ','Off ')+
                    '(3)Pause:'+aonoff((pause in flags),'On ','Off'));
              print('(4)Color    :'+aonoff((color in flags),'On    ','Off   ')+
                    ' (5)Editor  :'+aonoff((fseditor in sflags),'F/S ','Reg '));

              prt(^M^J'Select (1-5) [C]all [M]ail [F]ile [S]ubs [Q]uit:');
              onek(c,'Q12345CMFS'^M);
            end;
          5:begin
              print('^5Subscription records:^1');
              print('(1) Credit: '+cstr(credit) +' (2) Debit: '+cstr(debit)+' (3) Expires: '+
                    aonoff(expiration=0,'Never',todate8(pd2date(expiration)))+' (4) Expire to: '+expireto);

              prt(^M^J'Select: (1-4) [C]all [M]ail [P]refs [F]ile [Q]uit:');
              onek(c,'Q1234CMPF'^M);
            end;
        end;
        case c of
          'Q',^M:done:=TRUE;
          'C':on:=1;
          'M':on:=2;
          'F':on:=3;
          'P':on:=4;
          'S':on:=5;
          '1'..'6':begin
            nl;
            if (on<>4) then begin
              if (on<>5) or not (value(c) in [3..4]) then
                begin
                  prt('New value: ');
                  input(s,10);
                  i:=value(s);
                end
              else
                case value(c) of
                  3:begin
                      if (pynq('Reset expiration date? ')) then
                        i := 0
                      else
                        begin
                          prt(^M^J'New expiration date: ');
                          inputformatted(s,'##/##/####',TRUE);
                          if (s <> '') then
                            i := date2pd(s);
                        end;
                    end;
                  4:begin
                      prt('Level to expire to: ');
                      onek(c,' ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M);
                      s := c;
                      c := '4';
                    end;
                end;
              if (s <> '') then
                case on of
                  1:case value(c) of
                      1:loggedon:=i;  2:ttimeon:=i;   3:ontoday:=i;
                      4:tltoday:=i;   5:illegal:=i;   6:timebank:=i;
                    end;
                  2:case value(c) of
                      1:msgpost:=i;   2:emailsent:=i;
                      3:feedback:=i;  4:waiting:=i;
                    end;
                  3:case value(c) of
                      1:downloads:=i; 2:dk:=i;        3:uploads:=i;
                      4:uk:=i;        5:dltoday:=i;   6:dlktoday:=i;
                    end;
                  5:case value(c) of
                      1:credit:=i;      2:debit:=i;
                      3:expiration:=i;
                      4:if (s[1] in [' ','A'..'Z']) then expireto:=s[1];
                    end;
                end;
            end else
                case value(c) of
                   1:cstuff(3, 3, user);
                   2:if clsmsg in sflags then sflags:=sflags-[clsmsg]
                        else sflags:=sflags+[clsmsg];
                   3:if (pause in flags) then flags:=flags-[pause] else flags:=flags+[pause];
                   4:if (color in flags) then flags:=flags-[color] else flags:=flags+[color];
                   5:if fseditor in sflags then sflags:=sflags-[fseditor]
                        else sflags:=sflags+[fseditor];
                end;
            end;
          end;
      until (done) or (hangup);
  end;

begin
  if ((usern<1) or (usern>maxusers-1)) then exit;
  if (usern=usernum) then begin
    user:=thisuser;
    saveurec(user,usern);
  end;
  loadurec(user,usern);

  clear_f;

  oldusern:=0;
  save:=FALSE;
  repeat
    abort:=FALSE;
    if (autolist) or (usern<>oldusern) or (c=^M) then begin
      showuserinfo(userinfotyp,usern,user);
      oldusern:=usern;
    end;
    Prt(^M^J'Select item: ');
    onek(c,'Q?[]={}*ABCDEFGHIJKLMNOPRSTUVWXY12345-+_;:\^'^M);
    nl;
    case c of
      '?':begin
            abort := FALSE;
            printacr('^5user editor help'^M^J);
            lcmds3(21,3,';New list mode',':Autolist toggle','\Show SysOp Log');
            lcmds3(21,3,'[Back one user',']Forward one user','=Reload old data');
            lcmds3(21,3,'{Search backward','}Search forward','*Validate user');
            lcmds3(21,3,'+Mailbox','UGoto user name/#','Search options');
            lcmds3(21,3,'-New user answers','_Other Q. answers','^Delete user');
            nl;
            pausescr(FALSE);
            save:=FALSE;
          end;
      '[',']','{','}','U','Q':begin
            if save then begin
              saveurec(user,usern);
              if usern=usernum then thisuser:=user;
              save:=FALSE;
            end;
            case c of
              '[':begin
                    dec(usern);
                    if (usern<=0) then usern:=maxusers-1;
                  end;
              ']':begin
                    inc(usern);
                    if (usern>=maxusers) then usern:=1;
                  end;
              '{':begin
                    prompt('Searching ... ');
                    search(-1); nl;
                  end;
              '}':begin
                    prompt('Searching ... ');
                    search(1);  nl;
                  end;
              'U':begin
                    prt('Enter user name, #, or partial search string: ');
                    finduserws(i);
                    if (i>0) then begin
                      loadurec(user,i);
                      usern:=i;
                    end;
                  end;
            end;
            loadurec(user,usern);
            if (usern=usernum) then thisuser:=user;
          end;
      '=':if pynq(^M^J'^7Reload old user data? ') then begin
            loadurec(user,usern);
            if (usern=usernum) then thisuser:=user;
            save:=FALSE;
            print('^7Old data reloaded.');
          end;
      'S','-','_',';',':','\':
          begin
            case c of
              'S':stopt;
              '-':begin
                    readasw(usern,general.miscpath+'newuser');
                    pausescr(FALSE);
                  end;
              '_':begin
                    prt(^M^J'Print questionairre file: '); mpl(8); input(s,8); nl;
                    readasw(usern,general.miscpath+s);
                    pausescr(FALSE);
                  end;
              ';':begin
                    prt(^M^J'(L)ong or (S)hort list mode : ');
                    onek(c,'QSL '^M);
                    case c of
                      'S':userinfotyp:=2;
                      'L':userinfotyp:=1;
                    end;
                  end;
              ':':autolist:=not autolist;
              '\':begin
                    s:=general.logspath+'slog'+cstr(usern)+'.log';
                    printf(s);
                    if (nofile) then print('"'+s+'": file not found.');
                    pausescr(FALSE);
                  end;
            end;
          end;
      '*','A','B','C','D','E','F','G','H','I','J','K','L','M',
      'N','P','R','O','T','V','W','X','Y','1','2','3','4','5','+','^':
          begin
            if (((thisuser.sl<=user.sl) or (thisuser.dsl<=user.dsl)) and
               (usernum<>1) and (usernum<>usern)) then begin
               sysoplog('Tried to modify '+caps(user.name)+' #'+cstr(usern));
               print('Access denied.');
               nl;
               pausescr(FALSE);
            end else begin
              save1:=save; save:=TRUE;
              case c of
                '+':cstuff(15,3,user);
                '^':if (deleted in user.sflags) then begin
                      print('User is currently deleted.'^M^J);

                      if pynq('Restore this user? ') then begin
                        InsertIndex(user.name, usern, FALSE, FALSE);
                        InsertIndex(user.realname, usern, TRUE, FALSE);
                        inc(Todaynumusers);
                        savegeneral(TRUE);
                        user.sflags:=user.sflags-[deleted];
                      end else
                        save:=save1;
                    end else
                      if (fnodeletion in user.flags) then begin
                        print('Access denied - This user is protected from deletion.');
                        sysoplog('* Attempt to delete user: '+caps(user.name)+
                                 ' #'+cstr(usern));
                        nl; pausescr(FALSE);
                        save:=save1;
                      end else begin
                        nl;
                        if pynq('*DELETE* this user? ') then delusr
                        else save:=save1;
                      end;
                '*':begin
                      autoval(user,usern);
                      ssm(abs(usern),'You were validated on '+date+' '+time+'.');
                    end;
               'V':begin
                      if lockedout in user.sflags then user.sflags:=user.sflags-[lockedout]
                         else user.sflags:=user.sflags+[lockedout];
                      if (lockedout in user.sflags) then begin
                        print('User is now locked out.'^M^J);

                        print('Each time the user logs on from now on, a text file will');
                        print('be displayed before user is terminated.'^M^J);

                        prt('Enter lockout filename: ');
                        mpl(8); input(ii,8);
                        if (ii='') then user.sflags:=user.sflags-[lockedout]
                        else begin
                          user.lockedfile:=ii;
                          sysoplog('Locked '+unam+' out: Lockfile "'+ii+'"');
                        end;
                      end;
                      if not (lockedout in user.sflags) then
                        print('User is no longer locked out of system.');
                      nl;
                      pausescr(FALSE);
                    end;
                'C':cstuff(1,3,user);
                'D':cstuff(4,3,user);
                'M':chhdsl;
                'O':chhflags;
                'N':begin
                      repeat
                        prt('Which AR flag? <CR>=Quit : ');
                        onek(c,'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M);
                        if (c<>^M) then
                          if (not (c in thisuser.ar)) and not (so) then begin
                            sysoplog('Tried to give '+caps(user.name)+
                                     ' #'+cstr(usern)+' AR flag "'+c+'"');
                            print('Access denied.'^G)
                          end else
                            if (c in ['A'..'Z']) then
                              if (c in user.ar) then user.ar:=user.ar-[c]
                                                else user.ar:=user.ar+[c];
                      until (c=^M) or (hangup);
                      c:=#0;
                    end;
                'P':begin
                      cstuff(2,3,user);
                      cstuff(12,3,user);
                    end;
                'H':cstuff(6,3,user);
                'F':begin
                      print('New SysOp Note: ');
                      prt(':'); mpl(35);
                      inputwn1(user.note, 35, 'C', next);
                    end;
                'T':begin
                      print('New Laston date (MM/DD/YYYY):');
                      prt(':'); mpl(8);
                      inputformatted(s,'##/##/####',TRUE);
                      if (s<>'') then user.laston:= date2pd(s);
                    end;
                '-':cstuff(15,3,user);
                'A':renusr;
                'R':cstuff(8,3,user);
                'B':begin
                      s := user.realname;
                      cstuff(10,3,user);
                      if (user.realname <> s) then
                        begin
                          InsertIndex(s, usern, TRUE, TRUE);
                          InsertIndex(user.realname, usern, TRUE, FALSE);
                        end;
                    end;
                'K':cstuff(27,3,user);
                'L':chhsl;
                'G':cstuff(5,3,user);
                'I':cstuff(13,3,user);
                'E':cstuff(14,3,user);
                'W':begin
                      print('Enter new password.'); prt(':'); input(s,20);
                      if (s<>'') then user.pw := CRC32(s);
                    end;
                'Y':begin
                      print('Enter new startout menu.');
                      prt(':'); inputwn1(user.userstartmenu,8,'U',next);
                    end;
                '1'..'5':chrecords(ord(c)-48);
               'X':begin
                     print('Enter new caller id string.');
                     prt(':'); input(s,20);
                     if (s <> '') then user.callerid := s;
                    end;
                'J':begin
                      repeat
                        print(^M^J'^11. Trapping status: '+
                          aonoff((trapactivity in user.sflags),
                          '^7'+aonoff((trapseparate in user.sflags),
                          'Trapping to TRAP'+cstr(usern)+'.LOG',
                          'Trapping to TRAP.LOG'),
                          'Off')+aonoff(general.globaltrap,'^8 <GLOBAL>',''));
                        print('^12. Auto-chat state: '+aonoff((chatauto in user.sflags),
                          aonoff((chatseparate in user.sflags),
                          '^7Output to CHAT'+cstr(usern)+'.LOG',
                          '^7Output to CHAT.LOG'),'Off')+
                          aonoff(general.autochatopen,'^8 <GLOBAL>',''));
                        print('^13. SysOp Log state: '+aonoff((slogseparate in user.sflags),
                          '^7Logging to SLOG'+cstr(usern)+'.LOG',
                          '^3Normal output'));
                        print('^14. Alert          : '+aonoff((alert in user.flags),
                          '^7Alert',
                          '^3Normal'));

                        prt(^M^J'Select (1-4,Q=Quit) : '); onek(c,'Q12345'^M);
                        if (c in ['1'..'4']) then begin
                          nl;
                          case c of
                            '1':begin
                                  dyny:=(trapactivity in user.sflags);
                                  if pynq('Trap user activity? ['+syn((trapactivity in user.sflags))+'] : ') then
                                     user.sflags:=user.sflags+[trapactivity]
                                     else user.sflags:=user.sflags-[trapactivity];

                                  if (trapactivity in user.sflags) then begin
                                    dyny:=(trapseparate in user.sflags);
                                    if pynq('Log to separate file? ['+syn(trapseparate in user.sflags)+'] : ') then
                                       user.sflags:=user.sflags+[trapseparate]
                                       else user.sflags:=user.sflags-[trapseparate];
                                  end else
                                    user.sflags:=user.sflags-[trapseparate];
                                end;
                            '2':begin
                                  dyny:=(chatauto in user.sflags);
                                  if pynq('Auto-chat buffer open? ['+syn(chatauto in user.sflags)+'] : ') then
                                    user.sflags:=user.sflags+[chatauto]
                                    else user.sflags:=user.sflags-[chatauto];
                                  if (chatauto in user.sflags) then begin
                                    dyny:=(chatseparate in user.sflags);
                                    if pynq('Separate buffer file? ['+syn(chatseparate in user.sflags)+'] : ') then
                                     user.sflags:=user.sflags+[chatseparate]
                                     else user.sflags:=user.sflags-[chatseparate];
                                  end else
                                    user.sflags:=user.sflags-[chatseparate];
                                end;
                            '3':begin
                                  dyny:=(slogseparate in user.sflags);
                                  if pynq('Output SysOp Log separately? ['+syn(slogseparate in user.sflags)+'] : ') then
                                     user.sflags:=user.sflags+[slogseparate]
                                     else user.sflags:=user.sflags-[slogseparate];
                                end;
                            '4':if (alert in user.flags) then user.flags:=user.flags-[alert]
                                   else user.flags:=user.flags+[alert];
                           end;
                        end;
                      until ((not (c in ['1'..'5'])) or (hangup));
                      c:=#0;
                    end;
                else
                      save:=save1;
              end;
            end;
          end;
    end;
    if (usern=usernum) then
      begin
        thisuser:=user;
        if (General.CompressBases) then
          NewComptables;
      end;
  until (c='Q') or hangup;
  update_screen;
  Lasterror := IOResult;
end;

end.
