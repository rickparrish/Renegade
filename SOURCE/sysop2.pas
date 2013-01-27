{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration - Main }

unit sysop2;

interface

uses crt, dos, overlay, common;

procedure changestuff;

implementation

uses sysop2a, sysop2b, sysop2c, sysop2d, sysop2e, sysop2f, sysop2g,
     sysop2h, sysop2i, sysop2j, sysop2k, sysop21, sysop2l, sysop2m,
     Maint;

const
  aresure='Are you sure this is what you want? ';

function wantit:boolean;
begin
  nl; wantit:=pynq(aresure);
end;

procedure changestuff;
var c:char;
    done:boolean;
begin
  repeat
    savegeneral(TRUE);
    done:=FALSE;
    cls;
    print('^5System configuration:^1'^M^J);
    abort:=FALSE; next:=FALSE;
    printacr('A. Main BBS Configuration                '+
             'B. Modem/Node Configuration');
    printacr('C. System ACS Settings                   '+
             'D. System Variables');
    printacr('E. System Toggles                        '+
             'F. File System Configuration');
    printacr('G. Subscription/Validation System        '+
             'H. Network Configuration');
    printacr('I. Offline Mail Configuration            '+
             'J. String Configuration');
    printacr('K. Color Configuration                   '+
             'L. Archive Configuration');
    printacr('M. Credit System Configuration           '+
             'N. --------------------------'^M^J);
    printacr('1. Time allowed per '+aonoff(general.percall,'call','day ') +
             '                 '+
             '2. Max calls per day');
    printacr('3. UL/DL # files ratio                   '+
             '4. UL/DL K-bytes ratio');
    printacr('5. Post/Call ratio                       '+
             '6. Max downloads per day');
    printacr('7. Max download kbytes per day           '+
             '8. Update System Averages');
    prt(^M^J'Enter selection (A-M,1-8) [Q]uit : ');
    onek(c,'QABCDEFGHIJKLM12345678'^M);
    case c of
      'A':pofile;
      'B':pomodem;
      'C':poslsettings;
      'D':pogenvar;
      'E':poflagfunc;
      'F':pofilesconfig;
      'G':ponewauto;
      'H':pofido;
      'I':poqwk;
      'J':postring;
      'K':pocolors;
      'L':poarcconfig;
      'M':pocreditconfig;
      '1':getsecrange('Time limitations',general.timeallow);
      '2':getsecrange('Call allowance per day',general.callallow);
      '3':getsecrange('UL/DL # files ratio (# files can DL per UL)',general.dlratio);
      '4':getsecrange('UL/DL K-bytes ratio (#k can DL per 1k UL)',general.dlkratio);
      '5':getsecrange('Post/Call ratio (posts per 100 calls) to have Z ACS flag set',general.postratio);
      '6':getsecrange('Maximum number of downloads in one day',general.dloneday);
      '7':getsecrange('Maximum amount of downloads (in kbytes) in one day',general.dlkoneday);
      '8':updategeneral;
      'Q':done:=TRUE;
    end;
    savegeneral(FALSE);
  until ((done) or (hangup));
end;

end.
