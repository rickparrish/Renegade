{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration Editor }

unit sysop2k;

interface

uses crt, dos, overlay, common;

procedure pocolors;

implementation

uses file11, file1, mail7, bulletin;



procedure pocolors;
    const
      ColorName:array[0..7] of string[7] =
       ('Black','Blue','Green','Cyan','Red','Magenta','Yellow','White');
var
  c:char;
  i,k:integer;
  s:astr;
  xloaded:integer;
  changed:boolean;
  u:userrec;

  procedure posscheme(x,y:integer);
  var tempscheme:schemerec;
      i,j,k:integer;
  begin
    k:=y; if (y>x) then dec(y);
    dec(x); dec(y);
    seek(SchemeFile,x); read(SchemeFile,tempscheme);
    i:=x; if (x>y) then j:=-1 else j:=1;
    while (i<>y) do
      begin
        if (i+j<filesize(SchemeFile)) then
          begin
            seek(SchemeFile,i+j); read(SchemeFile,Scheme);
            seek(SchemeFile,i); write(SchemeFile,Scheme);
          end;
        inc(i,j);
      end;
    seek(SchemeFile,y); write(SchemeFile,tempscheme);
    Lasterror := IOResult;
  end;

    function dt(n:integer):string;
    var
      s:string[50];
    begin
      s:=ColorName[n and 7]+' on '+ColorName[(n shr 4) and 7];
      if (n and 8)<>0 then s:='Bright ' + s;
      if (n and 128)<>0 then s:='Blinking ' + s;
      dt:=s;
    end;

    function getcolor:byte;
    var
      j:byte;
      b:byte;
    begin
      setc(7); print(^M^J'Colors:'^M^J);
      for j := 0 to 7 do
        begin
          setc(7); prompt(cstr(j)+'. '); setc(j); prompt(mln(ColorName[j],12));
          setc(7); prompt(mrn(cstr(j+8),2)+'. '); setc(j+8); print(mln(ColorName[j]+'!',9));
        end;
      nl;
      prt('Foreground (0-15): '); ini(b);
      if not (b in [0..15]) then
        j := 7
      else
        j := b;
      prt('Background (0-7): '); ini(b);
      if (b in [0..7]) then
        j := j or (b shl 4);
      if pynq('Blinking? ') then
        j := j or 128;
      setc(7); prompt(^M^J'Example: '); setc(j); print(dt(j) + ^M^J);
      Getcolor := j;
    end;
  procedure positionscheme;
  var
    i,j:integer;
  begin
    prt('Move which color scheme? (1-'+cstr(filesize(SchemeFile))+') : '); inu(i);
    if ((not badini) and (i>=1) and (i<=filesize(SchemeFile))) then
       begin
         prt('Move before which color scheme? (1-'+cstr(filesize(SchemeFile)+1)+') : ');
         inu(j);
         if ((not badini) and (j>=1) and (j<=filesize(SchemeFile)+1) and
            (j<>i) and (j<>i+1)) then
           begin
             posscheme(i,j);
             print(^M^J'Updating user records ...');
             reset(uf);
             k := 1;
             if (i > filesize(SchemeFile)) then dec(i);
             if (j > filesize(SchemeFile)) then dec(j);
             while (k < filesize(uf)) do
               begin
                 loadurec(u,k);
                 if (u.colorscheme = i) then
                   begin
                     u.colorscheme := j;
                     saveurec(u,k);
                   end
                 else
                   if (u.colorscheme = j) then
                     begin
                       u.colorscheme := i;
                       saveurec(u,k);
                     end;
                 inc(k);
               end;
             close(uf);
          end;
       end;
    Lasterror := IOResult;
  end;

  procedure insertscheme(i:integer);
  var
    j:integer;
  begin
    for j:=filesize(SchemeFile) downto i do
      begin
        seek(SchemeFile,j - 1);
        read(SchemeFile,Scheme);
        write(SchemeFile,Scheme);
      end;
    Scheme.Description := 'New Color Scheme';
    seek(SchemeFile,i - 1);
    write(SchemeFile,Scheme);
    Lasterror := IOResult;
  end;

  procedure deletescheme(i:integer);
  var
    j:integer;
  begin
    for j := i to filesize(SchemeFile) - 1 do
      begin
        seek(SchemeFile, j);
        read(SchemeFile, Scheme);
        seek(SchemeFile, j - 1);
        write(SchemeFile, Scheme);
      end;
    seek(SchemeFile,filesize(Schemefile) - 1);
    truncate(SchemeFile);
    Lasterror := IOResult;
  end;

  procedure showcolors;
  var
    j:integer;
  begin
    for j := 1 to 10 do
      begin
        setc(Scheme.Color[j]);
        prompt(cstr(j - 1) + ' ');
      end;
    nl;
  end;

  procedure modifyscheme;
  var
    i,j:integer;
    c:char;


    procedure systemcolors;
    var
      c:char;
      i,j:integer;

      procedure liststf;
      var c:integer;
      begin
        nl;
        for c:=1 to 10 do
          begin
            setc(7); prompt(mrn(cstr(c - 1),2) + '. System color ' + mrn(cstr(c - 1),2) + ': ');
            setc(Scheme.Color[c]); print(dt(Scheme.Color[c]));
          end;
      end;

    begin
      c := #0;
      repeat
        cls;
        liststf;
        prt(^M^J'System color to change : ');
        onek(c,'1234567890Q'^M);
        if (c in ['0'..'9']) then
          begin
            i := ord(c) - ord('0') + 1;
            j := GetColor;
            if pynq('Is this correct? ') then
              Scheme.Color[i] := j;
          end;
      until (c = 'Q') or (c = ^M) or (hangup);
    end;

    procedure filecolors;
    var
      c:char;
      j:integer;
      f:ulfrec;
    begin
      repeat
      with Scheme do
        begin
          bnp := FALSE; abort := FALSE;
          display_board_name;
          with f do
            begin
              filename := 'RENEGADE.ZIP';
              description := 'Latest version of Renegade!';
              credits := 0;
              blocks := 2743;
              stowner:= 'Patrick Spence';
              daten := daynum(date)+1;
              vpointer := -1;
              filestat := [];
            end;
          f.date := date; { including this above created compiler bug!! }
          display_file('',f,FALSE);
          with f do
            begin
              filename := 'RG      .ZIP';
              description := 'Latest Renegade upgrade.';
              stowner:= 'Gary Hall';
              blocks := 2158;
            end;
          display_file('RENEGADE',f,FALSE);
          if ((general.uldlratio) and (not general.filecreditratio)) then
            s:=mln('',25)
          else
            s:=mln('',31);
          printacr(s+'This is the latest upgrade available');
          printacr(s+'Uploaded by: Mi Dixie Wrecked');
          nl;
          lcmds3(20,3,'A Border','B File Name field','C Crs Field');
          lcmds3(20,3,'D Size field','E Desc Field','F Area field');
          nl;
          lcmds3(20,3,'G File name','H File Points','I File size');
          lcmds3(20,3,'J File desc','K Extended','L Status flags');
          lcmds(20,3,'M Uploader','N Search Match');
          nl;
          prt('Color to change : ');
          onek(c,'ABCDEFGHIJKLMNQ'^M);
          case c of
            'Q',^M:;
          else
            begin
              j := getcolor;
              if pynq('Is this correct? ') then
                Scheme.Color[ord(c) - 54] := j;
            end;
          end;
        end;
      until (c = 'Q') or (c = ^M) or (hangup);
    end;

    procedure msgcolors;
    var
      c:char;
      j:integer;
      f:ulfrec;
    begin
      repeat
      with Scheme do
        begin
          abort := FALSE;
          cls; { starts at color 28 }
          printacr('ÚÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄ¿');
          printacr('³ Msg# ³ Sender            ³ Receiver           ³  '+
                   'Subject           ³! Posted ³');
          printacr('ÀÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÙ');
          printacr('''* "1#      Herb Avore          $Peter Abbot          %Y2K!               &01/01/93');
          printacr('''* "2#      Robin Banks         $Helen Beck           %Re: Renegade       &01/01/93');
          printacr('''> "3#      Noah Zark           $Lou Zerr             %Modems             &01/01/93');
          nl;
          lcmds3(20,3,'A Border','B Msg Num field','C Sender Field');
          lcmds3(20,3,'D Receiver field','E Subject Field','F Date field');
          nl;
          lcmds3(20,3,'G Msg Num','H Msg Sender','I Msg Receiver');
          lcmds3(20,3,'J Subject','K Msg Date','L Status flags');
          nl;
          prt('Color to change : ');
          onek(c,'ABCDEFGHIJKLQ'^M);
          case c of
            'Q',^M:;
          else
            begin
              j := getcolor;
              if pynq('Is this correct? ') then
                Scheme.Color[ord(c) - 37] := j;
            end;
          end;
        end;
      until (c = 'Q') or (c = ^M) or (hangup);
    end;


    procedure fileareacolors;
    var
      c:char;
      j:integer;
      f:ulfrec;
    begin
      repeat
      with Scheme do
        begin
          abort := FALSE;
          fbaselist(TRUE);   { starts at 45 }
          nl;
          lcmds3(20,3,'A Border','B Base Num field','C Base Name Field');
          nl;
          lcmds3(20,3,'D Scan Indicator','E Base Number','F Base Name');
          nl;
          prt('Color to change : ');
          onek(c,'ABCDEFQ'^M);
          case c of
            'Q',^M:;
          else
            begin
              j := getcolor;
              if pynq('Is this correct? ') then
                Scheme.Color[ord(c) - 20] := j;
            end;
          end;
        end;
      until (c = 'Q') or (c = ^M) or (hangup);
    end;

    procedure msgareacolors;
    var
      c:char;
      j:integer;
      f:ulfrec;
    begin
      repeat
      with Scheme do
        begin
          abort := FALSE;
          mbaselist(TRUE);   { starts at 55 }
          nl;
          lcmds3(20,3,'A Border','B Base Num field','C Base Name Field');
          nl;
          lcmds3(20,3,'D Scan Indicator','E Base Number','F Base Name');
          nl;
          prt('Color to change : ');
          onek(c,'ABCDEFQ'^M);
          case c of
            'Q',^M:;
          else
            begin
              j := getcolor;
              if pynq('Is this correct? ') then
                Scheme.Color[ord(c) - 10] := j;
            end;
          end;
        end;
      until (c = 'Q') or (c = ^M) or (hangup);
    end;

    procedure qwkcolors;
    var
      c:char;
      j:integer;
      f:ulfrec;
    begin
      repeat
      with Scheme do  { starts at 115 }
        begin
          abort := FALSE;
          cls;
          print(centre('|The QWKÿSystem is now gathering mail.') + ^M^J);
          printacr('sÚÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄ¿');
          printacr('s³t Num s³u Message base name     s³v  Short  s³w Echo s³x  Total  '+
                   's³y New s³z Your s³{ Size s³');
          printacr('sÀÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÙ');
          printacr('   }1    ~General                 GENERAL    €No      530     ‚328    ƒ13    „103k');
          printacr('   }2    ~Not so General          NSGEN      €No      854     ‚ 86    ƒ15     „43k');
          printacr('   }3    ~Vague                   VAGUE      €No      985     ‚148     ƒ8     „74k'^M^J);

          lcmds3(20,3,'A Border','B Base num field','C Base name field');
          lcmds3(20,3,'D Short field','E Echo field','F Total field');
          lcmds3(20,3,'G New field','H Your field','I Size field');
          nl;
          lcmds3(20,3,'J Title','K Base Number','L Base name');
          lcmds3(20,3,'M Short','N Echo flag','O Total Msgs');
          lcmds3(20,3,'P New Msgs','R Your Msgs','S Msgs size');
          nl;
          prt('Color to change : ');
          onek(c,'ABCDEFGHIJKLMNOPRSQ'^M);
          case c of
            'Q',^M:;
          else
            begin
              j := getcolor;
              if pynq('Is this correct? ') then
                if (c < 'Q') then
                  Scheme.Color[ord(c) + 50] := j
                else
                  Scheme.Color[ord(c) + 49] := j;
            end;
          end;
        end;
      until (c = 'Q') or (c = ^M) or (hangup);
    end;

    procedure emailcolors;
    var
      c:char;
      j:integer;
      f:ulfrec;
    begin
      repeat
      with Scheme do  { starts at 135 }
        begin
          abort := FALSE;
          cls;
          abort := FALSE;
          printacr('‡ÚÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
          printacr('‡³ˆ Num ‡³‰ Date/Time         ‡³Š Sender                 ‡³‹ Subject                  ‡³');
          printacr('‡ÀÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
          printacr('    Œ1  01 Jan 1993  01:00a Izzy Backyet             Renegade');
          printacr('    Œ1  01 Jan 1993  01:00a Rhoda Bote               Upgrades'^M^J);

          lcmds3(20,3,'A Border','B Number field','C Date/Time field');
          lcmds(20,3,'D Sender field','E Subject field');
          nl;
          lcmds3(20,3,'F Number','G Date/Time','H Sender');
          lcmds(20,3,'I Subject','');
          nl;
          prt('Color to change : ');
          onek(c,'ABCDEFGHIQ'^M);
          case c of
            'Q',^M:;
          else
            begin
              j := getcolor;
              if pynq('Is this correct? ') then
                Scheme.Color[ord(c) + 70] := j;
            end;
          end;
        end;
      until (c = 'Q') or (c = ^M) or (hangup);
    end;

  begin
    c := #0;
    xloaded := -1;
    prt('Begin editing at which? (1-'+cstr(filesize(SchemeFile))+') : '); inu(i);
    if (i > 0) and (i <= filesize(SchemeFile)) then
      repeat
        if (i <> xloaded) then
          begin
            seek(SchemeFile, i -1);
            read(SchemeFile, Scheme);
            xloaded := i;
          end;
        if (c <> '?') then
          begin
            abort := FALSE;  next := FALSE;
            cls;
            printacr('Color Scheme ' + cstr(i) + ' of ' + cstr(filesize(SchemeFile)));
            nl;
            printacr('^11. Description   : ^5' + Scheme.Description);
            prompt  ('^12. System colors : ');
            showcolors;
            printacr('^13. File Listings');
            printacr('^14. Message Listings');
            printacr('^15. File Area Listings');
            printacr('^16. Message Area Listings');
            printacr('^1A. Offline Mail screen');
            printacr('^1B. Private Mail Listing');
          end;
        nl;
        prt('Edit menu (?=Help) : ');
        onek(c,'123456ABQ[]FL?'^M);
        case c of
          '?':begin
                nl;
                print(' #:Modify item   <CR>Redisplay screen');
                lcmds(15,3,'[Back Entry',']Forward Entry');
                lcmds(15,3,'First Entry','Last Entry');
              end;
          ']':if (i < filesize(SchemeFile)) then
                inc(i);
          '[':if (i > 1) then
                dec(i);
          'F':i := 1;
          'L':i := filesize(SchemeFile);
          '1':begin
                prt('New description: ');
                mpl(30);
                inputwn(Scheme.Description,30,changed);
              end;
          '2':systemcolors;
          '3':filecolors;
          '4':msgcolors;
          '5':fileareacolors;
          '6':msgareacolors;
          'A':qwkcolors;
          'B':emailcolors;
        end;
        if (pos(c,'Q[]FLJ') <> 0) then
          begin
            seek(SchemeFile, xloaded - 1);
            write(SchemeFile, Scheme);
          end;
      until (c = 'Q') or (hangup);
   end;

begin
  reset(SchemeFile);
  c := #0;
  repeat
    if (c <> '?') then
      begin
        cls;
        abort := FALSE; next := FALSE;
        printacr('^0NN'+seperator+mln('Description',30)+seperator+'Colors');
        printacr('^4==:==============================:============================');
        abort:=FALSE; next:=FALSE;
        i := 1;
        seek(SchemeFile, 0);
        while (FilePos(SchemeFile) < filesize(SchemeFile)) and (not hangup) and (not abort) do
          begin
            read(SchemeFile, Scheme);
            prompt('^3' + mn(i,2) + ' ' + mln(Scheme.Description,30) + ' ');
            showcolors;
            wkey;
            inc(i);
          end;
        abort := FALSE; next := FALSE;
      end;
      prt(^M^J'Color Scheme editor (?=Help) : ');
      onek(c,'QDIMP?'^M);
      case c of
        '?':begin
              print(^M^J'<CR>Redisplay screen');
              lcmds(15,3,'Delete scheme','Insert scheme');
              lcmds(15,3,'Modify scheme','Position scheme');
              lcmds(15,3,'Quit','');
            end;
        'M':ModifyScheme;
        'P':PositionScheme;
        'D':begin
              prt('Board number to delete? (1-'+cstr(filesize(SchemeFile))+') : '); inu(i);
              if ((not badini) and (i>=1) and (i<=filesize(SchemeFile))) then
                begin
                  deletescheme(i);
                  print('Updating user records ...');
                  reset(uf);
                  k := 1;
                  while (k < filesize(uf)) do
                    begin
                      loadurec(u, k);
                      if (u.colorscheme = i) then
                        begin
                          u.colorscheme := 1;
                          saveurec(u,k);
                        end
                      else
                        if (u.colorscheme > i) then
                          begin
                            dec(u.colorscheme);
                            saveurec(u,k);
                          end;
                      inc(k);
                    end;
                  close(uf);
                end;
            end;
        'I':begin
              prt('Scheme number to insert before? (1-'+cstr(filesize(SchemeFile)+1)+') : '); inu(i);
              if (not badini) and (i>0) and (i<=filesize(SchemeFile)+1) then
                begin
                  sysoplog('* Created color scheme');
                  insertscheme(i);
                  print('Updating user records ...');
                  reset(uf);
                  k := 1;
                  while (k < filesize(uf)) do
                    begin
                      loadurec(u, k);
                      if (u.colorscheme >= i) then
                        begin
                          inc(u.colorscheme);
                          saveurec(u, k);
                        end;
                      inc(k);
                    end;
                  close(uf);
                end;
            end;
        'Q':;
      end;
  until (c = 'Q') or (hangup);
  { read user's scheme back in }
  if (thisuser.ColorScheme > filesize(SchemeFile)) or (thisuser.colorscheme < 1) then
    Thisuser.ColorScheme := 1;
  seek(SchemeFile, thisuser.ColorScheme - 1);
  read(SchemeFile, Scheme);
  close(SchemeFile);
  Lasterror := IOResult;
end;

end.
