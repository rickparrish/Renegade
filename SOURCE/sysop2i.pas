{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration - Offline Mail Support }

unit sysop2i;

interface

uses crt, dos, overlay, common;

procedure poqwk;

implementation

procedure poqwk;
var c:char;
    done:boolean;
    s:string[5];
    i:word;
begin
  done:=FALSE;
  repeat
    with general do begin
      cls;
      abort:=FALSE;
      print('^5Offline Mail Configuration'^M^J);

      printacr('^1A. QWK/REP Packet name :^5'+packetname);
      printacr('^1B. Welcome screen name :^5'+qwkwelcome);
      printacr('^1C. News file name      :^5'+qwknews);
      printacr('^1D. Goodbye file name   :^5'+qwkgoodbye);
      printacr('^1E. Local QWK/REP path  :^5'+qwklocalpath);
      printacr('^1F. Ignore time for DL  :^5'+onoff(qwktimeignore));
      printacr('^1G. Max total messages  :^5'+cstr(maxqwktotal));
      printacr('^1H. Max msgs per base   :^5'+cstr(maxqwkbase));
      printacr('^1I. ACS for Network .REP:^5'+qwknetworkacs);

      prt(^M^J'Enter selection (A-I) [Q]uit : ');
      onek(c,'QABCDEFGHI'^M); nl;
      case c of
        'A':begin
              prt('QWK Packet name: ');
              input(packetname,8);
            end;
        'B':begin
              prt('Welcome screen path+name [no ext] : ');
              input(qwkwelcome,50);
            end;
        'C':begin
              prt('News file path+name [no ext] : ');
              input(qwknews,50);
            end;
        'D':begin
              prt('Goodbye file path+name [no ext] : ');
              input(qwkgoodbye,50);
            end;
        'E':inputpath('Enter local QWK reader path',qwklocalpath);
        'F':qwktimeignore := not qwktimeignore;
        'G':begin
              prt('Maximum total messages in a QWK packet: ');
              input(s,5);
              if (s <> '') then
                maxqwktotal := value(s);
            end;
        'H':begin
              prt('Maximum messages per base in a packet: ');
              input(s,5);
              if (s <> '') then
                maxqwkbase := value(s);
            end;
        'I':begin
              prt('New ACS: '); inputl(s,20);
              if (s<>'') then
                qwknetworkacs := s;
            end;
        'Q':done:=TRUE;
      end;
    end;
  until (done) or (hangup);
  savegeneral(FALSE);
end;

end.
