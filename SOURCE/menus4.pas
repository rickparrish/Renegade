{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Menu command execution routines. }

unit menus4;

interface

uses crt, dos, overlay, common;

procedure autovalidationcmd(const pw:astr;level:char);

implementation

procedure autovalidationcmd(const pw:astr;level:char);
var s:astr;
    ok:boolean;
begin
  nl;
  if (thisuser.sl=general.validation[level].newsl) and
     (thisuser.dsl=general.validation[level].newdsl) then begin
    print('You''ve been validated!  You do not need to use this command.');
    exit;
  end;

  print('Press [Enter] to abort.');
  prt(^M^J'Password: '); input(s,50);
  if (s='') then print('^7Function aborted.'^G)
  else begin
    ok:=(s = allcaps(pw));
    if (not ok) then
      begin
        sysoplog('Wrong password for auto-validation: "'+s+'"');
        print('^7Wrong!'^G);
      end
    else
      begin
        sysoplog('Used auto-validation password.');
        autovalidate(thisuser,usernum,level);
        status_screen(100,'This user has auto-validated himself.',FALSE,s);
        printf('autoval');
        if (nofile) then
          print(^M^J'Correct.  You are now validated.');
      end;
  end;
end;

end.
