{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration - BBS config and file paths }

unit sysop2a;

interface

uses crt, dos, overlay, common;

procedure pofile;

implementation

uses sysop3;

const
  aresure='Are you sure this is what you want? ';

function wantit:boolean;
begin
  nl; wantit:=pynq(aresure);
end;

function phours(const s:astr; lotime,hitime:integer):astr;
begin
  if (lotime<>hitime) then
    phours:=Zeropad(cstr(lotime div 60))+':'+Zeropad(cstr(lotime mod 60))+'...'+
            Zeropad(cstr(hitime div 60))+':'+Zeropad(cstr(hitime mod 60))
  else
    phours:=s;
end;

procedure gettimerange(const s:astr; var st1,st2:integer);
var t1,t2,t1h,t1m,t2h,t2m:integer;
begin
  if pynq(s) then begin
    print(^M^J^M^J'All entries in 24 hour time.  Hour: (0-23), Minute: (0-59)'^M^J);

    prompt('Starting time:');
    prt('  Hour   : '); mpl(5); inu(t1h);
    if (t1h<0) or (t1h>23) then t1h:=0;
    prt('                Minute : '); mpl(5); inu(t1m);
    if (t1m<0) or (t1m>59) then t1m:=0;
    prompt(^M^J'Ending time:  ');
    prt('  Hour   : '); mpl(5); inu(t2h);
    if (t2h<0) or (t2h>23) then t2h:=0;
    prt('                Minute : '); mpl(5); inu(t2m);
    if (t2m<0) or (t2m>59) then t2m:=0;
    t1:=t1h*60+t1m; t2:=t2h*60+t2m;
  end
  else begin t1:=0; t2:=0; end;
  prompt(^M^J'Hours: '+phours('Undeclared',t1,t2));
  if (wantit) then begin
    st1:=t1;
    st2:=t2;
  end;
end;

procedure pofile;
var s:string[80];
    i:integer;
    c:char;
    done:boolean;
begin
  done:=FALSE;
  repeat
    with general do begin
      cls;
      print('^5Main BBS Configuration'^M^J);
      abort:=FALSE;
      printacr('^1A. BBS name/number  :^5'+bbsname+' ^1(^5'+bbsphone+'^1)');
      printacr('^1B. SysOp''s name     :^5'+mln(sysopname,16)+
               '^1C. Renegade Version   :^5'+ver);
      printacr('^1D. SysOp chat hours :^5'+mln(phours('*None*',lowtime,hitime),16)+
               '^1E. Minimum baud hours :^5'+phours('Always allowed',minbaudlowtime,minbaudhitime));
      printacr('^1F. Regular DL hours :^5'+mln(phours('Always allowed',dllowtime,dlhitime),16)+
               '^1G. Minimum baud DL hrs:^5'+phours('Always allowed',minbauddllowtime,minbauddlhitime));
      printacr('^1H. BBS Passwords                     '+
               '^1I. Pre-event warning  :^5'+cstr(eventwarningtime)+' seconds');
      printacr('^1J. Startout menu    :^5'+mln(allstartmenu,16)+
               '^1K. Bulletin Prefix    :^5'+bulletprefix);
      printacr('^1L. Multinode support:^5'+mln(onoff(general.multinode),16)+
               '^1M. Network mode       :^5'+onoff(general.networkmode) + ^M^J);

      printacr('^1 0. Main data files dir.    :^5'+datapath);
      printacr('^1 1. Miscellaneous Files dir.:^5'+miscpath);
      printacr('^1 2. Message file storage dir:^5'+msgpath);
      printacr('^1 3. Menu file directory     :^5'+menupath);
      printacr('^1 4. Nodelist (Version 7) dir:^5'+nodepath);
      printacr('^1 5. Log files/trap files dir:^5'+logspath);
      printacr('^1 6. Temporary directory     :^5'+temppath);
      printacr('^1 7. Protocols directory     :^5'+protpath);
      printacr('^1 8. Archivers directory     :^5'+arcspath);
      printacr('^1 9. File attach directory   :^5'+fileattachpath);
      printacr('^1 R. RAM drive/multinode path:^5'+multpath);
      prt(^M^J'Enter selection (A-M,R,0-9) [Q]uit : ');
      onek(c,'QABCDEFGHIJKLMR0123456789'^M); nl;
      case c of
        'Q':done:=TRUE;
        'A':begin
              prt('New BBS name: ');
              inputwc(s,80);
              if (s<>'') then bbsname:=s;
              prt(^M^J'New BBS phone number: ');
              input(s,12);
              if (s<>'') then bbsphone:=s;
            end;
        'B':begin
              prt('New SysOp name: '); mpl(30); inputl(s,30);
              if (s<>'') then sysopname:=s;
            end;
        'C':begin
            end;
        'D':if (incom) then
              print('^7This can only be changed locally.')
            else
              gettimerange('Do you want to declare chat hours? ',
                            lowtime,hitime);
        'F':gettimerange('Do you want to declare download hours? ',
                          dllowtime,dlhitime);
        'H':begin
              print('System Passwords:');
              print('  A. SysOp password        :'+sysoppw);
              print('  B. New user password     :'+newuserpw);
              print('  C. Baud override password:'+minbaudoverride);
              prt(^M^J'Change (A-C) : '); onek(c,'QABC'^M);
              if (c in ['A'..'C']) then begin
                case c of
                  'A':prt('New SysOp password: ');
                  'B':prt('New new-user password: ');
                  'C':prt('New minimum baud rate override password: ');
                end;
                mpl(20);
                case c of
                  'A':inputwn1(SysOpPW, 20, 'U', next);
                  'B':inputwn1(NewUserPW, 20, 'U', next);
                  'C':inputwn1(MinBaudOverride, 20, 'U', next);
                end;
              end;
            end;
        'E':gettimerange('Do you want to declare hours people at the minimum baud can logon? ',
                          minbaudlowtime,minbaudhitime);
        'G':gettimerange('Do you want to declare hours people at minimum baud can download ? ',
                          minbauddllowtime,minbauddlhitime);
        'I':begin
              prt('New pre-event warning time ['+cstr(eventwarningtime)+'] : ');
              inu(i);
              if (not badini) then eventwarningtime:=i;
            end;
        'J':begin
              prt('Menu to start all users at: ');
              input(allstartmenu,8);
            end;
        'K':begin
              prt('Default bulletin prefix: ');
              input(bulletprefix,8);
            end;
        'L':if not incom then begin
              multinode:=not multinode;
              savegeneral(FALSE);
              clrscr;
              writeln('Please restart the system.');
              halt;
            end else print('Can only be changed locally.');
        'M':begin
              networkmode := not networkmode;
              if networkmode then
                localsec := TRUE
              else
                localsec := pynq('Do you want local security to remain on? ');
            end;
        '0'..'9','R':begin
              prt('Enter new ');
              case c of
                '0':prt('DATA');     '1':prt('MISC');
                '2':prt('MSGS');     '3':prt('MENUS');
                '4':prt('NODELIST'); '5':prt('TRAP');
                '6':prt('TEMP');     '7':prt('PROT');
                '8':prt('ARCS');     '9':prt('FILE ATTACH');
                'R':prt('MULTI NODE');
              end;
              prt(' path:'^M^J);
              mpl(40); input(s,40);
              if (s<>'') then begin
                if s[length(s)]<>'\' then s:=s+'\';
                if (wantit) then
                  case c of
                    '0':datapath:=s;     '1':miscpath:=s;
                    '2':msgpath:=s;      '3':menupath:=s;
                    '4':nodepath:=s;     '5':logspath:=s;
                    '6':temppath:=s;     '7':protpath:=s;
                    '8':arcspath:=s;     '9':fileattachpath:=s;
                    'R':multpath:=s;
                  end;
              end;
            end;
      end;
    end;
  until (done) or (hangup);
end;

end.
