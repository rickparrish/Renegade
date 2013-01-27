{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration - System Flagged Functions }

unit sysop2e;

interface

uses crt, dos, overlay, common;

procedure poflagfunc;

implementation

function sltype(i:integer):string;
begin
  case i of
    0:sltype:='File only';
    1:sltype:='Printer & File';
    2:sltype:='Printer only';
  end;
end;

procedure poflagfunc;
var s:string[80];
    c,cc:char;
    nuu,i:integer;
    done:boolean;
    bbb:byte;
begin
  done:=FALSE;
  repeat
    with general do begin
      cls;
      print('^5System flagged functions'^M^J);

      abort:=FALSE; next:=FALSE;
      printacr('^1A. Handles allowed on system:^5'+onoff(allowalias)+
         '^1  B. Phone number in logon     :^5'+onoff(phonepw));
      printacr('^1C. Local security protection:^5'+onoff(localsec)+
         '^1  D. Use EMS for overlay file  :^5'+onoff(useems));
      printacr('^1E. Global activity trapping :^5'+onoff(globaltrap)+
         '^1  F. Auto chat buffer open     :^5'+onoff(autochatopen));
      printacr('^1G. AutoMessage in logon     :^5'+onoff(autominlogon)+
         '^1  H. Bulletins in logon        :^5'+onoff(bullinlogon));
      printacr('^1I. -------------------------:^5'+onoff(lcallinlogon)+
         '^1  J. User info in logon        :^5'+onoff(yourinfoinlogon));
      printacr('^1K. Strip color off SysOp Log:^5'+onoff(stripclog)+
         '^1  L. Offhook in local logon    :^5'+onoff(offhooklocallogon));
      printacr('^1M. Trap Teleconferencing    :^5'+onoff(TrapTeleConf)+
         '^1  N. Compress file/msg numbers :^5'+onoff(compressbases));
      printacr('^1O. UL duplicate file search :^5'+onoff(searchdup)+
         '^1  P. SysOp Log type            :^5'+sltype(slogtype));
      printacr('^1R. Use BIOS for video output:^5'+onoff(usebios)+
         '^1  S. Use IEMSI handshakes      :^5'+onoff(useIEMSI));
      printacr('^1T. Refuse new users         :^5'+onoff(closedsystem)+
         '^1  U. Swap shell function       :^5'+onoff(swapshell));
      printacr('^1V. Use shuttle logon        :^5'+onoff(shuttlelog)+
         '^1  W. Chat call paging          :^5'+onoff(chatcall));
      printacr('^1X. Time limits are per call :^5'+onoff(percall)+
         '^1  Y. SysOp Password checking   :^5'+onoff(sysoppword));
      printacr('');
      s:='^11. New user message sent to :^5';
      if (newapp=-1) then s:=s+'Off' else s:=s+mn(newapp,3);
      printacr(s);
      s:='^12. Mins before timeout bell :^5';
      if (timeoutbell=-1) then s:=s+'Off' else s:=s+mn(timeoutbell,3);
      printacr(s);
      s:='^13. Mins before timeout      :^5';
      if (timeout=-1) then s:=s+'Off' else s:=s+mn(timeout,3);
      printacr(s);
      prt(^M^J'Enter selection (A-Y,1-3) [Q]uit : ');
      onek(c,'QABCDEFGHIJKLMNOPRSTUVWXY123'^M); nl;

      case c of
        'Q':done:=TRUE;
        'A':allowalias:=not allowalias;
        'B':phonepw:=not phonepw;
        'C':localsec:=not localsec;
        'D':useems:=not useems;
        'E':globaltrap:=not globaltrap;
        'F':autochatopen:=not autochatopen;
        'G':autominlogon:=not autominlogon;
        'H':bullinlogon:=not bullinlogon;
        {'I':lcallinlogon:=not lcallinlogon;}
        'J':yourinfoinlogon:=not yourinfoinlogon;
        'K':stripclog:=not stripclog;
        'L':offhooklocallogon:=not offhooklocallogon;
        'M':TrapTeleConf := not TrapTeleConf;
        'N':begin
              compressbases:=not compressbases;
              nl;
              if (compressbases) then print('Compressing bases...')
                else print('De-compressing bases...');
              newcomptables;
            end;
        'O':searchdup:=not searchdup;
        'P':begin
              print('Current SysOp Log type: '+sltype(slogtype) + ^M^J);
              for i:=0 to 2 do print(cstr(i)+': '+sltype(i));
              prt(^M^J'New type: '); ini(bbb);
              if ((not badini) and (bbb in [0..2])) then slogtype:=bbb;
            end;
        'R':begin
              usebios:=not usebios;
              directvideo:=not usebios;
            end;
        'S':useIEMSI:=not useIEMSI;
        'T':closedsystem:=not closedsystem;
        'U':swapshell:=not swapshell;
        'V':shuttlelog:=not shuttlelog;
        'W':chatcall:=not chatcall;
        'X':percall:=not percall;
        'Y':sysoppword:=not sysoppword;
        '1'..'3':
          begin
            prt('[E]nable [D]isable this function: ');
            onek(cc,'Q ED'^M);
            if cc in ['E','D'] then begin
              badini:=FALSE;
              case cc of
                'D':i:=-1;
                'E':begin
                      prt('Range ');
                      case c of
                        '1':begin
                             nuu:=maxusers-1;
                             prt('(1-'+cstr(nuu)+')');
                           end;
                        '2','3','4':prt('(1-20)');
                      else
                           prt('(0-32767)');
                      end;
                      prt(^M^J'Enter value for this function: ');
                      inu(i);
                    end;
              end;
              if (not badini) then
                case c of
                  '1':if ((i>=1) and (i<=nuu)) or (cc='D') then newapp:=i;
                  '2':if ((i>=1) and (i<=20)) or (cc='D') then timeoutbell:=i;
                  '3':if ((i>=1) and (i<=20)) or (cc='D') then timeout:=i;
                end;
            end
            else print('No change.');
          end;
      end;
    end;
  until (done) or (hangup);
end;

end.
