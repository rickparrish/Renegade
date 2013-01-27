{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S-,V-,X-}

unit common3;

interface

uses crt, dos, myio, common;

procedure inputdefault(var s:string; v:string; l:integer; flags:str8; lf:boolean);
procedure inputformatted(var NewString:string; Format:string; abortable:boolean);
procedure inu(var i:integer);
procedure ini(var i:byte);
procedure inputwn1(var v:string; l:integer; flags:str8; var changed:boolean);
procedure inputwn(var v:string; l:integer; var changed:boolean);
procedure inputwnwc(var v:string; l:integer; var changed:boolean);
procedure inputmain(var s:string; ml:integer; flags:str8);
procedure inputwc(var s:string; ml:integer);
procedure input(var s:string; ml:integer);
procedure inputl(var s:string; ml:integer);
procedure inputcaps(var s:string; ml:integer);

implementation

uses
  common1, common2;

procedure inputdefault(var s:string; v:string; l:integer; flags:str8; lf:boolean);
var c:char;
    i:byte;
begin
  mpl(l);
  mciallowed := FALSE;
  colorallowed := FALSE;
  prompt(v);
  colorallowed := TRUE;
  mciallowed := TRUE;
  c := char(getkey);
  if (c <> #13) then
    begin
      for i:=1 to length(v) do backspace;
      buf := c + buf;
      inputmain(s,l,flags);
      if (s = '') then
        begin
          s := v;
          prompt(s);
        end
      else
        if (s = ' ') then
          s := '';
    end
  else
    begin
      s:=v;
      if (pos('L',allcaps(flags)) = 0) then
        nl;
    end;
  UserColor(1);
  if lf then nl;
end;


procedure inputformatted(var NewString:string; Format:string; abortable:boolean);
var
  i,farback:byte;
  c:char;

  procedure updatestring;
  begin
    while (not (Format[i] in ['#','@']) and (i <= length(Format))) do
      begin
        outkey(Format[i]);
        NewString := NewString + Format[i];
        inc(i);
      end;
  end;

begin
  NewString := '';
  mpl(length(Format));
  i := 1;
  updatestring;
  farback := i;
  repeat
    c := char(getkey);
    if (i <= length(Format)) then
      if ((Format[i] = '@') and (c in ['a'..'z','A'..'Z'])) or
         ((Format[i] = '#') and (c in ['0'..'9'])) then
        begin
          c := upcase(c);
          outkey(c);
          NewString := NewString + c;
          inc(i);
          updatestring;
        end;
    if (c = ^H) then
      begin
        while ((i > farback) and not (Format[i - 1] in ['#','@'])) do
          begin
            backspace;
            dec(NewString[0]);
            dec(i);
          end;
       if (i > farback) then
         begin
           backspace;
           dec(NewString[0]);
           dec(i);
         end;
    end;
  until hangup or
        ((i > length(Format)) or (abortable)) and (c=#13);
  nl;
end;

procedure inu(var i:integer);
var s:string[5];
begin
  badini:=FALSE;
  input(s,5); i:=value(s);
  if (s='') then badini:=TRUE;
end;

procedure ini(var i:byte);
var s:string[3];
begin
  badini:=FALSE;
  input(s,3); i:=value(s);
  if s='' then badini:=TRUE;
end;

procedure inputwn1(var v:string; l:integer; flags:str8; var changed:boolean);
var s:string;
begin
  s := v;
  inputmain(s,l,flags);
  if (s = '') then
    s := v;

  if (s = ' ') then
    if pynq('Blank string? ') then
      s := ''
    else
      s := v;

  if (s <> v) then changed:=TRUE;
  v := s;
end;

procedure inputwn(var v:string; l:integer; var changed:boolean);
begin
  inputwn1(v,l,'',changed);
end;

procedure inputwnwc(var v:string; l:integer; var changed:boolean);
begin
  inputwn1(v,l,'c',changed);
end;

(* flags: "U" - Uppercase only
          "C" - Colors allowed
          "L" - Linefeeds OFF - no linefeed after <CR> pressed
          "D" - Display old if no change
          "P" - Capitalize characters
          "I" - Interactive editing
*)        {"V" - Input NotVisible}
procedure inputmain(var s:string; ml:integer; flags:str8);
var os:string;
    is:string[2];
    cp,cl:byte;
    c:word;
    InsertMode,xxupperonly,xxcolor,xxnolf,xxredisp,xxcaps,xxvisible:boolean;
    i:byte;

    procedure prompt(s:string);
    begin
      SerialOut(s);
      if (wantout) then
        write(s);
    end;

    procedure cursor_left;
    begin
      if not okavatar then
        SerialOut(#27'[D')
      else
        SerialOut(^V^E);
      if (wantout) then
        gotoxy(WhereX - 1, WhereY);
    end;

    procedure cursor_right;
    begin
      outkey(s[cp]);
      inc(cp);
    end;

    procedure setcursor(InsertMode:boolean);assembler;
    asm
      cmp InsertMode, 0
      je @turnon
      mov ch, 0
      mov cl, 7
      jmp @goforit
      @turnon:
      mov ch, 6
      mov cl, 7
      @goforit:
      mov ah,1
      int 10h
    end;

begin
  flags := allcaps(flags);
  xxupperonly := (pos('U', flags) > 0);
  xxcolor     := (pos('C', flags) > 0);
  xxnolf      := (pos('L', flags) > 0);
  xxredisp    := (pos('D', flags) > 0);
  xxcaps      := (pos('P', flags) > 0);
  {xxvisible  := (pos('V', flags) > 0);}
  if (pos('I', flags) = 0) or not (Okansi or OkAvatar) then
    begin
      s := '';
      cp := 1;
      cl := 0;
    end
  else
    begin
      cp := length(s); cl := length(s);
      if cp = 0 then cp := 1;
      prompt(s);
      if (length(s) > 0) then
        begin
          cursor_left;
          if (cp < ml) then cursor_right;
        end;
    end;

  os:=s;
  InsertMode := FALSE;

  repeat
    mlc:=s;
    setcursor(InsertMode);
    c := getkey;
    case c of
      8:if (cp > 1) then
          begin
            dec(cl);
            dec(cp);
            delete(s, cp, 1);
            backspace;
            if (cp < cl) then
              begin
                prompt(copy(s, cp, 255) + ' ');
                for i := cp to cl+1 do
                  cursor_left;
              end;
          end;
     24:begin
          for i := cp to cl do
            outkey(' ');
          for i := 1 to cl do
            backspace;
          cl := 0; cp := 1;
        end;
     32..255:
        begin
          if (xxupperonly) then c := ord(upcase(char(c)));
          if (xxcaps) then
            if (cp > 1) then begin
              if (s[cp - 1] in [#32..#64]) then
                c := ord(upcase(char(c)))
              else
                if (c in [ord('A')..ord('Z')]) then inc(c, 32);
            end else
              c := ord(upcase(char(c)));
          if ((InsertMode) and (cl < ml)) or
             ((not InsertMode) and (cp <= ml)) then
            begin
              outkey(char(c));
              if (InsertMode) then
                begin
                  is := char(c);
                  prompt(copy(s, cp, 255));
                  insert(is, s, cp);
                  for i := cp to cl do
                    cursor_left;
                end
              else
                s[cp]:= char(c);
              if (InsertMode) or (cp - 1 = cl) then
                inc(cl);
              inc(cp);
              if (trapping) then write(trapfile, char(c));
            end;
       end;
      F_END:while (cp < cl + 1) and (cp <= ml) do
              cursor_right;
     F_HOME:while (cp > 1) do
              begin
                cursor_left;
                dec(cp);
              end;
     F_LEFT:if (cp > 1) then
              begin
                cursor_left;
                dec(cp);
              end;
    F_RIGHT:if (cp <= cl) then
              cursor_right;
      F_INS:begin
              InsertMode := not InsertMode;
              setcursor(InsertMode);
            end;
      F_DEL:if (cp > 0) and (cp <= cl) then
              begin
                dec(cl);
                delete(s, cp, 1);
                prompt(copy(s, cp, 255) + ' ');
                for i := cp to cl+1 do
                  cursor_left;
              end;
    end;
    s[0] := chr(cl);
  until (c = 13) or (hangup);
  if ((xxredisp) and (s = '')) then begin
    s := os;
    prompt(s);
  end;
  if (not xxnolf) then nl;
  mlc := '';
  setcursor(FALSE);
end;

procedure inputwc(var s:string; ml:integer);
  begin inputmain(s,ml,'c'); end;

procedure input(var s:string; ml:integer);
  begin inputmain(s,ml,'u'); end;

procedure inputl(var s:string; ml:integer);
  begin inputmain(s,ml,''); end;

procedure inputcaps(var s:string; ml:integer);
  begin inputmain(s,ml,'p'); end;

end.
