{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ SysOp functions: Menu editor }

unit sysop7;

interface

uses crt, dos, overlay, common;

procedure menu_edit;

implementation

uses sysop7m, file9, menus2, sysop1;

var menuchanged:boolean;
    x,y:integer;

procedure menu_edit;
const showcmdtype:integer=1;
      menudata:boolean=FALSE;
var i:integer;
    c:char;
    filv:text;
    s,scurmenu:astr;

  procedure makenewfile(const fn:astr);                 (* make a new command list *)
  var f:text;
  begin
    assign(f,fn);
    rewrite(f);
    if (ioresult=0) then begin
      writeln(f,'New Renegade Menu');
      writeln(f,'');
      writeln(f,'');

      writeln(f,'');
      writeln(f,'');
      writeln(f,'Command? ');
      writeln(f,'');
      writeln(f,'');
      writeln(f,'MAIN');
      writeln(f,'0');
      writeln(f,'4');
      writeln(f,'4');
      writeln(f,'3');
      writeln(f,'5');
      writeln(f,'T');

      writeln(f,'(Q)uit back to the main menu');
      writeln(f,'(Q)uit to main');
      writeln(f,'Q');
      writeln(f,'');
      writeln(f,'-^');
      writeln(f,'main');
      writeln(f,'');
      close(f);
    end;
    Lasterror := IOResult;
  end;

  procedure newcmd(n:integer);                          { new command stuff }
  begin
    with MenuCommand^[n] do begin
      ldesc:='(XXX)New Renegade Command';
      sdesc:='(XXX)New Cmd';
      ckeys:='XXX';
      acs:='';
      cmdkeys:='-L';
      options:='';
      commandflags:=[];
    end;
  end;

  procedure moveinto(i1,i2:integer);
  begin
    MenuCommand^[i1]:=MenuCommand^[i2];
  end;

  procedure mes;
  var s:astr;
      i:integer;
  begin
    rewrite(filv);
    with menur do begin
      writeln(filv,menuname[1]);
      writeln(filv,menuname[2]);
      writeln(filv,menuname[3]);
      writeln(filv,directive);
      writeln(filv,longmenu);
      writeln(filv,menuprompt);
      writeln(filv,acs);
      writeln(filv,password);
      writeln(filv,fallback);
      writeln(filv,forcehelplevel);
      writeln(filv,gencols);
      for i:=1 to 3 do writeln(filv,gcol[i]);
      s:='';
      if (clrscrbefore in menuflags) then s:=s+'C';
      if (dontcenter in menuflags) then s:=s+'D';
      if (nomenuprompt in menuflags) then s:=s+'N';
      if (forcepause in menuflags) then s:=s+'P';
      if (autotime in menuflags) then s:=s+'T';
      if (forceline in menuflags) then s:=s+'F';
      if (NoGenericAnsi in menuflags) then s:=s+'1';
      if (NoGenericAvatar in menuflags) then s:=s+'2';
      if (NoGenericRIP in menuflags) then s:=s+'3';
      if (NoGlobalDisplayed in menuflags) then s:=s+'4';
      if (NoGlobalUsed in menuflags) then s:=s+'5';
      writeln(filv,s);
    end;
    for i:=1 to noc do begin
      with MenuCommand^[i] do begin
        writeln(filv,ldesc);
        writeln(filv,sdesc);
        writeln(filv,ckeys);
        writeln(filv,acs);
        writeln(filv,cmdkeys);
        writeln(filv,options);
        s:='';
        if (hidden in commandflags) then s:=s+'H';
        if (unhidden in commandflags) then s:=s+'U';
        writeln(filv,s);
      end;
    end;
    close(filv);
    sysoplog('* Saved menu file: '+scurmenu);
    Lasterror := IOResult;
  end;

  procedure med;
  begin
    prt('Delete menu file: '); mpl(8); input(s,8);
    s:=general.menupath+s+'.MNU';
    if exist(s) then begin
      print(^M^J'Menu file: ^4' + '"' + s + '"');
      if pynq('Delete it? ') then begin
        sysoplog('* Deleted menu file: "'+s+'"');
        kill(s);
      end;
    end;
  end;

  procedure mei;
  begin
    prt('Insert menu file: '); mpl(8); input(s,8);
    s:=general.menupath+allcaps(s)+'.MNU';
    if not (exist(s)) then
      begin
        sysoplog('* Created new menu file: "'+s+'"');
        makenewfile(s);
      end;
  end;

  procedure mem;
  var i,j,k:integer;
      c:char;
      b:byte;
      bb:boolean;

    procedure memd(i:integer);                   (* delete command from list *)
    var x:integer;
    begin
      if (i>=1) and (i<=noc) then begin
        for x:=i+1 to noc do MenuCommand^[x-1]:=MenuCommand^[x];
        dec(noc);
      end;
    end;

    procedure memi(i,y:integer);             (* insert a command into the list *)
    var x:integer;
        s:astr;
    begin
      if (i>=1) and (i<=noc+1) and (noc<100) then begin
        inc(noc);
        if (i<>noc) then
          for x:=noc downto i do MenuCommand^[x]:=MenuCommand^[x-1];
        if (y < 1) then
          newcmd(i)
        else
          MenuCommand^[i] := MenuCommand^[y];
      end;
    end;

    procedure memp;
    var i,j,k:integer;
    begin
      prt('Move which command? (1-'+cstr(noc)+') : '); inu(i);
      if ((not badini) and (i>=1) and (i<=noc)) then begin
        prt('Move before which command? (1-'+cstr(noc+1)+') : '); inu(j);
        if ((not badini) and (j>=1) and (j<=noc+1) and
            (j<>i) and (j<>i+1)) then begin
          memi(j,0);
          if j>i then k:=i else k:=i+1;
          MenuCommand^[j]:=MenuCommand^[k];
          if j>i then memd(i) else memd(i+1);
          menuchanged:=TRUE;
        end;
      end;
    end;

    function sfl(b:boolean; c:char):char;
    begin
      if (b) then sfl:=c else sfl:='-';
    end;

  begin
    prt('Modify menu file: '); mpl(8); input(s,8);
    if exist(general.menupath+s+'.MNU') then begin
      scurmenu:=s;
      assign(filv, general.menupath+s+'.MNU');
      curmenu:=general.menupath+scurmenu+'.MNU';
      if (exist(curmenu)) then begin
        readin;
        menuchanged:=FALSE;
        repeat
          if (c<>'?') then begin
            cls;
            abort:=FALSE; next:=FALSE; mciallowed:=FALSE;
            if (menudata) then begin
              printacr('^3Menu filename: '+scurmenu);
              with menur do begin
                printacr('^11. Menu titles   :'+menuname[1]);
                if (menuname[2]<>'') then
                  printacr('   Menu title #2 :'+menuname[2]);
                if (menuname[3]<>'') then
                  printacr('   Menu title #3 :'+menuname[3]);
                printacr('^12. Help files    :'+
                      aonoff((directive=''),'*Generic*',directive)+' / '+
                      aonoff((longmenu=''),'*Generic*',longmenu));
                printacr('^13. Menu Prompt   :'+menuprompt);
                mciallowed:=TRUE;
                printacr('^3(^1' + menuprompt + '^3)');
                mciallowed:=FALSE;
                printacr('^14. ACS required  :"'+acs+'"');
                printacr('5. Password      :'+
                      aonoff((password=''),'*None*',password));
                printacr('6. Fallback menu :'+
                      aonoff((fallback=''),'*None*',fallback));
                printacr('7. Forced ?-level:'+
                      aonoff((forcehelplevel=0),'None',cstr(forcehelplevel)));
                printacr('8. Generic info  :'+cstr(gencols)+' cols - '+
                      cstr(gcol[1])+'/'+cstr(gcol[2])+'/'+cstr(gcol[3]));
                printacr('9. Flags         :'+
                      sfl((clrscrbefore in menuflags),'C')+
                      sfl((dontcenter in menuflags),'D')+
                      sfl((nomenuprompt in menuflags),'N')+
                      sfl((forcepause in menuflags),'P')+
                      sfl((autotime in menuflags),'T')+
                      sfl((forceline in menuflags),'F')+
                      sfl((NoGenericAnsi in menuflags),'1')+
                      sfl((NoGenericAvatar in menuflags),'2')+
                      sfl((NoGenericRIP in menuflags),'3')+
                      sfl((NoGlobalDisplayed in menuflags),'4')+
                      sfl((NoGlobalUsed in menuflags),'5'));
                printacr('^1Q. Quit');
              end;
            end else
              showcmds(showcmdtype);
          end;
          mciallowed:=TRUE;
          prt(^M^J'Menu editor (?=help) : ');
          onek(c,'QDCILMPSTX123456789?'^M);
          case c of
            '?':begin
                  print(^M^J'^1<CR>Redisplay screen');
                  lcmds(20,3,'Delete command','Position command');
                  lcmds(20,3,'Insert command','Copy command');
                  lcmds(20,3,'Modify commands','XMenu data/command data');
                  lcmds(20,3,'Short generic menu','Long generic menu');
                  lcmds(20,3,'Toggle display','Quit and save');
                end;
            'C':if (noc<100) then begin
                  prt('Copy which command? (1-'+cstr(noc)+') : ');
                  inu(y);
                  if (not badini) and (y >= 1) and (y <= noc) then
                    begin
                      prt('Copy before which command? (1-'+cstr(noc+1)+') : ');
                      inu(i);
                      if (not badini) and (i>=1) and (i<=noc+1) then begin
                        prt('Copy how many times? (1-'+cstr(100-noc)+') [1] : ');
                        inu(j);
                        if (badini) then j:=1;
                        if (j>=1) and (j<=100-noc) then begin
                          for k:=1 to j do
                            begin
                              if (i <= y) then
                                inc(y);
                              memi(i,y);
                            end;
                          menuchanged:=TRUE;
                        end;
                      end;
                    end;
                end else
                  begin
                    print('^7You already have 100 commands, delete some to make room.'^M^J);
                    pausescr(FALSE);
                  end;
            'D':begin
                  prt('Delete which command? (1-'+cstr(noc)+') : '); ini(b);
                  if (not badini) and (b>=1) and (b<=noc) then begin
                    memd(b);
                    menuchanged:=TRUE;
                  end;
                end;
            'I':if (noc<100) then begin
                  prt('Insert before which command? (1-'+cstr(noc+1)+') : ');
                  inu(i);
                  if (not badini) and (i>=1) and (i<=noc+1) then begin
                    prt('Insert how many commands? (1-'+cstr(100-noc)+') [1] : ');
                    inu(j);
                    if (badini) then j:=1;
                    if (j>=1) and (j<=100-noc) then begin
                      for k:=1 to j do memi(i,0);
                      menuchanged:=TRUE;
                    end;
                  end;
                end else
                  begin
                    print('^7You already have 100 commands, delete some to make room.'^M^J);
                    pausescr(FALSE);
                  end;
            'L':begin
                  genericmenu(3);
                  pausescr(FALSE);
                end;
            'M':memm(scurmenu,menuchanged);
            'P':memp;
            'S':begin
                  genericmenu(2);
                  pausescr(FALSE);
                end;
            'T':showcmdtype:=1-showcmdtype;  {* toggle between 0 and 1 *}
            'X':menudata:=not menudata;
            '1':begin
                  print(^M^J'^5Up to THREE menu titles are allowed.');
                  print('Just leave unwanted titles set to NULL.');
                  for i:=1 to 3 do begin
                    prt(^M^J'New menu title #'+cstr(i)+': ');
                    inputwnwc(menur.menuname[i],sizeof(menur.menuname[1]) -1,menuchanged);
                  end;
                end;
            '2':begin
                  prt(^M^J'New file displayed for help: '); mpl(12);
                  inputwn(menur.directive,sizeof(menur.directive)-1,menuchanged);
                  menur.directive:=allcaps(menur.directive);
                  prt(^M^J'New file displayed for extended help: '); mpl(12);
                  inputwn(menur.longmenu,sizeof(menur.longmenu)-1,menuchanged);
                  menur.longmenu:=allcaps(menur.longmenu);
                  nl;
                end;
            '3':begin
                  prt(^M^J'New menu prompt: ');
                  inputwnwc(menur.menuprompt,sizeof(menur.menuprompt)-1,menuchanged);
                end;
            '4':begin
                  prt(^M^J'New menu ACS: '); mpl(20);
                  inputwn(menur.acs,20,menuchanged);
                end;
            '5':begin
                  prt(^M^J'New password: '); mpl(15);
                  inputwn1(menur.password,sizeof(menur.password)-1,'u',menuchanged);
                end;
            '6':begin
                  prt(^M^J'New fallback menu: '); mpl(8);
                  inputwn1(menur.fallback,8,'u',menuchanged);
                end;
            '7':begin
                  prt(^M^J'New forced menu help-level (1-3,0=None) ['+
                    cstr(menur.forcehelplevel)+'] : ');
                  ini(b);
                  if ((not badini) and (b in [0..3])) then begin
                    menuchanged:=TRUE;
                    menur.forcehelplevel:=b;
                  end;
                end;
            '8':begin
                  repeat
                    print(^M^J'^1C. Generic columns  :'+cstr(menur.gencols));
                    print('1. Bracket color    :'+cstr(menur.gcol[1]));
                    print('2. Command color    :'+cstr(menur.gcol[2]));
                    print('3. Description color:'+cstr(menur.gcol[3]));
                    print('S. Show menu'^M^J);
                    prt('Select (CS,1-3,Q=Quit) : '); onek(c,'QCS123'^M);
                    nl;
                    if (c='S') then genericmenu(2);
                    if (c in ['C','1'..'3']) then begin
                      case c of
                        'C':prt('New number of generic columns (1-7) ['+
                                cstr(menur.gencols)+'] : ');
                      else
                            prt('New generic menu color '+c+' (0-9) ['+
                                cstr(menur.gcol[ord(c)-48])+'] : ');
                      end;
                      ini(b);
                      if (not badini) then
                        case c of
                          'C':if (b in [1..7]) then begin
                                menuchanged:=TRUE;
                                menur.gencols:=b;
                              end;
                        else
                              if (b in [0..9]) then begin
                                menuchanged:=TRUE;
                                menur.gcol[ord(c)-48]:=b;
                              end;
                        end;
                    end;
                  until ((not (c in ['C','S','1'..'3'])) or (hangup));
                  c:=#0;
                end;
            '9':begin
                  nl;
                  lcmds(17,3,'Clear screen','Don''t center titles');
                  lcmds(17,3,'No menu prompt','Pause before display');
                  lcmds(17,3,'Time display','Force line input');
                  lcmds(17,3,'1 No ANS prompt','2 No AVT prompt');
                  lcmds(17,3,'3 No RIP prompt','4 No Global Disp');
                  lcmds(17,3,'5 No global use','');
                  nl;

                  prt('Choose : '); onek(c,'QCDNPTF12345'^M);
                  bb:=menuchanged; menuchanged:=TRUE;
                  with menur do
                    case c of
                      'F':if (forceline in menuflags) then
                            menuflags:=menuflags-[forceline]
                          else
                            menuflags:=menuflags+[forceline];
                      'C':if (clrscrbefore in menuflags) then
                            menuflags:=menuflags-[clrscrbefore]
                       else menuflags:=menuflags+[clrscrbefore];
                      'D':if (dontcenter in menuflags) then
                            menuflags:=menuflags-[dontcenter]
                       else menuflags:=menuflags+[dontcenter];
                      'N':if (nomenuprompt in menuflags) then
                            menuflags:=menuflags-[nomenuprompt]
                       else menuflags:=menuflags+[nomenuprompt];
                      'P':if (forcepause in menuflags) then
                            menuflags:=menuflags-[forcepause]
                       else menuflags:=menuflags+[forcepause];
                      'T':if (autotime in menuflags) then
                            menuflags:=menuflags-[autotime]
                       else menuflags:=menuflags+[autotime];
                      '1':if (NoGenericAnsi in menuflags) then
                            menuflags:=menuflags-[NoGenericAnsi]
                       else menuflags:=menuflags+[NoGenericAnsi];
                      '2':if (NoGenericAvatar in menuflags) then
                            menuflags:=menuflags-[NoGenericAvatar]
                       else menuflags:=menuflags+[NoGenericAvatar];
                      '3':if (NoGenericRIP in menuflags) then
                            menuflags:=menuflags-[NoGenericRIP]
                       else menuflags:=menuflags+[NoGenericRIP];
                      '4':if (NoGlobalDisplayed in menuflags) then
                            menuflags:=menuflags-[NoGlobalDisplayed]
                       else menuflags:=menuflags+[NoGlobalDisplayed];
                      '5':if (NoGlobalUsed in menuflags) then
                            menuflags:=menuflags-[NoGlobalUsed]
                       else menuflags:=menuflags+[NoGlobalUsed];
                    else
                          menuchanged:=bb;
                    end;
                  c:=#0;
                end;
          end;
        until ((c='Q') or (hangup));
        if (menuchanged) then begin
          print('Saving menu.......');
          mes;
        end;
      end;
    end;
    Lasterror := IOResult;
  end;

begin
  noc:=0;
  GlobalMenuCommands := 0;

  repeat
    abort:=FALSE;
    if (c<>'?') then begin
      cls;
      print('^3Renegade Menu Editor^1'^M^J);
      dir(general.menupath,'*.mnu',FALSE);
    end;
    prt(^M^J'Menu editor (?=help) : ');
    onek(c,'QDIM?'^M);
    nl;
    case c of
      '?':begin
            print('^1<CR>Redisplay screen');
            lcmds(17,3,'Delete menu file','Insert menu file');
            lcmds(17,3,'Modify menu file','Quit and save');
          end;
      'D':med;
      'I':mei;
      'M':mem;
    end;
  until (c='Q') or (hangup);

  curmenu := general.menupath + 'global.mnu';
  if (exist(curmenu)) then
    begin
      readin;
      GlobalMenuCommands := noc;
      {if (GlobalMenuCommands > 0) then
        move(MenuCommand^[1],
             MenuCommand^[100 - GlobalMenuCommands + 1],
             GlobalMenuCommands * Sizeof(CommandRec));}
    end;

  Lasterror := IOResult;
end;

end.
