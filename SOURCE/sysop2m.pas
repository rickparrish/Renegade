{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration - Credit system config }

unit sysop2m;

interface

uses crt, dos, overlay, common;

procedure pocreditconfig;

implementation

procedure pocreditconfig;
var c:char;
    done:boolean;
    s:string[5];
    i:integer;
begin
  done:=FALSE;
  repeat
    with general do begin
      cls;
      abort:=FALSE;
      print('^5Credit System Config'^M^J);

      printacr('^1A. Charge/minute       :^5' + cstr(CreditMinute));
      printacr('^1B. Message post        :^5' + cstr(CreditPost));
      printacr('^1C. Email sent          :^5' + cstr(CreditEmail));
      printacr('^1D. Free time at logon  :^5' + cstr(CreditFreeTime));
      printacr('^1E. Internet mail cost  :^5' + cstr(CreditInternetMail));

      prt(^M^J'Enter selection (A-E) [Q]uit : ');
      onek(c,'QABCDE'^M); nl;
      case c of
        'A':begin
              prt('Credits charged per minute online: ');
              inu(i);
              if (not badini) then
                CreditMinute := i;
            end;
        'B':begin
              prt('Credits charged per message post: ');
              inu(i);
              if (not badini) then
                CreditPost := i;
            end;
        'C':begin
              prt('Credits charged per email sent: ');
              inu(i);
              if (not badini) then
                CreditEmail := i;
            end;
        'D':begin
              prt('Minutes to give users w/o credits at logon: ');
              inu(i);
              if (not badini) then
                CreditFreeTime := i;
            end;
        'E':begin
              prt('Cost for Internet mail messages: ');
              inu(i);
              if (not badini) then
                CreditInternetmail := i;
            end;
        'Q':done:=TRUE;
      end;
    end;
  until (done) or (hangup);
  savegeneral(FALSE);
end;

end.
