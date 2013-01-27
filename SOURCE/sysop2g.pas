{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration -  New user stuff }

unit sysop2g;

interface

uses crt, dos, overlay, common;

procedure ponewauto;

implementation

uses sysop3;

procedure editone(level:char);
var done:boolean;
    c:char;
    b:byte;
    i:integer;
    s:string[30];


  function show_arflags:string;
  var c:char;
      s:string[26];
  begin
    s:='';
    for c:='A' to 'Z' do
      if c in general.validation[level].newar then
        s := s + c
      else
        s := s + '-';
    show_arflags:=s;
  end;

  function show_restric:string;
  var r:uflags;
      s:string[15];
  begin
    s := '';
    for r := rlogon to rmsg do
      if r in general.validation[level].newac then
        s := s + copy('LCVUA*PEKM',ord(r)+1,1)
      else
        s := s + '-';

    s := s+'/';

    for r:=fnodlratio to fnodeletion do
      if r in general.validation[level].newac then
        s := s + copy('1234',ord(r)-19,1)
      else
        s := s + '-';
    show_restric:=s;
  end;

  procedure autoswac(r:uflags);
  begin
    if r in general.validation[level].newac then
      general.validation[level].newac := general.validation[level].newac - [r]
    else
      general.validation[level].newac := general.validation[level].newac + [r]
  end;

  procedure autoacch(c:char);
  begin
    case c of
      'L':autoswac(rlogon);
      'C':autoswac(rchat);
      'V':autoswac(rvalidate);
      'U':autoswac(ruserlist);
      'A':autoswac(ramsg);
      '*':autoswac(rpostan);
      'P':autoswac(rpost);
      'E':autoswac(remail);
      'K':autoswac(rvoting);
      'M':autoswac(rmsg);
      '1':autoswac(fnodlratio);
      '2':autoswac(fnopostratio);
      '3':autoswac(fnocredits);
      '4':autoswac(fnodeletion);
    end;
  end;

begin
  done:=FALSE;
  repeat
    if (c <> '?') then
      begin
        cls;
        abort:=FALSE; next:=FALSE;
        printacr('^5Subscription level ' + level);
        nl;
        if (level = 'A') then
          general.validation['A'].description := 'New User Settings';
        printacr('^1A. Description: ^5'+general.validation[level].description);
        printacr('^1B. New SL     : ^5'+cstr(general.validation[level].newsl));
        printacr('^1C. New DSL    : ^5'+cstr(general.validation[level].newdsl));
        printacr('^1D. AR flags   : ^5'+show_arflags);
        printacr('^1E. AC flags   : ^5'+show_restric);
        printacr('^1G. New credit : ^5'+cstr(general.validation[level].newcredit));
        if (general.validation[level].expiration > 0) then
          s := cstr(general.validation[level].expiration) + ' days'
        else
          s := 'No expiration';
        printacr('^1H. Expiration : ^5' + s);
        if (general.validation[level].expireto in ['A'..'Z']) then
          s := general.validation[level].expireto + ' (' +
               general.validation[general.validation[level].expireto].description + ')'
        else
          s := 'No change';
        printacr('^1I. Expire to  : ^5' + s);
        printacr('^1K. AR upgrade : ^5'+aonoff(general.validation[level].softar,'Soft','Hard'));
        printacr('^1L. AC upgrade : ^5'+aonoff(general.validation[level].softac,'Soft','Hard'));
        printacr('^1M. Start menu : ^5'+general.validation[level].newmenu);
      end;
    prt(^M^J'Enter selection (A-M) [Q]uit : ');
    onek(c,'QABCDEGHIJKLM[]?'^M); nl;
    case c of
      'A':begin
            prt('New description: ');
            inputwn(general.validation[level].description,25,done);
            done := FALSE;
          end;
      'B':begin
            prt('Enter new SL: '); mpl(3); ini(b);
            if not badini then general.validation[level].newsl:=b;
          end;
      'C':begin
            prt('Enter new DSL: '); mpl(3); ini(b);
            if not badini then general.validation[level].newdsl:=b;
          end;
      'D':repeat
            prt('Toggle AR Flag? (A-Z) <CR>=Quit ['+show_arflags+'] : ');
            onek(c,'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M);
            if c in ['A'..'Z'] then
              if c in general.validation[level].newar then
                general.validation[level].newar := general.validation[level].newar-[c]
              else
                general.validation[level].newar := general.validation[level].newar+[c];
          until (c=^M) or (hangup);
      'E':repeat
            prt('Restrictions [?]Help <CR>=Quit ['+show_restric+'] : ');
            onek(c,'Q?LCVUA*PEKM1234'^M);
            case c of
              'Q',^M:c:='Q';
              '?':restric_list;
            else
              autoacch(c);
            end;
          until (c='Q') or (hangup);
      'G':begin
            prt('Enter additional credit: '); mpl(5); inu(i);
            if not badini then general.validation[level].newcredit := i;
          end;
      'H':begin
            prt('Enter days until expiration: '); mpl(5); inu(i);
            if not badini then general.validation[level].expiration := i;
          end;
      'I':begin
            prt('Enter expiration level: '); mpl(5);
            onek(c,' ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M);
            if (c in [' ','A'..'Z']) then
              general.validation[level].expireto := c;
          end;
      'K':general.validation[level].softar := not general.validation[level].softar;
      'L':general.validation[level].softac := not general.validation[level].softac;
      ']':if (level < 'Z') then
            inc(level);
      '[':if (level > 'A') then
            dec(level);
      'J':begin
            prt('Jump to entry: ');
            onek(c,'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M);
            if (c >= 'A') and (c <= 'Z') then
              level := c;
          end;
      'F':level := 'A';
      'L':level := 'B';
      'M':begin
            prt('Enter startout menu: ');
            inputwn1(general.validation[level].newmenu,8,'U',done);
            done := FALSE;
          end;
      '?':begin
            print(' #:Modify item   <CR>Redisplay screen');
            lcmds(15,3,'[Back entry',']Forward entry');
            lcmds(15,3,'Jump to entry','Quit');
          end;
      'Q':done:=TRUE;
    end;
  until (done) or (hangup);
end;

procedure ponewauto;
var
  c:char;
  Index:char;
begin
  c := #0;
  repeat
    if (c <> '?') then
      begin
        cls; abort := FALSE; next := FALSE;
        Index := '?';
        while (Index <= 'X') and (not abort) and (not hangup) do
          begin
            inc(Index,2);
            c := Index; inc(c);
            printacr(Index + '. ' + mln(general.validation[Index].description,30) +
                     c + '. ' + general.validation[c].description);
          end;
        nl;
      end;
    prt('Subscription editor (?=help) : ');
    onek(c,'QM?'^M);
    case c of
      '?':begin
            print(^M^J'^1<^3CR^1>Redisplay screen');
            lcmds(16,3,'Modify level','Quit');
          end;
     'M':begin
           prt('Begin editing at which? (A-Z) : ');
           onek(c,'ABCDEFGHIJKLMNOPQRSTUVWXYZ'^M);
           if (c in ['A'..'Z']) then
             editone(c);
         end;
    end;
  until (hangup) or (c = 'Q');
end;

end.
