{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration - Modem Configuration }

unit sysop2b;

interface

uses crt, dos, overlay, common;

procedure pomodem;

implementation

uses cuser, sysop2k;

const
  aresure='Are you sure this is what you want? ';

function wantit:boolean;
begin
  nl; wantit:=pynq(aresure);
end;

procedure noch;
begin
  print('No change.');
end;

procedure newmodemstring(var vs:astr; const what:astr; len:integer);
var
  changed:boolean;
begin
  print('^1Current modem '+what+' string: "'+ vs +'"'^M^J);
  print('Use: "|" for a carriage return');
  print('     "~" for a half-second delay');
  print('     "^" to toggle DTR off for 1/4 second'^M^J);
  print('Enter new modem '+what+' string:');
  prt(':');
  if (len > 78) then
    mpl(78)
  else
    mpl(len);
  inputwn(vs, len, changed);
  if not (changed) then
    noch;
end;

procedure pomodem;
var s:string[80];
    i,c1,c2,cc:integer;
    c:char;
    done,
    Changed:boolean;
    f:file of linerec;

  function WhichBaud(i:integer):string;
  begin
    case i of
      1:WhichBaud := 'CONNECT 300';    2:WhichBaud := 'CONNECT 600';
      3:WhichBaud := 'CONNECT 1200';    4:WhichBaud := 'CONNECT 2400';
      5:WhichBaud := 'CONNECT 4800';    6:WhichBaud := 'CONNECT 7200';
      7:WhichBaud := 'CONNECT 9600';    8:WhichBaud := 'CONNECT 12000';
      9:WhichBaud := 'CONNECT 14400';   10:WhichBaud := 'CONNECT 16800';
     11:WhichBaud := 'CONNECT 19200';   12:WhichBaud := 'CONNECT 21600';
     13:WhichBaud := 'CONNECT 24000';   14:WhichBaud := 'CONNECT 26400';
     15:WhichBaud := 'CONNECT 28800';   16:WhichBaud := 'CONNECT 31200';
     17:WhichBaud := 'CONNECT 33600';   18:WhichBaud := 'CONNECT 38400';
     19:WhichBaud := 'CONNECT 57600';   20:WhichBaud := 'CONNECT 115200';
   end;
 end;

begin
  done:=FALSE;
  assign(f,general.datapath+'NODE'+cstr(node)+'.DAT');
  reset(f);
  read(f,liner);
  repeat
    with liner do begin
      cls;
      print('^5Modem/Node Configuration'^M^J);

      abort:=FALSE; next:=FALSE;
      printacr('^11. Maximum baud rate: ^5'+mln(cstr(InitBaud), 20) +
               '^12. Port number      : ^5'+cstr(ComPort));
      printacr('^13. Modem init       : ^5'+mln(Init, 20) +
               '^14. Modem answer     : ^5'+Answer);
      printacr('^15. Modem hangup     : ^5'+mln(Hangup, 20) +
               '^16. Modem offhook    : ^5'+Offhook);
      printacr('^17. COM port locking : ^5'+mln(onoff(LockedPort in mflags),20)+
               '^18. Digiboard support: ^5'+onoff(DigiBoard in mflags));
      printacr('^19. CTS/RTS flow     : ^5'+mln(onoff(CTSRTS in mflags),20) +
               '^1A. XON/XOFF flow    : ^5'+onoff(XONXOFF in mflags));
      printacr('^1B. Drop file path   : ^5'+mln(DoorPath,20) +
               '^1C. ACS for this node: ^5'+LogonACS);
      printacr('^1D. TeleConf Normal  : ^5'+mln(TeleConfNormal,20) +
               '^1J. Answer on ring   : ^5'+cstr(AnswerOnRing));
      printacr('^1E. TeleConf Anon    : ^5'+mln(TeleConfAnon,20)+
               '^1K. MultiRing only   : ^5'+onoff(MultiRing));
      printacr('^1F. TeleConf Global  : ^5'+TeleConfGlobal);
      printacr('^1G. TeleConf Private : ^5'+TeleConfPrivate);
      printacr('^1H. IRQ string       : ^5'+IRQ);
      printacr('^1I. Address string   : ^5'+Address);
      printacr('^1R. Modem result codes');

      prt(^M^J'Enter selection (1-9, A-K, R) [Q]uit : ');
      onek(c,'Q123456789ABCDEFGHIJKR'^M); nl;
      case c of
        '1':if (incom) then
              begin
                print('^7This can only be changed locally.'^M^J);
                pausescr(FALSE);
              end
            else
              begin
                print('Select your modem''s maximum baud rate: '^M^J);
                print('A:2400 B:9600 C:19200 D:38400 E:57600 F:115200');
                prt('Modem speed? (A-F) : '); onek(c,'QABCDEF'^M);
                if (c in ['A'..'F']) then
                  case c of
                    'A':InitBaud := 2400;
                    'B':InitBaud := 9600;
                    'C':InitBaud := 19200;
                    'D':InitBaud := 38400;
                    'E':InitBaud := 57600;
                    'F':InitBaud := 115200;
                  end;
              end;
        '2':if (incom) then
              begin
                print('^7This can only be changed locally.'^M^J);
                pausescr(FALSE);
              end
            else
              begin
                prt('Com port (0-64)? '); inu(cc);
                if (cc in [0..64]) and (wantit) then
                  begin
                    com_deinstall;
                    ComPort := cc;
                    initport;
                  end
                else
                  noch;
                if (not localioonly) and (ComPort = 0) then
                  localioonly := TRUE;
              end;
        '3':newmodemstring(Init,'init', sizeof(Init) - 1);
        '4':newmodemstring(Answer,'answer', sizeof(Answer) - 1);
        '5':newmodemstring(Hangup,'hangup', sizeof(Hangup) - 1);
        '6':newmodemstring(Offhook,'offhook', sizeof(Offhook) - 1);
        '7':if (LockedPort in MFlags) then
              MFlags := MFlags - [LockedPort]
            else
              MFlags := MFlags + [LockedPort];
        '8':if (DigiBoard in MFlags) then
              MFlags := MFlags - [DigiBoard]
            else
              MFlags := MFlags + [DigiBoard];
        '9':if (CTSRTS in MFlags) then
              MFlags := MFlags - [CTSRTS]
            else
              MFlags := MFlags + [CTSRTS];
        'A':if (XONXOFF in MFlags) then
              MFlags := MFlags - [XONXOFF]
            else
              MFlags := MFlags + [XONXOFF];
        'C':begin
              prt('New ACS: '); mpl(20);
              inputmain(LogonACS, 20, 'I');
            end;
        'B':inputpath('Enter path to write door interface files to',DoorPath);
        'D'..'G':begin
              print('Enter new teleconference string.');
              prt(':'); mpl(sizeof(TeleConfNormal)-1);
              case c of
                'D': inputmain(TeleConfNormal, sizeof(TeleConfNormal)-1, 'CI');
                'E': inputmain(TeleConfAnon, sizeof(TeleConfAnon)-1, 'CI');
                'F': inputmain(TeleConfGlobal, sizeof(TeleConfGlobal)-1, 'CI');
                'G': inputmain(TeleConfPrivate, sizeof(TeleConfPrivate)-1, 'CI');
              end;
            end;
        'H':begin
              prt('IRQ for %E MCI code: '); mpl(sizeof(IRQ)-1);
              inputmain(IRQ, sizeof(IRQ), 'I');
            end;
        'I':begin
              prt('Address for %C MCI code: '); mpl(sizeof(Address)-1);
              inputmain(Address, sizeof(Address) - 1, 'I');
            end;
        'J':begin
              prt('Answer after ring number: '); inu(cc);
              if (not badini) then
                AnswerOnRing := cc;
            end;
        'K':MultiRing := not MultiRing;
        'R':repeat
              cls;
              abort := FALSE;
              print('^5Modem configuration - Result Codes'^M^J);

              printacr('^1    A. NO CARRIER     : ^5' + mln(NOCARRIER, 18) + '^1B. RELIABLE       : ^5' + RELIABLE);
              printacr('^1    C. OK             : ^5' + mln(OK, 18) + '^1D. RING           : ^5' + RING);
              printacr('^1    E. CALLER ID      : ^5' + mln(CALLERID, 18) + '^1F. ID in user note: ^5' + onoff(UseCallerID));
              for i := 1 to MAXRESULTCODES do
                begin
                  Changed := not odd(i);
                  if Changed then
                    print('^1    '+chr(i + 70)+'. ' + mln(WhichBaud(i), 14) + ' : ^5'
                          + CONNECT[i])
                  else
                    prompt(mln('^1    '+chr(i + 70)+'. ' + mln(WhichBaud(i), 14) + ' : ^5'
                           + CONNECT[i], 38));
                end;
              prt(^M^J'Your choice or [ENTER] : ');
              onek(c, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M);
              case c of
                 'A':begin
                     prt('Enter NO CARRIER string: ');
                     inputwn1(NOCARRIER, sizeof(NOCARRIER) - 1, 'U', Changed);
                   end;
                 'B':begin
                     prt('Enter RELIABLE string: ');
                     inputwn1(RELIABLE, sizeof(RELIABLE) - 1, 'U', Changed);
                   end;
                 'C':begin
                     prt('Enter OK string: ');
                     inputwn1(OK, sizeof(OK) - 1, 'U', Changed);
                   end;
                 'D':begin
                     prt('Enter RING string: ');
                     inputwn1(RING, sizeof(RING) - 1, 'U', Changed);
                   end;
                 'E':begin
                     prt('Enter caller ID string: ');
                     inputwn1(CALLERID, sizeof(CALLERID) - 1, 'U', Changed);
                   end;
                 'F':UseCallerID := not UseCallerID;
                else
                  begin
                    cc := ord(c) - 70;
                    if (cc in [1..MAXRESULTCODES]) then
                      begin
                        prt('Enter ' + WhichBaud(cc) + ' string: ');
                        inputwn1(CONNECT[cc], sizeof(CONNECT[1]) - 1, 'U', Changed);
                      end
                  end;
              end;
            until (c = ^M);
        'Q':done:=TRUE;
      end;
    end;
  until ((done) or (hangup));
  seek(f,0);
  write(f,liner);
  close(f);
  Lasterror := IOResult;
end;

end.
