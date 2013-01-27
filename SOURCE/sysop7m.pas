{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Menu Editor }

unit sysop7m;

interface

uses crt, dos, overlay, common;

procedure memm(const scurmenu:astr; var menuchanged:boolean);

implementation

uses file9, menus2, sysop1;

procedure memm(const scurmenu:astr; var menuchanged:boolean);
var ii:integer;
    c:char;
    s:astr;
begin
  prt('Begin editing at which? (1-'+cstr(noc)+') : '); inu(ii);
  c:=' ';
  if (ii>=1) and (ii<=noc) then begin
    while (c<>'Q') and (not hangup) do begin
      repeat
        with MenuCommand^[ii] do begin
          if (c<>'?') then begin
            cls;
            print('^3Menu filename: '+scurmenu);
            print('Command #'+cstr(ii)+' of '+cstr(noc) + ^M^J);
            with MenuCommand^[ii] do begin
              mciallowed:=FALSE;
              print('^11. Long descript :'+ldesc);
              print('2. Short descript:'+sdesc);
              print('3. Menu keys     :'+ckeys);
              print('4. ACS required  :"'+acs+'"');
              print('5. Cmdkeys       :'+cmdkeys);
              print('6. Options       :'+options+'^1');
              mciallowed:=TRUE;
              s:='';
              if (hidden in commandflags) then s:='(H)idden';
              if (unhidden in commandflags) then begin
                if (s<>'') then s:=s+', ';
                s:=s+'(U)nhidden';
              end;
              if (s='') then s:='None';
              print('   Flags         :'+s);
              print('Q. Quit');
            end;
          end;
          prt(^M^J'Edit menu (?=help) : ');
          onek(c,'Q123456[]FJLUH?'^M);
          nl;
          case c of
            '1':begin
                  print('New long description:');
                  prt(':'); inputwnwc(ldesc, sizeof(ldesc) - 1,menuchanged);
                end;
            '2':begin
                  prt('New short description: ');
                  inputwnwc(sdesc,sizeof(sdesc) - 1,menuchanged);
                end;
            '3':begin
                  prt('New command letters: '); mpl(14); input(s,14);
                  if (s<>'') then begin ckeys:=s; menuchanged:=TRUE; end;
                end;
            '4':begin
                  prt('New ACS: '); mpl(40);
                  inputwn(acs,40,menuchanged);
                end;
            '5':begin
                  repeat
                    prt('New command (?=List): '); mpl(2); input(s,2);
                    if s='?' then begin cls; printf('menucmd'); nl; end;
                  until (hangup) or (s<>'?');
                  if (length(s)=2) then begin cmdkeys:=s; menuchanged:=TRUE; end;
                end;
            '6':begin
                  prt('New options: '); mpl(50);
                  inputwnwc(options,sizeof(options) - 1,menuchanged);
                end;
            'U':begin
                  if (unhidden in commandflags) then
                    commandflags:=commandflags-[unhidden]
                  else commandflags:=commandflags+[unhidden];
                  menuchanged:=true;
                end;
            'H':begin
                  if (hidden in commandflags) then
                    commandflags:=commandflags-[hidden]
                  else commandflags:=commandflags+[hidden];
                  menuchanged:=true;
                end;
            '[':if (ii>1) then dec(ii) else c:=' ';
            ']':if (ii<noc) then inc(ii) else c:=' ';
            'F':if (ii<>1) then ii:=1 else c:=' ';
            'J':begin
                  prt('Jump to entry: ');
                  input(s,3);
                  if (value(s)>=1) and (value(s)<=noc) then ii:=value(s) else c:=' ';
                end;
            'L':if (ii<>noc) then ii:=noc else c:=' ';
            '?':ee_help;
          end;
        end;
      until (c in ['Q','[',']','F','J','L']) or (hangup);
    end;
  end;
end;

end.
