{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit execbat;

interface

uses crt, dos, overlay, common, myio;

var
  sx,sy:byte;
  savcurwind:integer;

procedure ExecWindow(var ok:boolean; const dir,batline:astr; oklevel:integer;
                     var rcode:byte);
procedure execbatch(var ok:boolean; dir, batline:astr; oklevel:integer;
                    var rcode:byte; windowed:boolean);
procedure shel(const s:astr);
procedure shel2(x:boolean);

implementation

var
  CurInt21 : Pointer;
  WindPos : Word;
  WindLo : Word;
  WindHi : Word;
  WindAttr : Byte;

{$IFDEF MSDOS}
  {$L EXECWIN}
{$ENDIF}
  procedure SetCsInts; {$IFDEF MSDOS}external;{$ENDIF}
{$IFDEF WIN32}
  begin
    WriteLn('REETODO execbat.SetCsInts');
	Halt;
  end;
{$ENDIF}
  
  procedure NewInt21; {$IFDEF MSDOS}external;{$ENDIF}
{$IFDEF WIN32}
  begin
    WriteLn('REETODO execbat.NewInt21');
	Halt;
  end;
{$ENDIF}

{$IFDEF MSDOS}
procedure ExecWindow(var ok:boolean; const dir,batline:astr; oklevel:integer;
                    var rcode:byte);
var oldwindowon:boolean;
    oldcurwindow:byte;
    s:string[1];

    {-Exec a program in a window}
{$IFDEF Ver70}
  var
    TmpInt21 : Pointer;
{$ENDIF}
  begin
    oldcurwindow:=general.curwindow;
    oldwindowon:=general.windowon;
    general.windowon:=TRUE;

    sx:=wherex; sy:=wherey;
    savescreen(wind);

    clrscr;

    status_screen(1,'',FALSE,s);

    {Store global copies of window data for interrupt handler}
    WindAttr := 7;
    WindLo := WindMin;
    WindHi := WindMax;

    {Assure cursor is in window}
    inline
    (
     {;get cursor pos}
     $B4/$03/                     {  mov ah,3}
     $30/$FF/                     {  xor bh,bh}
     $CD/$10/                     {  int $10}
     {;assure it's within window}
     $8B/$0E/>WindLo/             {  mov cx,[>windlo]}
     $38/$EE/                     {  cmp dh,ch ;row above minimum?}
     $73/$02/                     {  jae okxlo ;jump if so}
     $88/$EE/                     {  mov dh,ch}
     {okxlo:}
     $38/$CA/                     {  cmp dl,cl ;col above minimum?}
     $73/$02/                     {  jae okylo ;jump if so}
     $88/$CA/                     {  mov dl,cl}
     {okylo:}
     $8B/$0E/>WindHi/             {  mov cx,[>windhi]}
     $38/$EE/                     {  cmp dh,ch ;row below maximum?}
     $76/$02/                     {  jbe okxhi ;jump if so}
     $88/$EE/                     {  mov dh,ch}
     {okxhi:}
     $38/$CA/                     {  cmp dl,cl ;col below maximum?}
     $76/$02/                     {  jbe okyhi ;jump if so}
     $88/$CA/                     {  mov dl,cl}
     {okyhi:}
     $89/$16/>WindPos/            {  mov [>windpos],dx ;save current position}
     {;position cursor}
     $B4/$02/                     {  mov ah,2}
     $30/$FF/                     {  xor bh,bh}
     $CD/$10);                    {  int $10}

    {Take over interrupt}
    GetIntVec($21, CurInt21);
    SetCsInts;
    SetIntVec($21, @NewInt21);

  {$IFDEF Ver70}
    {Prevent SwapVectors from undoing our int21 change}
    TmpInt21 := SaveInt21;
    SaveInt21 := @NewInt21;
  {$ENDIF}

    {Exec the program}
    execbatch(ok,dir,batline,oklevel,rcode,TRUE);

  {$IFDEF Ver70}
    SaveInt21 := TmpInt21;
  {$ENDIF}

    window(1,1,MaxDisplayCols,MaxDisplayRows);
    removewindow(wind);

    {Restore interrupt}
    SetIntVec($21, CurInt21);
    general.curwindow:=oldcurwindow;
    general.windowon:=oldwindowon;
    LastScreenSwap := timer - 5;
    status_screen(general.curwindow,'',FALSE,s);

    gotoxy(sx,sy);
  end;
{$ENDIF}
{$IFDEF WIN32}
procedure ExecWindow(var ok:boolean; const dir,batline:astr; oklevel:integer;
                    var rcode:byte);
begin
  WriteLn('REETODO execbat ExecWindow'); Halt;
end;
{$ENDIF}

procedure execbatch(var ok:boolean;     { result                     }
                    dir:astr;           { directory takes place in   }
                    batline:astr;       { .BAT file line to execute  }
                    oklevel:integer;    { DOS errorlevel for success }
                    var rcode:byte;     { errorlevel returned }
                    windowed:boolean);  { windowed? }
var bfp:text;
    odir:astr;
    bname:string[20];
begin
  bname:='TEMP'+cstr(node)+'.BAT';
  getdir(0,odir);
  dir:=fexpand(dir);
  while dir[length(dir)] = '\' do
    dec(dir[0]);
  assign(bfp,bname);
  rewrite(bfp);
  writeln(bfp,'@echo off');
  writeln(bfp,chr(ExtractDriveNumber(dir)+64)+':');
  if (dir <> '') then
    writeln(bfp,'cd '+dir);
  if not (wantout) then
    batline := batline + ' >nul';
  writeln(bfp,batline);
  writeln(bfp,':done');
  writeln(bfp,chr(ExtractDriveNumber(odir)+64)+':');
  writeln(bfp,'cd '+odir);
  writeln(bfp,'exit');
  close(bfp);

  if (wantout) and not windowed then shel(batline);

  if not (wantout) then
    bname := bname + ' >nul';

  shelldos(FALSE,bname,rcode);

  shel2(windowed);

  chdir(odir);
  kill(bname);
  if (oklevel<>-1) then ok:=(rcode=oklevel) else ok:=TRUE;
  Lasterror := IOResult;
end;

procedure shel(const s:astr);
begin
  savcurwind:=general.curwindow;
  sx:=wherex; sy:=wherey;
  setwindow(wind,1,1,80,25,7,0,0);
  clrscr;
  textbackground(1); textcolor(15); clreol;
  write(s);
  textbackground(0); textcolor(7); writeln;
end;

procedure shel2(x:boolean);
begin
    clrscr;
    removewindow(wind);
    if x then exit;
    gotoxy(sx,sy);
    LastScreenSwap := timer - 5;
    {update_screen;}
end;

end.
