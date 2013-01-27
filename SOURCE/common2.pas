{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S-,V-}

unit common2;

interface

uses crt, dos, myio, common;

procedure initport;
procedure skey1(var c:char);
procedure savegeneral(x:boolean);
procedure tleft;
procedure changeuserdatawindow;
procedure status_screen(WhichScreen:byte; const Message:astr; OneKey:boolean; var Answer:astr);
procedure update_screen;
procedure ToggleWindow(ShowIt:boolean);

implementation

uses common1, common3, timefunc, syschat;

const
  SYSKEY_LENGTH=1269;
  SYSKEY : array [1..1269] of Char = (
    #3 ,#16,'Ú',#26,'M','Ä','¿',#24,'³',#17,#25,#23,#11,'R','e','n','e',
    'g','a','d','e',' ','B','u','l','l','e','t','i','n',' ','B','o','a',
    'r','d',' ','S','y','s','t','e','m',#25,#23,#3 ,#16,'³',#24,'Ã',#26,
    '%','Ä','Â',#26,'&','Ä','´',#24,'³',' ',#14,'A','L','T','+','B',' ',
    #15,':',' ',#7 ,'T','o','g','g','l','e',' ','"','B','e','e','p','-',
    'a','f','t','e','r','-','e','n','d','"',#25,#5 ,#3 ,'³',' ',#14,'A',
    'L','T','+','N',' ',#15,':',' ',#7 ,'S','w','i','t','c','h',' ','t',
    'o',' ','n','e','x','t',' ','S','y','s','O','p',' ','w','i','n','d',
    'o','w',#25,#2 ,#3 ,'³',#24,'³',' ',#14,'A','L','T','+','C',' ',#15,
    ':',' ',#7 ,'E','n','t','e','r','/','E','x','i','t',' ','c','h','a',
    't',' ','m','o','d','e',#25,#8 ,#3 ,'³',' ',#14,'A','L','T','+','O',
    ' ',#15,':',' ',#7 ,'C','o','n','f','e','r','e','n','c','e',' ','S',
    'y','s','t','e','m',' ','t','o','g','g','l','e',#25,#5 ,#3 ,'³',#24,
    '³',' ',#14,'A','L','T','+','D',' ',#15,':',' ',#7 ,'D','u','m','p',
    ' ','s','c','r','e','e','n',' ','t','o',' ','f','i','l','e',#25,#9 ,
    #3 ,'³',' ',#14,'A','L','T','+','P',' ',#15,':',' ',#7 ,'P','r','i',
    'n','t',' ','f','i','l','e',' ','t','o',' ','t','h','e',' ','u','s',
    'e','r',#25,#7 ,#3 ,'³',#24,'³',' ',#14,'A','L','T','+','E',' ',#15,
    ':',' ',#7 ,'E','d','i','t',' ','C','u','r','r','e','n','t',' ','U',
    's','e','r',#25,#11,#3 ,'³',' ',#14,'A','L','T','+','Q',' ',#15,':',
    ' ',#7 ,'T','u','r','n',' ','o','f','f',' ','c','h','a','t',' ','p',
    'a','g','i','n','g',#25,#9 ,#3 ,'³',#24,'³',' ',#14,'A','L','T','+',
    'F',' ',#15,':',' ',#7 ,'G','e','n','e','r','a','t','e',' ','f','a',
    'k','e',' ','l','i','n','e',' ','n','o','i','s','e',#25,#4 ,#3 ,'³',
    ' ',#14,'A','L','T','+','R',' ',#15,':',' ',#7 ,'S','h','o','w',' ',
    'c','h','a','t',' ','r','e','q','u','e','s','t',' ','r','e','a','s',
    'o','n',#25,#5 ,#3 ,'³',#24,'³',' ',#14,'A','L','T','+','G',' ',#15,
    ':',' ',#7 ,'T','r','a','p','/','c','h','a','t','-','c','a','p','t',
    'u','r','i','n','g',' ','t','o','g','g','l','e','s',' ',' ',#3 ,'³',
    ' ',#14,'A','L','T','+','S',' ',#15,':',' ',#7 ,'S','y','s','O','p',
    ' ','W','i','n','d','o','w',' ','o','n','/','o','f','f',#25,#10,#3 ,
    '³',#24,'³',' ',#14,'A','L','T','+','H',' ',#15,':',' ',#7 ,'H','a',
    'n','g','u','p',' ','u','s','e','r',' ','i','m','m','e','d','i','a',
    't','e','l','y',#25,#5 ,#3 ,'³',' ',#14,'A','L','T','+','T',' ',#15,
    ':',' ',#7 ,'T','o','p','/','B','o','t','t','o','m',' ','S','y','s',
    'O','p',' ','w','i','n','d','o','w',#25,#6 ,#3 ,'³',#24,'³',' ',#14,
    'A','L','T','+','I',' ',#15,':',' ',#7 ,'T','o','g','g','l','e',' ',
    'u','s','e','r',' ','i','n','p','u','t',#25,#11,#3 ,'³',' ',#14,'A',
    'L','T','+','U',' ',#15,':',' ',#7 ,'T','o','g','g','l','e',' ','u',
    's','e','r',' ','s','c','r','e','e','n',#25,#11,#3 ,'³',#24,'³',' ',
    #14,'A','L','T','+','J',' ',#15,':',' ',#7 ,'J','u','m','p',' ','t',
    'o',' ','t','h','e',' ','O','S',#25,#14,#3 ,'³',' ',#14,'A','L','T',
    '+','V',' ',#15,':',' ',#7 ,'A','u','t','o','-','v','a','l','i','d',
    'a','t','e',' ','u','s','e','r',#25,#11,#3 ,'³',#24,'³',' ',#14,'A',
    'L','T','+','K',' ',#15,':',' ',#7 ,'K','i','l','l',' ','u','s','e',
    'r',' ','w','/','H','A','N','G','U','P','#',' ','f','i','l','e',#25,
    #4 ,#3 ,'³',' ',#14,'A','L','T','+','W',' ',#15,':',' ',#7 ,'E','d',
    'i','t',' ','U','s','e','r',' ','w','i','t','h','o','u','t',' ','n',
    'o','t','i','c','e',#25,#5 ,#3 ,'³',#24,'³',' ',#14,'A','L','T','+',
    'L',' ',#15,':',' ',#7 ,'T','o','g','g','l','e',' ','l','o','c','a',
    'l',' ','s','c','r','e','e','n',' ','d','i','s','p','l','a','y',' ',
    ' ',#3 ,'³',' ',#14,'A','L','T','+','Z',' ',#15,':',' ',#7 ,'W','a',
    'k','e',' ','u','p',' ','a',' ','s','l','e','e','p','i','n','g',' ',
    'u','s','e','r',#25,#6 ,#3 ,'³',#24,'³',' ',#14,'A','L','T','+','M',
    ' ',#15,':',' ',#7 ,'M','a','k','e','/','T','a','k','e',' ','T','e',
    'm','p',' ','S','y','s','O','p',' ','A','c','c','e','s','s',' ',' ',
    #3 ,'³',' ',#14,'A','L','T','-','#',' ',#15,':',' ',#7 ,'E','x','e',
    'c','u','t','e',' ','G','L','O','B','A','T','#','.','B','A','T',#25,
    #10,#3 ,'³',#24,'³',' ',#14,'A','L','T','+','+',' ',#15,':',' ',#7 ,
    'G','i','v','e',' ','5',' ','m','i','n','u','t','e','s',' ','t','o',
    ' ','u','s','e','r',#25,#6 ,#3 ,'³',' ',#14,'A','L','T','+','-',' ',
    #15,':',' ',#7 ,'T','a','k','e',' ','5',' ','m','i','n','u','t','e',
    's',' ','f','r','o','m',' ','u','s','e','r',#25,#5 ,#3 ,'³',#24,'Ã',
    #26,'%','Ä','Á',#26,'&','Ä','´',#24,'³',' ',#14,'C','T','R','L','+',
    'H','O','M','E',' ',#15,':',' ',#7 ,'T','h','i','s',' ','h','e','l',
    'p',' ','s','c','r','e','e','n',#25,#10,#14,'C','T','R','L','+','S',
    'Y','S','R','Q',' ',#15,':',' ',#7 ,'F','a','k','e',' ','s','y','s',
    't','e','m',' ','e','r','r','o','r',#25,#7 ,#3 ,'³',#24,'³',' ',#14,
    'S','C','R','L','C','K',#25,#3 ,#15,':',' ',#7 ,'T','o','g','g','l',
    'e',' ','c','h','a','t',' ','a','v','a','i','l','a','b','i','l','i',
    't','y',#25,#2 ,#14,'A','L','T','+','F','1','-','F','5',' ',' ',#15,
    ':',' ',#7 ,'S','y','s','O','p',' ','W','i','n','d','o','w',' ','1',
    ' ','-',' ','5',#25,#6 ,#3 ,'³',#24,'À',#26,'M','Ä','Ù',#24,#24,#24,
    #24,#24,#24,#24,#24,#24,#24,#24,#24,#24,#24,#24,#24,#24,#24,#24,#24,
    #24,#24,#24,#24,#24,#24,#24,#24,#24,#24,#24);

  WIN1_LENGTH=51;
  WIN1 : array [1..51] of Char = (
    #15,#23,#25,#27,'A','R',':',#25,#27,'N','S','L',':',#25,#4 ,'T','i',
    'm','e',':',#25,#6 ,#24,#25,#27,'A','C',':',#25,#15,'B','a','u','d',
    ':',#25,#6 ,'D','S','L',':',#25,#4 ,'N','o','d','e',':',#25,#6 ,#24);

  WIN2_LENGTH=42;
  WIN2 : array [1..42] of Char = (
    #15,#23,#25,#27,'P','H',':',#25,#18,'F','O',':',#25,#10,'T','e','r',
    'm',':',#25,#10,#24,#25,#27,'B','D',':',#25,#18,'L','O',':',#25,#10,
    'E','d','i','t',':',#25,#10,#24);
  WIN3_LENGTH=80;
  WIN3 : array [1..80] of Char = (
    #15,#23,' ','T','C',':',#25, #6,'C','T',':',#25, #6,'P','P',':',#25,
     #6,'F','S',':',#25, #6,'D','L',':',#25,#14,'F','R',':',#25, #5,'T',
    'i','m','e',':',#25, #6,#24,' ','T','T',':',#25, #6,'B','L',':',#25,
     #6,'E','S',':',#25, #6,'T','B',':',#25, #6,'U','L',':',#25,#14,'P',
    'R',':',#25, #5,'N','o','d','e',':',#25, #6,#24);
  WIN4_LENGTH=96;
  WIN4 : array [1..96] of Char = (
    #8 ,#23,' ',#15,'T','o','d','a','y',#39,'s',' ',#8 ,'³',' ',' ',#15,
    'C','a','l','l','s',':',#25,#7 ,'E','m','a','i','l',':',#25,#7 ,'D',
    'L',':',#25,#17,'N','e','w','u','s','e','r','s',':',#25,#9 ,#24,#25,
    #2 ,'S','t','a','t','s',' ',#8 ,'³',' ',' ',#15,'P','o','s','t','s',
    ':',#25,#7 ,'F','e','e','d','b',':',#25,#7 ,'U','L',':',#25,#17,'A',
    'c','t','i','v','i','t','y',':',#25,#9 ,#24);
  WIN5_LENGTH=113;
  WIN5 : array [1..113] of Char = (
    #8 ,#23,' ',#15,'S','y','s','t','e','m',' ',' ',#8 ,'³',' ',' ',#15,
    'C','a','l','l','s',':',#25,#7 ,'D','L',':',#25,#7 ,'D','a','y','s',
    ' ',':',#25,#6 ,'U','s','e','r','s',':',#25,#6 ,'D','i','s','k','f',
    'r','e','e',':',#25,#7 ,#24,' ',' ','S','t','a','t','s',' ',' ',#8 ,
    '³',' ',' ',#15,'P','o','s','t','s',':',#25,#7 ,'U','L',':',#25,#7 ,
    'H','o','u','r','s',':',#25,#6 ,'M','a','i','l',' ',':',#25,#6 ,'O',
    'v','e','r','l','a','y','s',':',#25,#7 ,#24);


procedure BiosScroll(up:boolean); assembler;
asm
  mov cx, 0
  mov dh, MaxDisplayRows
  mov dl, MaxDisplayCols
  mov bh, 7
  mov al, 2
  cmp up, 1
  je @up
  mov ah, 7 { down }
  jmp @go
  @up:
  mov ah, 6
  @go:
  int 10h
end;

procedure cpr(c1,c2:byte);
var
  r:uflags;
begin
  for r:=rlogon to rmsg do begin
    if (r in Thisuser.flags) then textattr:=c1 else textattr:=c2;
    write(copy('LCVUA*PEKM',ord(r)+1,1));
  end;
  for r:=fnodlratio to fnodeletion do begin
    if (r in Thisuser.flags) then textattr:=c1 else textattr:=c2;
    write(copy('1234',ord(r) - 19,1));
  end;
end;

procedure clear_status_box;
begin
  if General.IsTopWindow then
    window(1,1,MaxDisplayCols,2)
  else
    window(1,MaxDisplayRows - 1,MaxDisplayCols,MaxDisplayRows);
  clrscr;
  window(1,1,MaxDisplayCols,MaxDisplayRows);
end;

procedure ToggleWindow(ShowIt:boolean);
var
  SaveX, SaveY, Z:integer;
begin
  SaveX := WhereX;
  SaveY := WhereY;
  z := textattr;
  textattr := 7;
  if General.WindowOn then
    begin
      clear_status_box;
      if General.IsTopWindow then
        begin
          gotoxy(1, MaxDisplayRows);
          write(^J^J);
        end;
        {BiosScroll(TRUE);}
    end
  else
    begin
      if (General.IsTopWindow and (SaveY <= MaxDisplayRows - 2)) then
        BiosScroll(FALSE)
      else
       if (not General.IsTopWindow and (SaveY > MaxDisplayRows - 2)) then
         begin
         BiosScroll(TRUE);
         dec(SaveY,2)
         end
      else
       if General.IsTopWindow then
         dec(SaveY,2);
    end;

  General.WindowOn := not General.WindowOn;
  if ShowIt then
    update_screen;
  gotoxy(SaveX,SaveY);
  textattr := z;
end;

procedure status_screen(WhichScreen:byte; const Message:astr; OneKey:boolean; var Answer:astr);
var
  FirstRow, SecondRow, SaveX, SaveY, SaveA:byte;
  c:char;
  u:userrec;
  OldScreen:boolean;
  hf:file of historyrec;
  TodayHistory:HistoryRec;

begin
  if ((inwfcmenu or (not General.WindowOn)) and (WhichScreen < 99)) or
    (General.Networkmode and not CoSysOp) then
    exit;

  OldScreen := General.WindowOn;
  if not General.WindowOn then
    ToggleWindow(FALSE);

  tleft;

  SaveX := WhereX;
  SaveY := WhereY;
  SaveA := TextAttr;

  window(1,1,MaxDisplayCols,MaxDisplayRows);

  if General.IsTopWindow then
    FirstRow := 1
  else
    FirstRow := MaxDisplayRows - 1;

  SecondRow := FirstRow + 1;

  TextAttr := 120;

  LastScreenSwap := 0;

  CursorOn(FALSE);

  clear_status_box;

  if (WhichScreen < 99) then
    General.Curwindow := WhichScreen;

  case WhichScreen of
    1:with Thisuser do begin
        if mem[$0000:$0449]=7 then
          Update_logo(Win1,MScreenAddr[(FirstRow - 1) * 160],WIN1_LENGTH)
        else
          Update_logo(Win1,ScreenAddr[(FirstRow - 1) * 160],WIN1_LENGTH);

        gotoxy(02, FirstRow); write(caps(Name));
        gotoxy(33, FirstRow);
        for c:='A' to 'Z' do
          begin
            if (c in AR) then
              textattr := 116
            else
              textattr := 120;
            write(c);
          end;
        textattr := 120;
        gotoxy(65, FirstRow);
        if TempSysOp then
          begin
            textattr := 244;
            write(255);
            textattr := 120;
          end
        else
          write(SL);
        gotoxy(75, FirstRow); write(nsl div 60);

        gotoxy(02, SecondRow); write(Realname,' #',UserNum);
        gotoxy(33, SecondRow); cpr(116,120);
        textattr := 120;

        gotoxy(54, SecondRow); write(ActualSpeed);
        gotoxy(65, SecondRow);
        if TempSysOp then
          begin
            textattr := 244;
            write(255);
            textattr := 120;
          end
        else
          write(DSL);
        gotoxy(75, SecondRow); write(Node);
      end;
    2:with Thisuser do begin
        if mem[$0000:$0449]=7 then
          Update_logo(Win2,MScreenAddr[(FirstRow - 1) * 160],WIN2_LENGTH)
        else
          Update_logo(Win2,ScreenAddr[(FirstRow - 1) * 160],WIN2_LENGTH);

        gotoxy(02, FirstRow); write(Street);
        gotoxy(33, FirstRow); write(Ph);
        gotoxy(55, FirstRow); write(todate8(pd2date(Firston)));
        gotoxy(71, FirstRow);
          if okrip then
            write('RIP')
          else if okavatar then
            write('AVATAR')
          else if okansi then
            write('ANSI')
          else if okvt100 then
            write('VT-100')
          else
            write('NONE');

        gotoxy(02, SecondRow); write(mln(Citystate + ' ' + Zipcode,26));
        gotoxy(33, SecondRow); write(todate8(pd2date(Birthdate)),', ');

        write(Sex,' ',ageuser(thisuser.birthdate));
        gotoxy(55, SecondRow); write(todate8(pd2date(Laston)));
        gotoxy(71, SecondRow);
        if (fseditor in sflags) then
          write('FullScrn')
        else
          write('Regular');
      end;
    3:with Thisuser do begin
        if mem[$0000:$0449]=7 then
          Update_logo(Win3,MScreenAddr[(FirstRow - 1) * 160],WIN3_LENGTH)
        else
          Update_logo(Win3,ScreenAddr[(FirstRow - 1) * 160],WIN3_LENGTH);

        gotoxy(06, FirstRow); write(Loggedon);
        gotoxy(16, FirstRow); write(OnToday);
        gotoxy(26, FirstRow); write(MsgPost);
        gotoxy(36, FirstRow); write(Feedback);
        gotoxy(46, FirstRow); write(Downloads,'/',dk,'k');
        gotoxy(64, FirstRow);
        if (Downloads > 0) then
          write((Uploads / Downloads) * 100:3:0,'%')
        else
          write(0);

        gotoxy(75, FirstRow); write(nsl div 60);

        gotoxy(06, SecondRow); write(TTimeon);
        gotoxy(16, SecondRow); write(Thisuser.Credit - Thisuser.Debit);
        gotoxy(26, SecondRow); write(EmailSent);
        gotoxy(36, SecondRow); write(TimeBank);
        gotoxy(46, SecondRow); write(Uploads,'/',uk,'k');
        gotoxy(64, SecondRow);
        if (Loggedon > 0) then
          write((Msgpost / Loggedon) * 100:3:0,'%')
        else
          write(0);

        gotoxy(75, SecondRow); write(Node);
      end;
    4:begin
        assign(hf,general.datapath+'history.dat');
        reset(hf);
        if (ioresult = 2) then
          rewrite(hf)
        else
          begin
            seek(hf, filesize(hf) - 1);
            read(hf, Todayhistory);
          end;
        close(hf);
        with TodayHistory do begin
          if mem[$0000:$0449]=7 then
            Update_logo(Win4,MScreenAddr[(FirstRow - 1) * 160],WIN4_LENGTH)
          else
            Update_logo(Win4,ScreenAddr[(FirstRow - 1) * 160],WIN4_LENGTH);

          gotoxy(20, FirstRow); write(Callers);
          gotoxy(34, FirstRow); write(Email);
          gotoxy(45, FirstRow); write(Downloads,'/',dk,'k');
          gotoxy(72, FirstRow); write(NewUsers);

          gotoxy(20, SecondRow); write(Posts);
          gotoxy(34, SecondRow); write(Feedback);
          gotoxy(45, SecondRow); write(Uploads,'/',uk,'k');
          if (Active > 9999) then
            Active := 9999;
          gotoxy(72, SecondRow); write(Active,' min');
        end;
      end;
    5:with TodayHistory do begin
        if mem[$0000:$0449]=7 then
          Update_logo(Win5,MScreenAddr[(FirstRow - 1) * 160],WIN5_LENGTH)
        else
          Update_logo(Win5,ScreenAddr[(FirstRow - 1) * 160],WIN5_LENGTH);

        gotoxy(20, FirstRow); write(general.callernum);
        gotoxy(31, FirstRow); write(general.totaldloads + downloads);
        gotoxy(45, FirstRow); write(general.daysonline + 1);
        gotoxy(58, FirstRow); write(general.numusers);
        gotoxy(74, FirstRow); write((diskfree(0) div 1024) div 1024,'m');

        gotoxy(20, SecondRow); write(general.totalposts + posts);
        gotoxy(31, SecondRow); write(general.totaluloads + uploads);
        gotoxy(45, SecondRow); write((general.totalusage + active) div 60);
        loadurec(u,1);
        gotoxy(58, SecondRow);
        if (u.waiting > 0) then
          textattr := 244;
        write(u.waiting);
        textattr := 120;
        gotoxy(74, SecondRow);
        case OverlayLocation of
          0:write('Disk');
          1:write('EMS');
          2:write('XMS');
        end;
      end;
    100:begin
        gotoxy((MaxDisplayCols - length(message)) div 2, FirstRow);
        write(Message);
        LastScreenSwap := Timer;
      end;
    99:begin
        gotoxy(1, FirstRow);
        write(Message);
        if OneKey then
          Answer := upcase(readkey)
        else
          begin
            gotoxy(2, FirstRow + 1);
            write('> ');
            local_input1(Answer, MaxDisplayCols - 4, FALSE);
          end;
      end;
  end;

  if General.IsTopWindow then
    window(1,3,MaxDisplayCols,MaxDisplayRows)
  else
    window(1,1,MaxDisplayCols,MaxDisplayRows - 2);

  CursorOn(TRUE);

  if not OldScreen then
    ToggleWindow(FALSE);

  gotoxy(SaveX,SaveY);
  TextAttr := SaveA;
end;

procedure update_screen;
var
  s:string[1];
begin
  status_screen(General.CurWindow,'',FALSE,s);
end;

procedure initport;

  function driverinstalled:word; assembler;
  asm
    mov ah, 5
    mov dx, FossilPort
    pushf
    call interrupt14
    mov ah, 4
    pushf
    call interrupt14
  end;

begin
  FossilPort := liner.comport - 1;
  if localioonly then exit;

  if (DigiBoard in liner.mflags) then
    begin
      regs.ah := $1E;
      regs.dx := FossilPort;
      if (xonxoff in liner.mflags) then
        regs.bh := $3 else regs.bh := $0;
      if (ctsrts in liner.mflags) then
        regs.bl := $18 else regs.bl := $0;
      intr($14, regs);
      regs.ah := $20;
      regs.dx := FossilPort;
      regs.al := 0;
      intr($14, regs);
    end
  else
    if (driverinstalled <> $1954) then
      begin
        clrscr;
        writeln('Renegade requires a FOSSIL driver.');
        halt;
      end
    else
      asm
        xor al, al
        mov bl, liner.mflags
        and bl, 00000100b
        jz @label1
        mov al, 2
        @label1:
        and bl, 00000010b
        jz @label2
        add al, 9
        @label2:
        mov dx, FossilPort
        mov ah, $F
        pushf
        call interrupt14
      end;
  com_set_speed(Liner.InitBaud);
end;


procedure skey1(var c:char);
var s:string;
    i:integer;
    SaveX,SaveY,z,RetCode:byte;
    t:longint;
    cc:char;
    b:boolean;

begin
  if (General.Networkmode and (not CoSysOp or inwfcmenu)) then
    exit;

  SaveX := WhereX;  SaveY := WhereY;  Z := TextAttr;


  case ord(c) of
    120..129:begin  {ALT-1 to ALT-0}
               getdir(0,s);
               chdir(start_dir);
               savescreen(wind);
               clrscr;
               t:=timer;
               i := ord(c) - 119; if (i = 10) then i := 0;
               shelldos(FALSE,'globat'+chr(i + 48),RetCode);
               com_flush_rx;
               freetime:=freetime+timer-t;
               removewindow(wind);
               gotoxy(SaveX,SaveY);
               chdir(s);
             end;
    104..108:Status_Screen(ord(c) - 104 + 1,'',FALSE,s);   { ALT F1-F5     }
    114:runerror(255);                                     { CTRL-PRTSC    }
    36:begin
         savescreen(wind);
         sysopshell;                                       { ALT-J         }
         removewindow(wind);
       end;
    32:begin                                               { ALT-D         }
         Status_Screen(99,'Dump screen to what file: ',
                       FALSE,s);
         if (s<>'') then
           screendump(s);
         update_screen;
       end;
    59..68:buf:=general.macro[ord(c) - 59];                { F1 - F10      }
  end;

  if (not inwfcmenu) then begin
    case ord(c) of
    119:begin                                              { CTRL-HOME     }
              savescreen(wind);
              if mem[$0000:$0449]=7 then
                Update_logo(SYSKEY,MScreenAddr[0],SYSKEY_LENGTH)
              else
                Update_logo(SYSKEY,ScreenAddr[0],SYSKEY_LENGTH);
              cursoron(FALSE);
              c:=readkey;
              if (c = #0) then
                c:=readkey;
              cursoron(TRUE);
              removewindow(wind);
              gotoxy(SaveX,SaveY);
              update_screen;
            end;
      34:                                                  { ALT-G         }
        begin
          Status_Screen(99,'Log options - [T]rap activity [C]hat buffering',TRUE,s);
          cc:=s[1];
          with thisuser do
            case cc of
              'C':begin
                    status_screen(99,'Auto chat buffering - [O]ff [S]eparate [M]ain (CHAT.LOG)',TRUE,s);
                    cc:=s[1];
                    if (cc in ['O','S','M']) then chatfile(FALSE);
                    case cc of
                      'O':thisuser.sflags:=thisuser.sflags-[chatauto,chatseparate];
                      'S':thisuser.sflags:=thisuser.sflags+[chatauto,chatseparate];
                      'M':begin
                            thisuser.sflags:=thisuser.sflags+[chatauto];
                            thisuser.sflags:=thisuser.sflags-[chatseparate];
                          end;
                    end;
                    if (cc in ['S','M']) then chatfile(TRUE);
                  end;
              'T':begin
                    status_screen(99,'Activity trapping - [O]ff [S]eperate [M]ain (TRAP.LOG)',TRUE,s);
                    cc:=s[1];
                    if (cc in ['O','S','M']) then
                      if (trapping) then begin
                        close(trapfile);
                        trapping:=FALSE;
                      end;
                    case cc of
                      'O':thisuser.sflags:=thisuser.sflags-[trapactivity,trapseparate];
                      'S':thisuser.sflags:=thisuser.sflags+[trapactivity,trapseparate];
                      'M':begin
                            thisuser.sflags:=thisuser.sflags+[trapactivity];
                            thisuser.sflags:=thisuser.sflags-[trapseparate];
                          end;
                    end;
                    if (cc in ['S','M']) then inittrapfile;
                  end;
            end;
          update_screen;
        end;
      20:begin                                             { ALT-T         }
           if General.WindowOn then
             BiosScroll(General.IsTopWindow);
           general.istopwindow := not general.istopwindow;
           update_screen;
         end;
      31:ToggleWindow(TRUE);                               { ALT-S         }
      47:if useron then begin                              { ALT-V         }
          s[1] := #0;
          Status_Screen(99,'Enter the validation level (A-Z) for this user.',TRUE,s);
          if (s[1] in ['A'..'Z']) then
            begin
              autovalidate(thisuser,usernum,s[1]);
              Status_Screen(100,'This user has been validated.',FALSE,s);
            end
          else
            update_screen;
        end;
      18:if (useron) then begin                            { ALT-E         }
          wait(TRUE);
          savescreen(wind);
          changeuserdatawindow;
          removewindow(wind);
          update_screen;
          wait(FALSE);
        end;
      17:if (useron) then
           begin
             savescreen(wind);
             changeuserdatawindow;                         { ALT-W         }
             removewindow(wind);
             update_screen;
           end;
      49:                                                  { ALT-N         }
        if (useron) then begin
          i:=general.curwindow mod 5 + 1;
          status_screen(i,'',FALSE,s);
        end;
      23:                                                  { ALT-I         }
        if (Speed > 0) and (not com_carrier) then
          Status_Screen(100,'No carrier detected!',FALSE,s)
        else
          if (Speed > 0) then
          begin
            if (outcom) then
              if (incom) then incom:=FALSE else
                if (com_carrier) then incom:=TRUE;
            if (incom) then Status_Screen(100,'User keyboard ON.',FALSE,s)
                       else Status_Screen(100,'User keyboard OFF.',FALSE,s);
            com_flush_rx;
          end;
      16:begin                                             { ALT-Q         }
          chatcall:=FALSE; chatr:='';
          thisuser.flags:=thisuser.flags-[alert];
          update_screen;
        end;
      35:hangup:=TRUE;                                     { ALT-H         }
      24:begin                                             { ALT-O         }
           confsystem:=(not confsystem);
           if confsystem then
             Status_Screen(100,'The Conference system has been turned ON.',FALSE,s)
           else
             Status_Screen(100,'The Conference system has been turned OFF.',FALSE,s);
           newcomptables;
         end;
      130:begin                                            { ALT-MINUS     }
          b:=ch;
          ch:=TRUE;
          dec(thisuser.tltoday, 5);
          tleft;
          ch:=b;
        end;
      131:                                                 { ALT-PLUS      }
        begin
          b:=ch;
          ch:=TRUE;
          inc(thisuser.tltoday, 5);
          timewarn := FALSE;
          tleft;
          ch:=b;
        end;
      50:                                                  { ALT-M         }
        if (useron) then
          begin
            TempSysOp := not TempSysOp;
            if TempSysOp then
              Status_Screen(100,'Temporary SysOp access granted.',FALSE,s)
            else
              Status_Screen(100,'Normal access restored',FALSE,s);
            if (General.CompressBases) then
              NewComptables;
          end;
      46:                                                  { ALT-C         }
        if (ch) then begin
          ch:=FALSE;
          buf := #0;   { needed to allow chat to exit }
          chatr:='';
        end else
          chat;
      72,                                                  { Arrow up    }
      75,                                                  { Arrow left  }
      77,                                                  { Arrow Right }
      80:                                                  { Arrow Down  }
        if ((ch) or (write_msg)) then begin
          if (okavatar) then buf:=buf+^V else buf:=buf+^[+'[';
          case ord(c) of
            72:if (okavatar) then buf:=buf+^C else buf:=buf+'A';
            75:if (okavatar) then buf:=buf+^E else buf:=buf+'D';
            77:if (okavatar) then buf:=buf+^F else buf:=buf+'C';
            80:if (okavatar) then buf:=buf+^D else buf:=buf+'B';
          end;
        end;
      22:                                                  { ALT-U         }
        if (Speed > 0) and (outcom) then begin
          Status_Screen(100,'User screen and keyboard OFF',FALSE,s);
          outcom:=FALSE; incom:=FALSE;
        end else
          if (Speed > 0) and (com_carrier) then
            begin
              Status_Screen(100,'User screen and keyboard ON',FALSE,s);
              outcom:=TRUE; incom:=TRUE;
            end;
      37:                                                  { ALT-K        }
        begin
          status_screen(99,'Display what hangup file (HANGUPxx) :',FALSE,s);
          if (s<>'') then begin
						nl; nl; incom:=FALSE;
            printf('hangup'+s);
            sysoplog('Displayed hangup file HANGUP'+s);
            hangup:=TRUE;
          end;
          update_screen;
        end;
      48:                                                  { ALT-B         }
        begin
          beepend:=not beepend;
          Status_Screen(100,'SysOp next ' + onoff(beepend),FALSE,s);
          b:=ch; ch:=TRUE;
          tleft; ch:=b;
        end;
      38:                                                  { ALT-L         }
        if (wantout) then begin
          textcolor(11);
          textbackground(0);
          window(1,1,MaxDisplayCols,MaxDisplayRows);
          clrscr;
          wantout:=FALSE;
          cursoron(FALSE);
        end else begin
          wantout:=TRUE;
          cursoron(TRUE);
          writeln('Local display on.');
          update_screen;
        end;
      44:                                                  { ALT-Z         }
        begin
          Status_Screen(100,'Waking up user ...',FALSE,s);
          repeat
            outkey(^G);
            delay(500);
            asm int 28h end;
            checkhangup;
          until ((not empty) or (hangup));
          update_screen;
        end;
      19:Status_Screen(100,'Chat request: '+chatr,FALSE,s);{ ALT-R         }
      25:begin                                             { ALT-P         }
          status_screen(99,'Print what file: ',FALSE,s);
          if (s<>'') then begin
            nl; nl;
            printf(s);
            sysoplog('Displayed file '+s);
          end;
          update_screen;
        end;
      33:                                                  { ALT-F         }
        begin
          randomize;
          s := '';
          for i := 1 to random(50) do
            begin
              cc := chr(random(255));
              if not (cc in [#3,'^','@']) then
                s := s + cc;
            end;
          prompt(s);
        end;
    end;
  end;
  { any processed keys no longer used should be here }
  if (ord(c) in [16..20,22..25,31..38,44,47..50,104..108,114,119..131]) then
    c := #0;
  textattr:=z;
end;

procedure savegeneral(x:boolean);
var generalf:file of generalrec;
    i,j:byte;
    b,b2:boolean;
begin
  assign(generalf,DatFilePath+'renegade.dat');
  reset(generalf);
  if x then begin
    b:=general.windowon;
    b2:=general.istopwindow;
    j:=general.curwindow;
    read(generalf,general);
    general.windowon:=b;
    general.istopwindow:=b2;
    general.curwindow:=j;
    inc(general.callernum,Todaycallers);
    Todaycallers:=0;
    inc(general.numusers,Todaynumusers);
    Todaynumusers:=0;
    seek(generalf,0);
  end;
  write(generalf,general);
  close(generalf);
  Lasterror := IOResult;
end;

procedure setacch(c:char; b:boolean; var u:userrec);
begin
  if (b) then if (not (tacch(c) in u.flags)) then acch(c,u);
  if (not b) then if (tacch(c) in u.flags) then acch(c,u);
end;

function mrnn(i,l:integer):string;
begin
  mrnn:=mrn(cstr(i),l);
end;

procedure tleft;
var
  sx,sy,sz:integer;
begin
  if TimedOut or TimeLock then exit;
  sz := curco;
  if ((nsl <= 0) and (choptime <> 0)) then
    begin
      sysoplog('Logged user off for system event');
      print(^M^J^M^J^G'^7Shutting down for System Event.'^G^M^J);
      hangup:=TRUE;
    end;
  if (not ch) and not (fnocredits in thisuser.flags) and (General.CreditMinute > 0) and (useron) and (CreditTime > 0) and
    (AccountBalance > ((nsl div 60) + 1) * General.CreditMinute) and (not hangup) then
    begin
      { They got more credits; change their time back }
      CreditTime := 0;
      if (AccountBalance < ((nsl div 60) + 1) * General.CreditMinute) then
        inc(CreditTime, nsl - (AccountBalance div General.CreditMinute) * 60);
    end;
  if (not ch) and not (fnocredits in thisuser.flags) and (General.CreditMinute > 0) and (useron) and
     (AccountBalance < (nsl div 60) * General.CreditMinute) and
     (not invisedit) and (not hangup) then
    begin
      print(^M^J^G^G'^8Note: ^9Your online time has been adjusted due to insufficient account balance.');
      inc(CreditTime, nsl - (AccountBalance div General.CreditMinute) * 60);
    end;
  if (not timewarn) and (not ch) and (nsl < 180) and (useron) and (not invisedit) and (not hangup) then
    begin
      timewarn := TRUE;
      print(^M^J^G^G'^8Warning: ^9You have less than '+cstr(nsl div 60 + 1)+' minute'+
            Plural(nsl div 60 + 1)+' remaining online!'^M^J);
      setc(sz);
    end;
  if (not ch) and (nsl <= 0) and (useron) and (not hangup) then
    begin
      nl;
      timedout := TRUE;
      printf('notleft');
      if (nofile) then
        print ('^7You have used up all of your time.');
      nl;
      hangup := TRUE;
    end;

  checkhangup;

  if Wantout and General.WindowOn and (General.CurWindow = 1) and (not inwfcmenu) and not
    (General.Networkmode and not CoSysOp) and (LastScreenSwap = 0) then
    begin
      textattr := 120;
      sx := wherex; sy := wherey;
      window(1,1,MaxDisplayCols,MaxDisplayRows);
      if General.IsTopWindow then
        gotoxy(75, 1)
      else
        gotoxy(75, MaxDisplayRows - 1);
      write(nsl div 60,' ');
      if General.IsTopWindow then
        window(1,3,MaxDisplayCols,MaxDisplayRows)
      else
        window(1,1,MaxDisplayCols,MaxDisplayRows - 2);

      gotoxy(sx,sy);
      textattr := sz;
    end;
end;

procedure gp(i,j:integer);
var x:byte;
begin
  case j of
    0:gotoxy(58,8);
    1:gotoxy(20,7); 2:gotoxy(20,8); 3:gotoxy(20,9);
    4:gotoxy(20,10); 5:gotoxy(36,7); 6:gotoxy(36,8);
  end;
  if (j in [1..4]) then x:=5 else x:=3;
  if (i=2) then inc(x);
  if (i>0) then gotoxy(wherex+x,wherey);
end;

procedure changeuserdatawindow;
var
    s:string[39];
    oo,i,oldsl,savsl,savdsl:integer;
    c:char;
    sx,sy,ta:byte;
    done,done1:boolean;

  procedure ar_tog(c:char);
  begin
    if (c in thisuser.ar) then thisuser.ar:=thisuser.ar-[c]
      else thisuser.ar:=thisuser.ar+[c];
  end;

  procedure shd(i:integer; b:boolean);
  var j:byte;
      c:char;
  begin
    gp(0,i);
    if (b) then textcolor(14) else textcolor(9);
    case i of
      1:write('SL  :'); 2:write('DSL :'); 3:write('BL  :');
      4:write('Note:'); 5:write('AR:');   6:write('AC:');
    end;
    if (b) then begin textcolor(0); textbackground(7); end else textcolor(14);
    write(' ');
    with thisuser do
      case i of
        0:if (b) then write('ÄDoneÄ')
          else begin
            textcolor(9); write('Ä');
            textcolor(11); write('Done');
            textcolor(9); write('Ä');
          end;
        1:write(mln(cstr(sl),3));
        2:write(mln(cstr(dsl),3));
        3:write(mln(cstr(AccountBalance),5));
        4:write(mln(note,39));
        5:for c:='A' to 'Z' do begin
            if (c in ar) then textcolor(4)
              else if (b) then textcolor(0) else textcolor(7);
            write(c);
          end;
        6:if (b) then cpr($07,$70) else cpr($70,$07);
      end;
    write(' ');
    textbackground(0);
    cursoron(i in [1..4]);

    if (b) then begin
      gotoxy(26,12); textcolor(14);
      for j:=1 to 41 do write(' ');
      gotoxy(26,12);
      case i of
        0:write('Done');
        1:write('Security Level (0-255)');
        2:write('Download Security Level (0-255)');
        3:write('Account balance');
        4:write('SysOp note for this user');
        5:write('Access flags ("!" to toggle all)');
        6:write('Restrictions & special ("!" to clear)');
      end;
    end;
  end;

  procedure ddwind;
  var i:byte;
      c:char;
  begin
    cursoron(FALSE);
    textcolor(9);
    box(1,18,6,68,13); window(19,7,67,12); clrscr;
    box(1,18,6,68,11); window(19,7,67,10);

    window(1,1,MaxDisplayCols,MaxDisplayRows);
    gotoxy(20,12); textcolor(9); write('Desc:');

    for i:=0 to 6 do shd(i,FALSE);

    shd(oo,TRUE);
  end;


begin
  saveurec(thisuser, usernum);

  infield_out_fgrd:=0;
  infield_out_bkgd:=7;
  infield_inp_fgrd:=0;
  infield_inp_bkgd:=7;
  infield_arrow_exit:=TRUE;
  infield_arrow_exited:=FALSE;

  sx:=wherex; sy:=wherey; ta:=textattr; textattr := 7;
  oo:=1;

  ddwind;
  done:=FALSE;
  repeat
    infield_arrow_exited:=FALSE;
    case oo of
      0:begin
          done1:=FALSE;
          shd(oo,TRUE);
          repeat
            c:=readkey;
            case upcase(c) of
              ^M:begin done:=TRUE; done1:=TRUE; end;
              #0:begin
                   c:=readkey;
                   case ord(c) of
                     80,72:   {arrow down, up}
                       begin
                         infield_arrow_exited:=TRUE;
                         infield_last_arrow:=ord(c);
                         done1:=TRUE;
                       end;
                   end;
                 end;
            end;
          until (done1);
        end;
      1:begin
          s:=cstr(thisuser.sl); infield1(26,7,s,3);
          if (value(s)<>thisuser.sl) then
            begin
              thisuser.sl:=value(s);
              inc(thisuser.tltoday,
                  general.timeallow[thisuser.sl] - general.timeallow[thisuser.sl]);
            end;
        end;
      2:begin
          s:=cstr(thisuser.dsl); infield1(26,8,s,3);
          if (value(s)<>thisuser.dsl) then
            thisuser.dsl:=value(s);
        end;
      3:begin
          s:=cstr(AccountBalance); infield1(26,9,s,5);
          AdjustBalance(AccountBalance - value(s));
        end;
      4:begin
          s:=thisuser.note; infield1(26,10,s,39);
          thisuser.note:=s;
        end;
      5:begin
          done1:=FALSE;
          repeat
            c:=upcase(readkey);
            case c of
              #13:done1:=TRUE;
              #0:begin
                   c:=readkey;
                   case ord(c) of
                     80,72:  {arrow down,up}
                       begin
                         infield_arrow_exited:=TRUE;
                         infield_last_arrow:=ord(c);
                         done1:=TRUE;
                       end;
                   end;
                 end;
              '!':begin
                    for c:='A' to 'Z' do ar_tog(c);
                    shd(oo,TRUE);
                  end;
              'A'..'Z':begin ar_tog(c); shd(oo,TRUE); end;
            end;
          until (done1);
        end;
      6:begin
          s:='LCVUA*PEKM1234';
          done1:=FALSE;
          repeat
            c:=upcase(readkey);
            if (c=#13) then done1:=TRUE
            else
            if (c=#0) then begin
              c:=readkey;
              case ord(c) of
                80,72:  {arrow down,up}
                  begin
                    infield_arrow_exited:=TRUE;
                    infield_last_arrow:=ord(c);
                    done1:=TRUE;
                  end;
              end;
            end
            else
            if (pos(c,s)<>0) then begin
              acch(c,thisuser);
              shd(oo,TRUE);
            end
            else begin
              if (c='!') then
                for i:=1 to length(s) do setacch(s[i],FALSE,thisuser);
              shd(oo,TRUE);
            end;
          until (done1);
        end;
    end;
    if (not infield_arrow_exited) then begin
      infield_arrow_exited:=TRUE;
      infield_last_arrow:=80;  {arrow down}
    end;
    if (infield_arrow_exited) then
      case infield_last_arrow of
        80,72:begin     {arrow down,up}
          shd(oo,FALSE);
          if (infield_last_arrow=80) then begin  {arrow down}
            inc(oo);
            if (oo>6) then oo:=0;
          end else begin
            dec(oo);
            if (oo<0) then oo:=6;
          end;
          shd(oo,TRUE);
        end;
      end;
  until (done);

  gotoxy(sx,sy); textattr:=ta;
  cursoron(TRUE);
  if (general.compressbases) then newcomptables;

  saveurec(thisuser, usernum);

end;

end.

