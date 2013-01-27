{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
unit dffix;
{
  code: 276
}
interface

uses dos;

function  diskkbfree(drive:byte):longint;

implementation

function diskkbfree(drive:byte):longint;
var
  regs:registers;

begin
  regs.ah := $36;
  regs.dl := drive;
  intr($21,regs);
  diskkbfree := longint(regs.bx) * ((longint(regs.ax) * regs.cx) div 1024);
end;

end.
