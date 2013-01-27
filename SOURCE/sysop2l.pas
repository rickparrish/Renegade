{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration - File and Archive Setup }

unit sysop2l;

interface

uses crt, dos, overlay, common;

procedure poarcconfig;

implementation

function nt(s:astr):string;
begin
  if s<>'' then nt:=s else nt:='*None*';
  if s[1] = '/' then begin
    s:='"'+s+'" - ';
    case s[3] of
      '1':nt:=s+'*Internal* ZIP viewer';
      '2':nt:=s+'*Internal* ARC/PAK viewer';
      '3':nt:=s+'*Internal* ZOO viewer';
      '4':nt:=s+'*Internal* LZH viewer';
      '5':nt:=s+'*Internal* ARJ viewer';
    end;
  end;
end;

function nt2(i:integer):string;
begin
  if i<>-1 then nt2:=cstr(i) else nt2:='-1 (ignores)';
end;

procedure poarcconfig;
var ii,i2,numarcs:integer;
    c:char;
    s:astr;
    bb:byte;
    changed:boolean;
begin
  numarcs:=1;
  while (general.filearcinfo[numarcs].ext<>'') and (numarcs<=maxarcs) do
    inc(numarcs);
  dec(numarcs);
  c:=' ';
  while (c<>'Q') and (not hangup) do begin
    repeat
      if c<>'?' then begin
        cls;
        print('^5Archive configuration edit');
        nl;
        abort:=FALSE; next:=FALSE;
        printacr('^3 NN'+seperator+'Ext'+seperator+'Compression cmdline      '+
                 seperator+'Decompression cmdline    '+seperator+'Success Code');
        printacr('^4 ==:===:=========================:=========================:============');
        ii:=1;
        while (ii<=numarcs) and (not abort) and (not hangup) do begin
          with general.filearcinfo[ii] do begin
            if (active) then s:='^5+' else s:='^1-';
            s:=s+'^0'+mn(ii,2)+' ^3'+mln(ext,3)+' ^5'+
                 +mln(arcline,25)+' '+mln(unarcline,25)+' '+
                 nt2(succlevel);
            printacr(s);
          end;
          inc(ii);
        end;
        nl;
        for bb:=1 to 3 do begin
          s:=general.filearccomment[bb]; if s='' then s:='*None*';
          printacr('^1    '+cstr(bb)+'. Archive comment file: ^5'+s);
        end;
        nl;
      end;
      prt(^M^J'Enter selection (1-3, I,D,M) [Q]uit : ');
      onek(c,'Q?DIM123'^M);
      nl;
      case c of
        '?':begin
              print('<CR>Redisplay screen');
              print('1-3:Archive comments files');
              lcmds(16,3,'Insert archive','Delete archive');
              lcmds(16,3,'Modify archives','Quit and save');
            end;
        'M':begin
              prt('Begin editing at which? '); ini(bb);
              if (not badini) and (bb>=1) and (bb<=numarcs) then begin
                i2:=bb;
                while (c<>'Q') and (not hangup) do begin
                  repeat
                    if c<>'?' then begin
                      cls;
                      print('Archive #'+cstr(i2)+' of '+cstr(numarcs) + ^M^J);
                      with general.filearcinfo[i2] do begin
                        abort:=FALSE; next:=FALSE;
                        printacr('^11. Active                 : ^5'+syn(active));
                        printacr('^12. Extension name         : ^5'+ext);
                        printacr('^13. Interior list method   : ^5'+nt(listline));
                        printacr('^14. Compression cmdline    : ^5'+nt(arcline));
                        printacr('^15. Decompression cmdline  : ^5'+nt(unarcline));
                        printacr('^16. File testing cmdline   : ^5'+nt(testline));
                        printacr('^17. Add comment cmdline    : ^5'+nt(cmtline));
                        printacr('^18. errorlevel for success : ^5'+nt2(succlevel));
                        printacr('^1Q. Quit');
                      end;
                    end;
                    prt(^M^J'Edit menu: (1-8,[,],Q) : ');
                    onek(c,'Q12345678[]?'^M);
                    nl;
                    case c of
                      '?':begin
                            print('^1 #:Modify item  <CR>Redisplay screen');
                            lcmds(14,3,'[Back archive',']Forward archive');
                            lcmds(14,3,'Quit and save','');
                          end;
                      '1'..'8':
                          with general.filearcinfo[i2] do
                            case c of
                              '1':active:=not active;
                              '2':begin
                                    prt('New extension: '); input(s,3);
                                    if s<>'' then ext:=s;
                                  end;
                              '3'..'7':
                                  begin
                                    prt('New commandline: ');
                                    inputl(s,25);
                                    if s<>'' then begin
                                      if s=' ' then
                                        if pynq('Set to NULL string? ') then
                                          s:='';
                                      if s<>' ' then
                                        case c of
                                          '3':listline:=s;
                                          '4':arcline:=s;
                                          '5':unarcline:=s;
                                          '6':testline:=s;
                                          '7':cmtline:=s;
                                        end;
                                    end;
                                  end;
                              '8':begin
                                    prt('New errorlevel: '); inu(ii);
                                    if not badini then
                                      general.filearcinfo[i2].succlevel:=ii;
                                  end;
                            end;
                      '[':if i2>1 then dec(i2) else c:=' ';
                      ']':if i2<numarcs then inc(i2) else c:=' ';
                    end;
                  until (c in ['Q','[',']']) or (hangup);
                end;
              end;
              c:=' ';
            end;
        'D':begin
              prt('Delete which? '); ini(bb);
              if (not badini) and (bb in [1..numarcs]) then begin
                prompt(^M^J'^3'+general.filearcinfo[bb].ext);
                if pynq('   Delete it? ') then begin
                  for i2:=bb to numarcs-1 do
                    general.filearcinfo[i2]:=general.filearcinfo[i2+1];
                  general.filearcinfo[numarcs].ext:='';
                  dec(numarcs);
                end;
              end;
            end;
        'I':if numarcs<>maxarcs then begin
              prt('Insert before which (1-'+cstr(numarcs+1)+') : ');
              ini(bb);
              if (not badini) and (bb in [1..numarcs+1]) then begin
                if bb<>numarcs+1 then
                  for i2:=numarcs+1 downto bb+1 do
                    general.filearcinfo[i2]:=general.filearcinfo[i2-1];
                with general.filearcinfo[bb] do begin
                  active:=FALSE;
                  ext:='AAA';
                  listline:=''; arcline:=''; unarcline:='';
                  testline:=''; cmtline:=''; succlevel:=-1;
                end;
                inc(numarcs);
              end;
            end;
        '1'..'3':
            begin
              bb:=ord(c)-48;
              prt('New comment file #'+c+': ');
              inputwnwc(general.filearccomment[bb],32,changed);
            end;
      end;
    until (c='Q') or (hangup);
  end;
end;

end.
