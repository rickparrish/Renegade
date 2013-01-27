{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration - Range stuff (1-5) }

unit sysop21;

interface

uses crt, dos, overlay, common;

procedure getsecrange(const editing:astr; var sec:secrange);

implementation

procedure getsecrange(const editing:astr; var sec:secrange);
var pag:byte;
    c:char;
    i,j,k:byte;
    h:integer;
    done:boolean;
                    
  procedure showsecrange(beg:byte);
  var s:astr;
      i,j:byte;
      k:integer;
  begin
    abort:=FALSE; next:=FALSE;
    i:=0;
    repeat
      s:='';
      for j:=0 to 7 do begin
        k:=beg+i+j*20;
        if (k<=255) then begin
          s:=s+mn(k,3)+':'+mn(sec[k],5);
          if (j<>7) then s:=s+' ';
        end;
      end;
      printacr(s);
      inc(i);
    until ((i>19) or (abort));
  end;

begin
  done:=FALSE; abort:=FALSE;
  pag:=0;
  repeat
    cls;
    print('^5Editing: '+editing+'^1'^M^J);
    showsecrange(pag);
    prt(^M^J'Range settings (S)et (T)oggle (Q)uit : ');
    onek(c,'QST'^M);
    case c of
      'Q':done:=TRUE;
      'S':begin
            prt(^M^J'From (0-255): ');
            ini(i);
            if (not badini) then begin
              prt('To   (0-255): ');
              ini(j);
              if ((not badini) and (j>=i)) then begin
                prt('Value to set (0-32767): ');
                inu(h);
                if (not badini) then
                  for k:=i to j do sec[k]:=h;
              end;
            end;
          end;
      'T':if (pag=0) then pag:=160 else pag:=0;
    end;
  until ((done) or (hangup));
end;

end.
