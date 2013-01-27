{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Other menu functions - generic, list, etc. }

unit menus2;

interface

uses crt, dos, overlay, common;

procedure readin;
procedure showcmds(listtype:integer);
function oksecurity(i:integer; var cmdnothid:boolean):boolean;
procedure genericmenu(t:integer);
procedure showthismenu;

implementation

procedure readin;
var filv:text;
    LastTime:longint;
    s,lcmdlistentry:astr;
    i,j:integer;
    cc:char;
    b:boolean;
begin
  cmdlist:='';
  move(MenuCommand^[noc - GlobalMenuCommands + 1],
       MenuCommand^[100 - GlobalMenuCommands + 1],
       GlobalMenuCommands * Sizeof(CommandRec));
  noc := 0;
  if (exist(curmenu)) then
    begin
      assign(filv, curmenu);
      LastTime := Timer + 2;
      repeat
        reset(filv);
        i := ioresult;
{$IFDEF MSDOS}
        asm
          int 28h
          int 28h
        end;
{$ENDIF}
{$IFDEF WIN32}
        begin
		  WriteLn('REETODO menus2 readin'); Halt;
		end;
{$ENDIF}
      until (i = 0) or (LastTime < Timer);
    end
  else
    i := 1;

  if (i <> 0) and (pos('GLOBAL.MNU',allcaps(curmenu)) = 0) then
    begin
      sysoplog(curmenu + ' is MISSING.');
      print('That menu is not available.');
      curmenu:=general.menupath+menur.fallback+'.mnu';
      assign(filv, curmenu);
      reset(filv);
      if (ioresult <> 0) then
        begin
          curmenu:=general.menupath + general.allstartmenu;
          assign(filv, curmenu);
          reset(filv);
          if (IOResult <> 0) then
            begin
              sysoplog(curmenu+' is MISSING - Hung user up.');
              print('Emergency System shutdown. Please call back later.');
              print(^M^J'Critical error; hanging up.');
              hangup:=TRUE;
            end;
        end;
    end;

  if (not hangup) then begin
    with menur do begin
      readln(filv,menuname[1]);
      readln(filv,menuname[2]);
      readln(filv,menuname[3]);
      readln(filv,directive);
      readln(filv,longmenu);
      readln(filv,menuprompt);
      readln(filv,acs);
      readln(filv,password);
      readln(filv,fallback);
      readln(filv,forcehelplevel);
      readln(filv,gencols);
      for i:=1 to 3 do readln(filv,gcol[i]);
      readln(filv,s);
      s:=allcaps(s); menuflags:=[];
      if (pos('C',s)<>0) then menuflags:=menuflags+[clrscrbefore];
      if (pos('D',s)<>0) then menuflags:=menuflags+[dontcenter];
      if (pos('N',s)<>0) then menuflags:=menuflags+[nomenuprompt];
      if (pos('P',s)<>0) then menuflags:=menuflags+[forcepause];
      if (pos('T',s)<>0) then menuflags:=menuflags+[autotime];
      if (pos('F',s)<>0) then menuflags:=menuflags+[forceline];
      if (pos('1',s)<>0) then menuflags:=menuflags+[NoGenericAnsi];
      if (pos('2',s)<>0) then menuflags:=menuflags+[NoGenericAvatar];
      if (pos('3',s)<>0) then menuflags:=menuflags+[NoGenericRIP];
      if (pos('4',s)<>0) then menuflags:=menuflags+[NoGlobalDisplayed];
      if (pos('5',s)<>0) then menuflags:=menuflags+[NoGlobalUsed];
      {if (pos('6',s)<>0) then menuflags:=menuflags+[NoShownInput];}
    end;
    menukeys:='';
    repeat
      inc(noc);
      with MenuCommand^[noc] do begin
        readln(filv,ldesc);
        readln(filv,sdesc);
        readln(filv,ckeys);
        if (ckeys = 'ENTER') then
          cc := #13
        else if (ckeys = 'UP_ARROW') then
          cc := #255
        else if (ckeys = 'DOWN_ARROW') then
          cc := #254
        else if (ckeys = 'LEFT_ARROW') then
          cc := #253
        else if (ckeys = 'RIGHT_ARROW') then
          cc := #252
        else
          if (length(ckeys)>1) then
            cc:='/'
          else
            cc:=upcase(ckeys[1]);
        if (pos(cc,menukeys)=0) then menukeys:=menukeys+cc;
        readln(filv,acs);
        readln(filv,cmdkeys);
        readln(filv,options);
        readln(filv,s);
        s:=allcaps(s); commandflags:=[];
        if (pos('H',s)<>0) then commandflags:=commandflags+[hidden];
        if (pos('U',s)<>0) then commandflags:=commandflags+[unhidden];
      end;
    until eof(filv) or (noc = 100 - GlobalMenuCommands);
    if (GlobalMenuCommands > 0) then
      begin
        move(MenuCommand^[100 - GlobalMenuCommands + 1],
             MenuCommand^[noc + 1],
             GlobalMenuCommands * Sizeof(CommandRec));
        inc(noc, GlobalMenuCommands);
      end;
    Lasterror := IOResult;
    close(filv);
    Lasterror := IOResult;

    mqarea:=FALSE; fqarea:=FALSE; vqarea:=FALSE; rqarea:=FALSE;
    lcmdlistentry:=''; j:=0;
    for i:=1 to noc do begin
      if (MenuCommand^[i].ckeys<>lcmdlistentry) then begin
        b:=(aacs(MenuCommand^[i].acs));
        if (b) then inc(j);
        if (b) then begin
          if ((MenuCommand^[i].ckeys<>'FIRSTCMD') and (MenuCommand^[i].ckeys<>'GTITLE')) then begin
            if (j<>1) then cmdlist:=cmdlist+',';
            cmdlist:=cmdlist+MenuCommand^[i].ckeys;
          end else dec(j);
        end;
        lcmdlistentry:=MenuCommand^[i].ckeys;
      end;
      if (MenuCommand^[i].cmdkeys='M#') then mqarea:=TRUE;
      if (MenuCommand^[i].cmdkeys='F#') then fqarea:=TRUE;
      if (MenuCommand^[i].cmdkeys='V#') then vqarea:=TRUE;
      if (MenuCommand^[i].cmdkeys='R#') then rqarea:=TRUE;
    end;
  end;
end;

procedure showcmds(listtype:integer);
var i,j,numrows:integer;
    s,s1:astr;

  function type1(i:integer):astr;
  begin
    type1:=mn(i,3)+mln(MenuCommand^[i].ckeys,3)+mln(MenuCommand^[i].cmdkeys,4)+
           mln(MenuCommand^[i].options,15);
  end;

  function sfl(b:boolean; c:char):char;
  begin
    if (b) then sfl:=c else sfl:='-';
  end;

begin
  abort:=FALSE; next:=FALSE;
  if (noc<>0) then begin
    case listtype of
      0:begin
          printacr('^0NN'+seperator+'Command       '+seperator+'Fl'+seperator+
                   'ACS      '+seperator+'Cmd'+seperator+'options');
          printacr('^4==:==============:==:==========:==:========================================');
          i:=1;
          while (i<=noc) and (not abort) and (not hangup) do begin
            printacr('^0'+mn(i,2)+' ^3'+mln(MenuCommand^[i].ckeys,14)+' '+
                     sfl(hidden in MenuCommand^[i].commandflags,'H')+
                     sfl(unhidden in MenuCommand^[i].commandflags,'U')+' ^9'+
                     mln(MenuCommand^[i].acs,10)+' ^3'+
                     mln(MenuCommand^[i].cmdkeys,2)+' '+
                     MenuCommand^[i].options);
            inc(i);
          end;
        end;
      1:begin
          numrows:=(noc+2) div 3;
          i:=1;
          s:='^3NN:KK-Typ-Options        ';
          s1:='^4==:======================';
          while (i<=numrows) and (i<3) do begin
            s:=s+' NN:KK-Typ-Options        ';
            s1:=s1+' ==:======================';
            inc(i);
          end;
          printacr(s);
          printacr(s1);
          i:=0;
          repeat
            inc(i);
            s:=type1(i);
            for j:=1 to 2 do
              if i+(j*numrows)<=noc then
                s:=s+' '+type1(i+(j*numrows));
            printacr('^1'+s);
          until ((i>=numrows) or (abort) or (hangup));
        end;
    end;
  end
  else print('**No Commands on this menu**');
end;

function oksecurity(i:integer; var cmdnothid:boolean):boolean;
begin
  oksecurity:=FALSE;
  if (unhidden in MenuCommand^[i].commandflags) then cmdnothid:=TRUE;
  if (not aacs(MenuCommand^[i].acs)) then exit;
  oksecurity:=TRUE;
end;

procedure genericmenu(t:integer);
var
    s:astr;
    gcolors:array [1..3] of byte;
    onlin,i,j,colsiz,numcols,maxright:integer;
    cmdnothid:boolean;

  function gencolored(const keys:astr; desc:astr; acc:boolean):astr;
  begin
    s:=desc;
    j:=pos(allcaps(keys),allcaps(desc));
    if (j<>0) and (pos('^',desc)=0) then begin
      insert('^'+cstr(gcolors[3]),desc,j+length(keys)+1);
      insert('^'+cstr(gcolors[1]),desc,j+length(keys));
      if (acc) then insert('^'+cstr(gcolors[2]),desc,j);
      if (j<>1) then
        insert('^'+cstr(gcolors[1]),desc,j-1);
    end;
    gencolored:='^'+cstr(gcolors[3])+desc;
  end;

  function semicmd(s:string; x:integer):string;
  var i,p:integer;
  begin
    i:=1;
    while (i<x) and (s<>'') do begin
      p:=pos(';',s);
      if (p<>0) then s:=copy(s,p+1,length(s)-p) else s:='';
      inc(i);
    end;
    while (pos(';',s)<>0) do s:=copy(s,1,pos(';',s)-1);
    semicmd:=s;
  end;

  function tcentered(c:integer; const s:astr):astr;
  const spacestr='                                               ';
  begin
    c:=(c div 2)-(lennmci(s) div 2);
    if (c<1) then c:=0;
    tcentered:=copy(spacestr,1,c)+s;
  end;

  procedure newgcolors(const s:string);
  var s1:string;
  begin
    s1:=semicmd(s,1); if (s1<>'') then gcolors[1]:=value(s1);
    s1:=semicmd(s,2); if (s1<>'') then gcolors[2]:=value(s1);
    s1:=semicmd(s,3); if (s1<>'') then gcolors[3]:=value(s1);
  end;

  procedure dotitles;
  var i:integer;
      b:boolean;
  begin
    b:=FALSE;
    if (clrscrbefore in menur.menuflags) then begin
      cls;
      nl; nl;
    end;
    for i:=1 to 3 do
      if (menur.menuname[i]<>'') then begin
        if (not b) then begin nl; b:=TRUE; end;
        if (dontcenter in menur.menuflags) then
          printacr(menur.menuname[i])
        else
          printacr(tcentered(maxright,menur.menuname[i]));
      end;
    nl;
  end;

  procedure getmaxright;
  var
    i:integer;
    temp:astr;
  begin
    MaxRight := 0; onlin := 0; Temp := '';
    for i := 1 to noc do
      if (MenuCommand^[i].ckeys <> 'GTITLE') then
        begin
          inc(onlin);
          if (onlin<>numcols) then
            Temp := Temp + mln(MenuCommand^[i].sdesc,colsiz)
          else
            begin
              Temp := Temp + MenuCommand^[i].sdesc;
              onlin := 0;
              j := lennmci(Temp);
              if (j > MaxRight) then
                MaxRight := j;
              Temp := '';
            end;
        end
      else
        begin
          Temp := '';
          onlin := 0;
        end;
  end;

  procedure gen_tuto;
  var i,j:integer;
      b:boolean;
  begin
    GetMaxRight;
    dotitles;
    i := 0;
    if (NoGlobalDisplayed in menur.menuflags) or (NoGlobalUsed in menur.menuflags) then
      dec(noc, GlobalMenuCommands);
    while (i < noc) and (not abort) do begin
      inc(i);
      b:=oksecurity(i,cmdnothid);
      if (((b) or (unhidden in MenuCommand^[i].commandflags)) and
          (not (hidden in MenuCommand^[i].commandflags))) then
        if (MenuCommand^[i].ckeys='GTITLE') then
          begin
            printacr(MenuCommand^[i].ldesc);
            if (MenuCommand^[i].options<>'') then newgcolors(MenuCommand^[i].options);
          end
        else
          if (MenuCommand^[i].ldesc<>'') then
            printacr(gencolored(MenuCommand^[i].ckeys,MenuCommand^[i].ldesc,b));
    end;
    if (NoGlobalDisplayed in menur.menuflags) or (NoGlobalUsed in menur.menuflags) then
      inc(noc, GlobalMenuCommands);
  end;

  procedure stripc(var s1:astr);
  var s:astr;
      i:integer;
  begin
    s:=''; i:=1;
    while (i<=length(s1)) do begin
      if (s1[i]='^') then inc(i) else s:=s+s1[i];
      inc(i);
    end;
    s1:=s;
  end;

  procedure gen_norm;
  var s1:astr;
      Temp:astr;
      i,j:integer;
      b:boolean;
  begin
    s1:=''; onlin:=0; Temp := '';
    GetMaxRight;

    onlin := 0; Temp := '';
    i := 0; abort := FALSE;

		dotitles;

    if (NoGlobalDisplayed in menur.menuflags) or (NoGlobalUsed in menur.menuflags) then
      dec(noc, GlobalMenuCommands);

    while (i < noc) and (not abort) do begin
      inc(i);
      b:=oksecurity(i,cmdnothid);
      if (((b) or (unhidden in MenuCommand^[i].commandflags)) and
          (not (hidden in MenuCommand^[i].commandflags))) then begin
        if (MenuCommand^[i].ckeys='GTITLE') then begin
          if (onlin<>0) then printacr(Temp);
          printacr(tcentered(MaxRight,MenuCommand^[i].ldesc));
          Temp := '';
          onlin:=0;
          if (MenuCommand^[i].options<>'') then newgcolors(MenuCommand^[i].options);
        end else begin
          if (MenuCommand^[i].sdesc<>'') then begin
            inc(onlin); s1:=gencolored(MenuCommand^[i].ckeys,MenuCommand^[i].sdesc,b);
            if (onlin<>numcols) then s1:=mln(s1,colsiz);
            Temp := Temp + s1;
          end;
          if (onlin=numcols) then begin
            onlin:=0;
            printacr(Temp);
            Temp := '';
          end;
        end;
      end;
    end;
    if (NoGlobalDisplayed in menur.menuflags) or (NoGlobalUsed in menur.menuflags) then
      inc(noc, GlobalMenuCommands);
    if (onlin > 0) then printacr(Temp);
  end;


begin
  for i:=1 to 3 do gcolors[i]:=menur.gcol[i];
  numcols:=menur.gencols;
  case numcols of
    2:colsiz:=39; 3:colsiz:=25; 4:colsiz:=19;
    5:colsiz:=16; 6:colsiz:=12; 7:colsiz:=11;
  end;
  if (numcols*colsiz>=thisuser.linelen) then
    numcols:=thisuser.linelen div colsiz;
  abort:=FALSE; next:=FALSE;
  displayingmenu:=TRUE;
  if (t=2) then gen_norm else gen_tuto;
  displayingmenu:=FALSE;
end;

procedure showthismenu;
var s:astr;
begin
  case chelplevel of
    2:begin
        displayingmenu:=TRUE;
        nofile:=TRUE; s:=menur.directive;
        if (s<>'') then
          begin
            if (pos('@S',s) > 0) then
              printf(substitute(s,'@S',cstr(thisuser.sl)));
            if (nofile) then
              printf(substitute(s,'@S',''));
          end;
        displayingmenu:=FALSE;
      end;
    3:begin
        nofile:=TRUE; s:=menur.longmenu;
        if (s<>'') then begin
          if (pos('@C',s)<>0) then
            printf(substitute(s,'@C',currentconf));
          if (nofile) and (pos('@S',s)<>0) then
            printf(substitute(s,'@S',cstr(thisuser.sl)));
          if (nofile) then printf(substitute(s,'@S',''));
        end;
      end;
  end;
  if ((nofile) and (chelplevel in [2,3])) then genericmenu(chelplevel);
end;

end.
