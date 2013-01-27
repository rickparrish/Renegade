{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration - System ACS settings }

unit sysop2c;

interface

uses crt, dos, overlay, common;

procedure poslsettings;

implementation


procedure poslsettings;
var s:acstring;
    c:char;
    done:boolean;
begin
  done:=FALSE;
  repeat
    with general do begin
      cls;
      print('^5System ACS settings'^M^J);
      abort:=FALSE; next:=FALSE; mciallowed:=FALSE;
      printacr('^1A. Full SysOp       :^5'+mln(sop,18)+
               '^1B. Full Co-SysOp    :^5'+csop);
      printacr('^1C. Msg Base SysOp   :^5'+mln(msop,18)+
               '^1D. File Base SysOp  :^5'+fsop);
      printacr('^1E. Change a vote    :^5'+mln(changevote,18)+
               '^1F. Add voting choice:^5'+addchoice);
      printacr('^1G. Post public      :^5'+mln(normpubpost,18)+
               '^1H. Send e-mail      :^5'+normprivpost);
      printacr('^1I. See anon pub post:^5'+mln(anonpubread,18)+
               '^1J. See anon E-mail  :^5'+anonprivread);
      printacr('^1K. Global Anon post :^5'+mln(anonpubpost,18)+
               '^1L. E-mail anon      :^5'+anonprivpost);
      printacr('^1M. See unval. files :^5'+mln(seeunval,18)+
               '^1N. DL unval. files  :^5'+dlunval);
      printacr('^1O. No UL/DL ratio   :^5'+mln(nodlratio,18)+
               '^1P. No PostCall ratio:^5'+nopostratio);
      printacr('^1R. No DL credits chk:^5'+mln(nofilecredits,18)+
               '^1S. ULs auto-credited:^5'+ulvalreq);
      printacr('^1T. MCI in TeleConf  :^5'+mln(TeleConfMCI,18)+
               '^1U. Chat at any hour :^5'+overridechat);
      printacr('^1V. Send Netmail     :^5'+mln(netmailacs,18)+
               '^1W. "Invisible" Mode :^5'+Invisible);
      printacr('^1X. Mail file attach :^5'+mln(fileattachacs,18)+
               '^1Y. SysOp PW at logon:^5'+spw);
      mciallowed:=TRUE;
      prt(^M^J'Enter selection (A-Y) [Q]uit : ');
      onek(c,'QABCDEFGHIJKLMNOPRSTUVWXY'^M);

      if (c='Q') then done:=TRUE;

      nl;
      if (not done) and (c in ['A'..'P','R'..'Y']) then
        begin
          prt('New ACS: '); inputl(s, 20);
          if (s <> '') then
            case c of
              'A':sop:=s;           'B':csop:=s;
              'C':msop:=s;          'D':fsop:=s;
              'E':changevote:=s;    'F':addchoice:=s;
              'G':normpubpost:=s;   'H':normprivpost:=s;
              'I':anonpubread:=s;   'J':anonprivread:=s;
              'K':anonpubpost:=s;   'L':anonprivpost:=s;
              'M':seeunval:=s;      'N':dlunval:=s;
              'O':nodlratio:=s;     'P':nopostratio:=s;
              'R':nofilecredits:=s;     'S':ulvalreq:=s;
              'T':TeleConfMCI:=s;   'U':overridechat:=s;
              'V':netmailacs:=s;    'W':Invisible:=s;
              'X':fileattachacs:=s; 'Y':spw:=s;
            end;
        end;
    end;
  until (done) or (hangup);
end;

end.
