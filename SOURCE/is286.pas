{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
unit is286;

{$G-}

interface

implementation

{$IFDEF MSDOS}
function a286or_better:boolean; assembler;
asm
  pushf
  pop   bx
  and   bx,0fffh
  push  bx
  popf
  pushf
  pop   bx
  and   bx,0f000h
  cmp   bx,0f000h
  mov   ax,0
  jz    @@1
  mov   ax,1
  @@1:
end;
{$ENDIF}
{$IFDEF WIN32}
function a286or_better:boolean;
begin
  // I think this is a safe assumption
  a286or_better := true;
end;
{$ENDIF}

begin
  if not a286or_better then begin
    writeln;
    writeln('Renegade requires an 80286 or better processor.');
    halt;
  end;
end.
{$G+}
