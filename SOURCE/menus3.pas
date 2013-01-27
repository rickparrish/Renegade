{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Menu command execution routines. }

unit menus3;

interface

uses crt, dos, overlay, common;

procedure dochangemenu(var done:boolean; var newmenucmd:astr;
                       c2:char; const mstr:astr);

implementation

uses file0;

procedure dochangemenu(var done:boolean; var newmenucmd:astr;
                       c2:char; const mstr:astr);
var s,s1:astr;
begin
  case c2 of
    '^':begin
          s1:=mstr;
          if (pos(';',s1)<>0) then s1:=copy(s1,1,pos(';',s1)-1);
          if (mstr<>'') then begin
            s:=mstr;
            if (pos(';',s)<>0) then s:=copy(s,pos(';',s)+1,length(s));
            if s[1]='C' then menustackptr:=0;
            if (pos(';',s)=0) or (length(s)=1) then s:=''
              else s:=copy(s,pos(';',s)+1,length(s));
          end;
          if (s1<>'') then begin
            curmenu:=general.menupath+s1+'.mnu';
            done:=TRUE;
            if (s<>'') then newmenucmd:=allcaps(s);
            newmenutoload:=TRUE;
          end;
        end;
    '/':begin
          s1:=mstr;
          if (pos(';',s1)<>0) then s1:=copy(s1,1,pos(';',s1)-1);
          if ((mstr<>'') and (menustackptr<>8)) then begin
            s:=mstr;
            if (pos(';',s)<>0) then s:=copy(s,pos(';',s)+1,length(s));
            if s[1]='C' then menustackptr:=0;
            if (pos(';',s)=0) or (length(s)=1) then s:=''
              else s:=copy(s,pos(';',s)+1,length(s));
            if (Allcaps(curmenu) <> Allcaps(general.menupath+s1+'.mnu')) then
              begin
                inc(menustackptr);
                menustack[menustackptr]:=stripname(curmenu);
              end
            else
              s1 := '';
          end;
          if (s1<>'') then begin
            curmenu:=general.menupath+s1+'.mnu';
            done:=TRUE;
            if (s<>'') then newmenucmd:=allcaps(s);
            newmenutoload:=TRUE;
          end;
        end;
    '\':begin
          s:=mstr;
          if (menustackptr<>0) then begin
            curmenu:=general.menupath+menustack[menustackptr];
            dec(menustackptr);
          end;
          if s[1]='C' then menustackptr:=0;
          done:=TRUE;
          if (pos(';',s)=0) then s:='' else
            newmenucmd:=allcaps(copy(s,pos(';',s)+1,length(s)));
          newmenutoload:=TRUE;
        end;
  end;
  curmenu := sqoutsp(curmenu);
end;

end.
