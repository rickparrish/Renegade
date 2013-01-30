{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R+,S-,V-}

unit myio;

interface

uses crt, dos, overlay;

const
  infield_seperators:set of char=[' ','\','.'];

type
  astr=string[160];
  windowrec = array[0..8000] of byte;
  ScreenType = array [0..3999] of Byte;
  infield_special_function_proc_rec=procedure(c:char);

const
  infield_only_allow_on:boolean=FALSE;
  infield_arrow_exit:boolean=FALSE;
  infield_arrow_exited:boolean=FALSE;
  infield_arrow_exited_keep:boolean=FALSE;
  infield_special_function_on:boolean=FALSE;
  infield_arrow_exit_typedefs:boolean=FALSE;
  infield_normal_exit_keydefs:boolean=FALSE;
  infield_normal_exited:boolean=FALSE;

var
  wind:windowrec;
{$IFDEF MSDOS}
  MonitorType:byte absolute $0000:$0449;
{$ENDIF}
{$IFDEF WIN32}
  MonitorType:byte = CO80;
{$ENDIF}
{$IFDEF MSDOS}
  ScreenAddr : ScreenType absolute $B800:$0000;
  MScreenAddr : ScreenType absolute $B000:$0000;
{$ENDIF}
  ScreenSize:integer;
  MaxDisplayRows,
  MaxDisplayCols:byte;
  infield_out_fgrd,
  infield_out_bkgd,
  infield_inp_fgrd,
  infield_inp_bkgd:byte;
  infield_last_arrow,
  infield_last_normal:byte;
  infield_only_allow:string;
  infield_special_function_proc:infield_special_function_proc_rec;
  infield_special_function_keys:string;
  infield_arrow_exit_types:string;
  infield_normal_exit_keys:string;

{$IFDEF MSDOS}
procedure update_logo(var Addr1,Addr2; BlkLen:Integer);
{$ENDIF}
{$IFDEF WIN32}
procedure update_logo(data: array of char; originx, originy, datalength: integer);
{$ENDIF}
procedure cursoron(b:boolean);
procedure infield1(x,y:byte; var s:astr; len:byte);
procedure infielde(var s:astr; len:byte);
procedure infield(var s:astr; len:byte);
function l_yn:boolean;
function l_pynq(const s:astr):boolean;
procedure cwrite(const s:astr);
procedure cwriteat(x,y:integer; const s:astr);
function cstringlength(const s:astr):integer;
procedure cwritecentered(y:integer; const s:astr);
procedure box(linetype,TLX,TLY,BRX,BRY:integer);
procedure savescreen(var wind:windowrec);
procedure setwindow(var wind:windowrec; TLX,TLY,BRX,BRY,tcolr,bcolr,boxtype:integer);
procedure removewindow(var wind:windowrec);

implementation

{$IFDEF WIN32}
uses 
  RPScreen, VPSysLow;
  
var
  SavedScreen: TScreenBuf;
{$ENDIF}

{$IFDEF MSDOS}
procedure cursoron(b:boolean); assembler;
asm
  cmp b, 1
  je @turnon
  mov ch, 9
  mov cl, 0
  jmp @goforit
  @turnon:
  mov ch, 6
  mov cl, 7
  @goforit:
  mov ah,1
  int 10h
end;
{$ENDIF}
{$IFDEF WIN32}
procedure cursoron(b:boolean);
begin
  if (b) then
  begin
    RPShowCursor;
  end else
  begin
    RPHideCursor;
  end;
end;
{$ENDIF}

procedure infield1(x,y:byte; var s:astr; len:byte);
var os:astr;
    i,p,z:integer;
    sta,sx,sy:byte;
    c:char;
    ins,done,nokeyyet:boolean;

  procedure gocpos;
  begin
    gotoxy(x+p-1,y);
  end;

  procedure exit_w_arrow;
  var i:integer;
  begin
    infield_arrow_exited:=TRUE;
    infield_last_arrow:=ord(c);
    done:=TRUE;
    if (infield_arrow_exited_keep) then begin
      z:=len;
      for i:=len downto 1 do
        if (s[i]=' ') then dec(z) else i:=1;
      s[0]:=chr(z);
    end else
      s:=os;
  end;

  procedure exit_w_normal;
  var i:integer;
  begin
    infield_normal_exited:=TRUE;
    infield_last_normal:=ord(c);
    done:=TRUE;
    if (infield_arrow_exited_keep) then begin
      z:=len;
      for i:=len downto 1 do
        if (s[i]=' ') then dec(z) else i:=1;
      s[0]:=chr(z);
    end else
      s:=os;
  end;

begin
  sta:=textattr; sx:=wherex; sy:=wherey;
  os:=s;
  ins:=FALSE;
  done:=FALSE;
  infield_arrow_exited:=FALSE;
  gotoxy(x,y);
  textattr:=(infield_inp_bkgd*16)+infield_inp_fgrd;
  for i:=1 to len do write(' ');
  for i:=length(s)+1 to len do s[i]:=' ';
  gotoxy(x,y); write(s);
  p:=1; {  p:=length(s)+1;}
  gocpos;
  nokeyyet:=TRUE;
  repeat
    repeat c:=readkey
    until ((not infield_only_allow_on) or
           (pos(c,infield_special_function_keys)<>0) or
           (pos(c,infield_normal_exit_keys)<>0) or
           (pos(c,infield_only_allow)<>0) or (c=#0));

    if ((infield_normal_exit_keydefs) and
        (pos(c,infield_normal_exit_keys)<>0)) then exit_w_normal;

    if ((infield_special_function_on) and
        (pos(c,infield_special_function_keys)<>0)) then
      infield_special_function_proc(c)
    else begin
      if (nokeyyet) then begin
        nokeyyet:=FALSE;
        if (c in [#32..#255]) then begin
          gotoxy(x,y);
          for i:=1 to len do begin write(' '); s[i]:=' '; end;
          gotoxy(x,y);
        end;
      end;
      case c of
         #0:begin
              c:=readkey;
              if ((infield_arrow_exit) and (infield_arrow_exit_typedefs) and
                  (pos(c,infield_arrow_exit_types)<>0)) then exit_w_arrow
              else
              case c of
                #72,#80:if (infield_arrow_exit) then exit_w_arrow;
                #75:if (p>1) then dec(p);
                #77:if (p<len+1) then inc(p);
                #71:p:=1;
                #79:begin
                      z:=1;
                      for i:=len downto 2 do
                        if ((s[i-1]<>' ') and (z=1)) then z:=i;
                      if (s[z]=' ') then p:=z else p:=len+1;
                    end;
                #82:ins:=not ins;
                #83:if (p<=len) then begin
                      for i:=p to len-1 do begin
                        s[i]:=s[i+1];
                        write(s[i]);
                      end;
                      s[len]:=' '; write(' ');
                    end;
                #115:if (p>1) then begin
                       i:=p-1;
                       while ((not (s[i-1] in infield_seperators)) or
                             (s[i] in infield_seperators))
                             and (i>1) do
                         dec(i);
                       p:=i;
                     end;
                #116:if (p<=len) then begin
                       i:=p+1;
                       while ((not (s[i-1] in infield_seperators)) or
                             (s[i] in infield_seperators))
                             and (i<=len) do
                         inc(i);
                       p:=i;
                     end;
                #117:if (p<=len) then
                       for i:=p to len do begin
                         s[i]:=' ';
                         write(' ');
                       end;
              end;
              gocpos;
            end;
         #27:begin
               s:=os;
               done:=TRUE;
             end;
        #13:begin
              done:=TRUE;
              z:=len;
              for i:=len downto 1 do
                if (s[i]=' ') then dec(z) else i:=1;
              s[0]:=chr(z);
            end;
        #8:if (p<>1) then begin
             dec(p);
             s[p]:=' ';
             gocpos; write(' '); gocpos;
           end;
      else
            if ((c in [#32..#255]) and (p<=len)) then begin
              if ((ins) and (p<>len)) then begin
                write(' ');
                for i:=len downto p+1 do s[i]:=s[i-1];
                for i:=p+1 to len do write(s[i]);
                gocpos;
              end;
              write(c);
              s[p]:=c;
              inc(p);
            end;
      end;
    end;
  until done;
  gotoxy(x,y);
  textattr:=(infield_out_bkgd*16)+infield_out_fgrd;
  for i:=1 to len do write(' ');
  gotoxy(x,y); write(s);
  gotoxy(sx,sy);
  textattr:=sta;

  infield_only_allow_on:=FALSE;
  infield_special_function_on:=FALSE;
  infield_normal_exit_keydefs:=FALSE;
end; 

procedure infielde(var s:astr; len:byte);
begin
  infield1(wherex,wherey,s,len);
end;

procedure infield(var s:astr; len:byte);
begin
  s:=''; infielde(s,len);
end;

function l_yn:boolean;
var c:char;
begin
  repeat c:=upcase(readkey) until (c in ['Y','N',#13,#27]);
  if (c='Y') then begin
    l_yn:=TRUE;
    writeln('Yes');
  end else begin
    l_yn:=FALSE;
    writeln('No');
  end;
end;

function l_pynq(const s:astr):boolean;
begin
  textcolor(4); write(s); textcolor(11);
  l_pynq:=l_yn;
end;

procedure cwrite(const s:astr);
var i:byte;
    c:char;
    lastb,lastc:boolean;
begin
  lastb:=FALSE; lastc:=FALSE;
  for i:=1 to length(s) do begin
    c:=s[i];
    if ((lastb) or (lastc)) then begin
      if (lastb) then
        textbackground(ord(c))
      else
        if (lastc) then
          textcolor(ord(c));
      lastb:=FALSE; lastc:=FALSE;
    end else
      case c of
        #2:lastb:=TRUE;
        #3:lastc:=TRUE;
      else
           write(c);
      end;
  end;
end;

procedure cwriteat(x,y:integer; const s:astr);
begin
  gotoxy(x,y);
  cwrite(s);
end;

function cstringlength(const s:astr):integer;
var len,i:integer;
begin
  len:=length(s); i:=1;
  while (i<=length(s)) do begin
    if ((s[i]=#2) or (s[i]=#3)) then begin dec(len,2); inc(i); end;
    inc(i);
  end;
  cstringlength:=len;
end;

procedure cwritecentered(y:integer; const s:astr);
begin
  cwriteat(40-(cstringlength(s) div 2),y,s);
end;

{*
 *  ÚÄÄÄ¿   ÉÍÍÍ»   °°°°°   ±±±±±   ²²²²²   ÛÛÛÛÛ   ÖÄÄÄ·  ÕÍÍÍ¸
 *  ³ 1 ³   º 2 º   ° 3 °   ± 4 ±   ² 5 ²   Û 6 Û   º 7 º  ³ 8 ³
 *  ÀÄÄÄÙ   ÈÍÍÍ¼   °°°°°   ±±±±±   ²²²²²   ÛÛÛÛÛ   ÓÄÄÄ½  ÔÍÍÍ¾
 *}
procedure box(linetype,TLX,TLY,BRX,BRY:integer);
var i:integer;
    TL,TR,BL,BR,hline,vline:char;
begin
  window(1,1,MaxDisplayCols,MaxDisplayRows);
  case linetype of
    1:begin
        TL:=#218; TR:=#191; BL:=#192; BR:=#217;
        vline:=#179; hline:=#196;
      end;
    2:begin
        TL:=#201; TR:=#187; BL:=#200; BR:=#188;
        vline:=#186; hline:=#205;
      end;
    3:begin
        TL:=#176; TR:=#176; BL:=#176; BR:=#176;
        vline:=#176; hline:=#176;
      end;
    4:begin
        TL:=#177; TR:=#177; BL:=#177; BR:=#177;
        vline:=#177; hline:=#177;
      end;
    5:begin
        TL:=#178; TR:=#178; BL:=#178; BR:=#178;
        vline:=#178; hline:=#178;
      end;
    6:begin
        TL:=#219; TR:=#219; BL:=#219; BR:=#219;
        vline:=#219; hline:=#219;
      end;
    7:begin
        TL:=#214; TR:=#183; BL:=#211; BR:=#189;
        vline:=#186; hline:=#196;
      end;
    8:begin
        TL:=#213; TR:=#184; BL:=#212; BR:=#190;
        vline:=#179; hline:=#205;
      end;
  else
      begin
        TL:=#32; TR:=#32; BL:=#32; BR:=#32;
        vline:=#32; hline:=#32;
      end;
  end;
  gotoxy(TLX,TLY); write(TL);
  gotoxy(BRX,TLY); write(TR);
  gotoxy(TLX,BRY); write(BL);
  gotoxy(BRX,BRY); write(BR);
  for i:=TLX+1 to BRX-1 do begin
    gotoxy(i,TLY);
    write(hline);
  end;
  for i:=TLX+1 to BRX-1 do begin
    gotoxy(i,BRY);
    write(hline);
  end;
  for i:=TLY+1 to BRY-1 do begin
    gotoxy(TLX,i);
    write(vline);
  end;
  for i:=TLY+1 to BRY-1 do begin
    gotoxy(BRX,I);
    write(vline);
  end;
  if (linetype>0) then window(TLX+1,TLY+1,BRX-1,BRY-1)
                  else window(TLX,TLY,BRX,BRY);
end;

procedure savescreen(var wind:windowrec);
begin
{$IFDEF MSDOS}
  if (MonitorType = 7) then
    move(MScreenAddr[0],Wind[0],ScreenSize)
  else
    move(ScreenAddr[0],Wind[0],ScreenSize);
{$ENDIF}
{$IFDEF WIN32}
  RPSaveScreen(SavedScreen);
{$ENDIF}
end;

procedure setwindow(var wind:windowrec; TLX,TLY,BRX,BRY,tcolr,bcolr,boxtype:integer);
begin
  savescreen(wind);                        { save under window }
  window(TLX,TLY,BRX,BRY);                 { set window size }
  textcolor(tcolr);
  textbackground(bcolr);
  clrscr;                                  { clear window for action }
  box(boxtype,TLX,TLY,BRX,BRY);            { Set the border }
end;

procedure removewindow(var wind:windowrec);
begin
{$IFDEF MSDOS}
  if (MonitorType = 7) then
    move(Wind[0],MScreenAddr[0],ScreenSize)
  else
    move(Wind[0],ScreenAddr[0],ScreenSize);
{$ENDIF}
{$IFDEF WIN32}
  RPRestoreScreen(SavedScreen);
{$ENDIF}
end;

{$IFDEF MSDOS}
procedure update_logo(var Addr1,Addr2; BlkLen:Integer);
begin
  inline (
    $1E/
    $C5/$B6/ADDR1/
    $C4/$BE/ADDR2/
    $8B/$8E/BLKLEN/
    $E3/$5B/
    $8B/$D7/
    $33/$C0/
    $FC/
    $AC/
    $3C/$20/
    $72/$05/
    $AB/
    $E2/$F8/
    $EB/$4C/
    $3C/$10/
    $73/$07/
    $80/$E4/$F0/
    $0A/$E0/
    $EB/$F1/
    $3C/$18/
    $74/$13/
    $73/$19/
    $2C/$10/
    $02/$C0/
    $02/$C0/
    $02/$C0/
    $02/$C0/
    $80/$E4/$8F/
    $0A/$E0/
    $EB/$DA/
    $81/$C2/$A0/$00/
    $8B/$FA/
    $EB/$D2/
    $3C/$1B/
    $72/$07/
    $75/$CC/
    $80/$F4/$80/
    $EB/$C7/
    $3C/$19/
    $8B/$D9/
    $AC/
    $8A/$C8/
    $B0/$20/
    $74/$02/
    $AC/
    $4B/
    $32/$ED/
    $41/
    $F3/$AB/
    $8B/$CB/
    $49/
    $E0/$AA/
    $1F);
end;
{$ENDIF}
{$IFDEF WIN32}
procedure update_logo(data: array of char; originx, originy, datalength: integer);
var 
  i, x, y, count, counter: Integer;
  character: Char;
  spaces: String;
begin
  i := 0;
  x := originx;
  y := originy;
  spaces := '                                                                                '; // 80 spaces
  
  while (i < datalength) do
  begin
    case data[i] of
	  #0..#15: begin
	             TextColor(Ord(data[i]));
	           end;
	  #16..#23: begin
	              TextBackground(Ord(data[i]) - 16);
				end;
	  #24: begin
	         x := originx;
			 Inc(y);
		   end;
	  #25: begin
	         Inc(i);
			 count := Ord(data[i])+1;
			 SysWrtCharStrAtt(@spaces[1], count, x-1, y-1, TextAttr);
			 Inc(x, count);
	       end;
	  #26: begin
	         Inc(i);
			 count := Ord(data[i])+1;
			 Inc(i);
			 character := data[i];
			 for counter := 1 to count do
			 begin
			   SysWrtCharStrAtt(@data[i], 1, x-1, y-1, TextAttr);
			   Inc(x);
			 end;
	       end;
	  #27: begin
	         TextAttr := TextAttr XOR $80; // Invert blink flag
	       end;
	  #32..#255: begin
	               SysWrtCharStrAtt(@data[i], 1, x-1, y-1, TextAttr);
				   Inc(x);
	             end;
    end;
	Inc(i);
  end;
end;
{$ENDIF}

end.
