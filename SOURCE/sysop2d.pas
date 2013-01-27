{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration - System Variables }

unit sysop2d;

interface

uses crt, dos, overlay, common;

procedure pogenvar;

implementation

procedure pogenvar;
var c:char;
    i:integer;
    bbb:byte;
    done:boolean;
    s:astr;

  procedure listmac(const s:astr;x:byte);
  var i:integer;
      ss:astr;
  begin
    ss := '';
    prompt('^5"^1');
    for i:=1 to length(s) do
      if (s[i]>=' ') then
        ss := ss + s[i]
      else
        ss := ss +  '^3^'+chr(ord(s[i]) + 64) + '^1';
    prompt(mln(ss,x) + '^5"');
  end;

  procedure mmacroo(mn:byte);
  var c:char;
      n:byte;
  begin
    print(^M^J'^5Enter new F'+cstr(mn+1)+' macro now.');
    print('^5Enter ^Z to end recording. 100 character limit.'^M^J);

    n:=1; s:='';
    repeat
      c := char(getkey);

      if (c=^H) then begin
        c:=#0;
        if (n>=2) then begin
          backspace; dec(n);
          if (s[n]<#32) then backspace;
        end;
      end;

      if (n <= 100) and (c<>#0) then begin
        if (c in [#32..#255]) then begin
          outkey(c);
          s[n]:=c; inc(n);
        end else
          if (c in [^A,^B,^C,^D,^E,^F,^G,^H,^I,^J,^K,^L,^M,^N,^P,^Q,^R,^S,^T,
                    ^U,^V,^W,^X,^Y,#27,#28,#29,#30,#31]) then begin
            if (c=^M) then nl
              else prompt('^3^'+chr(ord(c)+64)+'^1');
            s[n]:=c; inc(n);
          end;
      end;
    until ((c=^Z) or (hangup));
    s[0]:=chr(n-1);
    print(^M^J^M^J'^3Your F'+cstr(mn+1)+' macro is now:'^M^J);
    listmac(s,160); nl;
    com_flush_rx;
    if pynq('Is this what you want? ') then begin
      general.macro[mn]:=s;
      print('Macro saved.');
    end else
      print('Macro not saved.');
  end;

begin
  done:=FALSE;
  repeat
    with general do begin
      cls;
      print('^5System variables'^M^J);
      abort:=FALSE; next:=FALSE;
      printacr('^1A. Max private sent per call:^5'+mn(maxprivpost,6)+
        '^1  B. Max feedback sent per call:^5'+mn(maxfback,3));
      printacr('^1C. Max public posts per call:^5'+mn(maxpubpost,6)+
        '^1  D. Max chat attempts per call:^5'+mn(maxchat,3));
      printacr('^1E. Normal max mail waiting  :^5'+mn(maxwaiting,6)+
        '^1  F. CoSysOp max mail waiting  :^5'+mn(csmaxwaiting,3));
      case General.SwapTo of
        0:s := 'Disk';
        1:s := 'XMS';
        2:s := 'EMS';
        4:s := 'EXT';
      else
        begin
          s := 'Any';
          general.SwapTo := $FF;
        end;
      end;
      printacr('^1G. Logins before bday check :^5'+mn(birthdatecheck,6)+
        '^1  H. Swap shell should use     :^5' + s);
      printacr('^1I. Number of logon attempts :^5'+mn(maxlogontries,6)+
        '^1  J. Password change every     :^5'+cstr(passwordchange)+'^1 days');
      printacr('^1K. SysOp chat color         :^5'+mn(sysopcolor,6)+
        '^1  L. User chat color           :^5'+mn(usercolor,3));
      printacr('^1M. Min. space for posts     :^5'+mn(minspaceforpost,6)+
        '^1  N. Min. space for uploads    :^5'+mn(minspaceforupload,4));
      printacr('^1O. Back SysOp Log keep days :^5'+mn(backsysoplogs,6)+
        '^1  P. Blank WFC menu minutes    :^5'+mn(wfcblanktime,4));
      printacr('^1R. Alert beep delay         :^5'+mn(alertbeep,6)+
        '^1  S. Number of system callers  :^5'+mn(callernum,6));
      printacr('^1T. Minimum logon baud rate  :^5'+mn(minimumbaud,6)+
        '^1  U. Minimum download baud rate:^5'+mn(minimumdlbaud,5) + ^M^J);

      for i := 0 to 9 do
         begin
           prompt('^1'+cstr(i)+'. F'+cstr(i + 1)+' Macro :^5');
           listmac(macro[i],21);
           if Odd(i) then nl
             else prompt('   ');
         end;
      prt(^M^J'Enter selection (A-U,0-9) [Q]uit : ');
      onek(c,'QABCDEFGHIJKLMNOPRSTU1234567890'^M); nl;
      badini:=FALSE;

      case c of
        'Q':done:=TRUE;
        '0'..'9':mmacroo(ord(c) - ord('0'));
        'H':begin
              prompt('Swap to which: (D)isk, (E)MS, (X)MS, (N)on XMS extended, or (A)ny? ');
              onek(c,'DEXNA'^M);
              case pos(c,'DXENA') of
                1..3:General.SwapTo := pos(c,'DXE') - 1;
                4:General.SwapTo := 4;
                5:General.SwapTo := 255;
              end;
            end;
        'A'..'P','R'..'U':
          begin
            prt('Range ');
            case c of
              'K','L':prt('(0-9)');
              'J','M','N':prt('(0-32,767)');
              'O':prt('(1-99)');
              'R':prt('(0-60)');
              'S':prt('(0-2.1B)');
              'T','U':prt('0-38400');
            else
                  prt('(0-255)');
            end;
            prt(^M^J'New value: ');
            case c of
              'J','M','N':inu(i);
              'S','T','U':inputl(s,10);
            else
                 ini(bbb);
            end;
            if (not badini) then
              case c of
                'A':maxprivpost:=bbb;
                'B':maxfback:=bbb;
                'C':maxpubpost:=bbb;
                'D':maxchat:=bbb;
                'E':maxwaiting:=bbb;
                'F':csmaxwaiting:=bbb;
                'G':birthdatecheck:=bbb;
                'I':maxlogontries:=bbb;
                'J':passwordchange:=i;
                'K':if (bbb in [0..9]) then sysopcolor:=bbb;
                'L':if (bbb in [0..9]) then usercolor:=bbb;
                'M':if (i>0) then minspaceforpost:=i;
                'N':if (i>0) then minspaceforupload:=i;
                'O':if (bbb in [1..99]) then backsysoplogs:=bbb;
                'P':if (bbb in [0..255]) then wfcblanktime:=bbb;
                'R':if (bbb in [0..60]) then alertbeep:=bbb;
                'S':if value(s)>-1 then callernum:=value(s);
                'T':if value(s)>-1 then minimumbaud:=value(s);
                'U':if value(s)>-1 then minimumdlbaud:=value(s);
              end;
          end;
      end;
    end;
  until (done) or (hangup);
end;

end.
