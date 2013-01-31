{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
PROGRAM Renemail;       {eatus echomailius}

{$A+,I-,E-,F+}

(* {A+,B-,D-,E-,F+,G+,N-,R-,S-,V-,I-} *)

uses crt, dos, timefunc {$IFDEF WIN32}, Strings{$ENDIF};

{$I RECORDS.PAS}

type
  fidorecord = record
    FromUserName : string[35];
    ToUserName   : string[35];
    Subject      : string[71];
    DateTime     : string[19];
    TimesRead    : SmallWord;
    DestNode     : SmallWord;
    OrigNode     : SmallWord;
    Cost         : SmallWord;
    OrigNet      : SmallWord;
    DestNet      : SmallWord;
    Filler       : array[1..8] of char;
    Replyto      : SmallWord;
    Attribute    : SmallWord;
    NextReply    : SmallWord;
  end;

var
    Lasterror :integer;
    header : fidorecord;
    dt : datetime;
    msgtfile : file;
    hiwaterf : file of integer;
    statusf : file of generalrec;
    statusr : generalrec;
    boardf : file of boardrec;
    boardr : boardrec;
    msghdrf : file of mheaderrec;
    msghdr : mheaderrec;
    msgtxtf : file;
    uf : file of userrec;
    user : userrec;
    sf : file of useridxrec;
    toi, fromi, subjecti, datetime : string;
    i, j, lines, msgnumber, highest, lowest, board, textsize,
    msglength, msgpointer : integer;
    c : char;
    attribute : word;
    ispm : boolean;
    dirinfo : searchrec;
    s, startdir, nos, datapath, msgpath, netmailpath : string [81];
    msgtxt : string [255];
    buffer : array [1..32767] of char;
    fcb : array [1..37] of char;
{$IFDEF MSDOS}
    regs : registers;
{$ENDIF}
    x : byte;

const
  netmailonly : boolean = FALSE;
  isnetmail : boolean = FALSE;
  fastpurge : boolean = TRUE;
  process_netmail : boolean = TRUE;
  purge_netmail : boolean = TRUE;
  absolute_scan : boolean = FALSE;
  ignore_1msg : boolean = TRUE;

{$IFDEF WIN32}
(* REENOTE 
   In BP/TP you can do this:

   var
     MySet: NetAttribs;
     MyWord: Word;
   begin
     MySet := [Private, Crash];
     MyWord := Word(MySet);
     { MyWord now contains the value 3 in BP/TP }
	 { but VP refuses to compile the code due to Word(MySet) }
   end;

   In VP this typecast isn't allowed (maybe there's a compiler setting to allow it, didn't look actually)
   so this function converts from a set to a word type.
   
   While this function should work for both BP/TP and for VP, I'm only using it for VP and using the
   original cast for BP/TP, since there's no need to change what isn't broken
*)
function NetAttribsToWord(inSet: NetAttribs): Word;
var
  Result: Word;
begin
  Result := 0;
  if (Private in inSet) then result := result + 1;
  if (Crash in inSet) then result := result + 2;
  if (Recd in inSet) then result := result + 4;
  if (NSent in inSet) then result := result + 8;
  if (FileAttach in inSet) then result := result + 16;
  if (Intransit in inSet) then result := result + 32;
  if (Orphan in inSet) then result := result + 64;
  if (KillSent in inSet) then result := result + 128;
  if (Local in inSet) then result := result + 256;
  if (Hold in inSet) then result := result + 512;
  if (Unused in inSet) then result := result + 1024;
  if (FileRequest in inSet) then result := result + 2048;
  if (ReturnReceiptRequest in inSet) then result := result + 4096;
  if (IsReturnReceipt in inSet) then result := result + 8192;
  if (AuditRequest in inSet) then result := result + 16384;
  if (FileUpdateRequest in inSet) then result := result + 32768;
  NetAttribsToWord := Result;
end;
{$ENDIF}

function Hex(i : longint; j:byte) : String;
const
  hc : array[0..15] of Char = '0123456789ABCDEF';
var
  one,two,three,four: Byte;
begin
  one   := (i and $000000FF);
  two   := (i and $0000FF00) shr 8;
  three := (i and $00FF0000) shr 16;
  four  := (i and $FF000000) shr 24;

  Hex[0] := chr(j);          { Length of String = 4 or 8}
  if (j = 4) then
    begin
      Hex[1] := hc[two shr 4];
      Hex[2] := hc[two and $F];
      Hex[3] := hc[one shr 4];
      Hex[4] := hc[one and $F];
    end
  else
    begin
      Hex[8] := hc[one and $F];
      Hex[7] := hc[one shr 4];
      Hex[6] := hc[two and $F];
      Hex[5] := hc[two shr 4];
      hex[4] := hc[three and $F];
      hex[3] := hc[three shr 4];
      hex[2] := hc[four and $F];
      hex[1] := hc[four shr 4];
    end;
end {Hex} ;

function Usename(b:byte; s:astr):string;
begin
  case b of
    1,
    2:s:='Anonymous';
    3:s:='Abby';
    4:s:='Problemed Person';
  end;
  Usename:=s;
end;

function existdir(fn:string):boolean;
var dirinfo:searchrec;
begin
  while (fn[length(fn)] = '\') do
    dec(fn[0]);
  findfirst(fn,anyfile,dirinfo);
  existdir:=(doserror=0) and (dirinfo.attr and $10=$10);
end;

{$IFDEF MSDOS}
function StrPas(Str: String): String; assembler;
asm
	PUSH	DS
	CLD
	LES	DI,Str
	MOV	CX,0FFFFH
	XOR	AL,AL
	REPNE	SCASB
	NOT	CX
	DEC	CX
	LDS	SI,Str
	LES	DI,@Result
	MOV	AL,CL
	STOSB
	REP	MOVSB
	POP	DS
end;
{$ENDIF}
{$IFDEF WIN32}
function StrPas(Str: String): String;
var
  i: Integer;
  Result: String;
begin
  Result := Str;
  for i := 1 to 255 do
  begin
    if (Str[i] = #0) then
    begin
      Result[0] := Chr(i - 1);
      Break;
    end;
  end;
  StrPas := Result;
end;
{$ENDIF}

function stripname(s:astr):astr;
var
  n:integer;
begin
  n := length(s);
  while (n > 0) and (pos(s[n],':\/') = 0) do
    dec(n);
  delete(s,1,n);
  stripname := s;
end;

function allcaps (const s : string) : string;
var
  q : integer;
begin
  allcaps [0] := s [0];
  for q := 1 to length (s) do
    allcaps [q] := upcase (s [q]);
end;

function caps (s : string) : string;
var
  i : integer;
begin
  for i := 1 to length (s) do
    if (s [i] in ['A'..'Z']) then
       s [i] := chr (ord (s [i]) + 32);

  for i := 1 to length (s) do
    if (not (s [i] in ['A'..'Z', 'a'..'z', chr (39) ]) ) then
      if (s [i + 1] in ['a'..'z']) then
         s [i + 1] := upcase (s [i + 1]);
  s [1] := upcase (s [1]);
  caps := s;
end;

function searchuser(Uname:string): word;
var
  Current:integer;
  Done:boolean;
  IndexR:useridxrec;
begin
  reset(sf);
  if (IOResult > 0) then
    exit;

  Uname := Allcaps(UName);

  Current := 0;
  Done := FALSE;

  if (filesize(sf) > 0) then
    repeat
      seek(sf, Current);
      read(sf, IndexR);
      if (Uname < IndexR.Name) then
        Current := IndexR.Left
      else
        if (Uname > IndexR.Name) then
          Current := IndexR.Right
        else
          Done := TRUE;
    until (Current = -1) or (Done);

  close(sf);

  if (Done) and not (IndexR.Deleted) then
    SearchUser := IndexR.Number
  else
    SearchUser := 0;

  Lasterror := IOResult;
end;

function stripcolor (o : string) : string;
var i,j : byte;
    s : string;
begin
  i := 0;
  s := '';
  while (i < length (o) ) do begin
    inc (i);
    case o [i] of
     #128..#255:if (mbfilter in boardr.mbstat) then
                  s := s + chr(ord(o[i]) and 128)
                else
                  s := s + o[i];
     '^' : if o [i + 1] in [#0..#9, '0'..'9'] then
              inc (i) else s := s + '^';
     '|' : if (mbfilter in boardr.mbstat) and (o[i + 1] in ['0'..'9']) then
              begin
                j:=0;
                while (o [i + 1] in ['0'..'9']) and (i <= length (o) )
                  and (j<=2) do begin
                    inc (i);
                    inc (j)
                  end
              end
           else
              s := s + '|'
      else s := s + o [i];
    end;
  end;
  stripcolor := s;
end;

procedure aborterror(const s:string);
begin
  writeln(s);
  halt(255);
end;

  function value (s : string) : longint;
  var i : longint;
      j : integer;
  begin
   val (s, i, j);
   if (j <> 0) then begin
      s[0]:=chr(j-1);
      val (s, i, j)
    end;
    value := i;
    if (s = '') then value := 0;
  end;

  function cstr (i : longint) : string;
  var c : string [16];
  begin
    str (i, c);
    cstr := c;
  end;

  procedure getmsglst (const dir : string);
  var hiwater : integer;
  begin
      hiwater := 1;
      if not isnetmail then
        begin
          assign (hiwaterf, dir + 'HI_WATER.MRK');
          reset (hiwaterf);
          if ioresult <> 0 then
            begin
               rewrite (hiwaterf);
               write (hiwaterf, hiwater);
               if ioresult <> 0 then
                 aborterror('error creating ' + dir + '\HI_WATER.MRK');
            end
          else
            begin
              read (hiwaterf, hiwater);
              i := ioresult;
              findfirst (dir + cstr (hiwater) + '.MSG', AnyFile, dirinfo);
              if doserror <> 0 then hiwater := 1;
            end;
            close (hiwaterf);
        end;
      findfirst (dir + '*.MSG', AnyFile, dirinfo);
      highest := 1;
      lowest := 32767;
      while doserror = 0 do
        begin
          i := value (dirinfo.name);
          if i < lowest then lowest := i;
          if i > highest then highest := i;
          findnext (dirinfo);
        end;

      if hiwater <= highest then
        if hiwater > 1 then
          lowest := hiwater + 1;

      if (ignore_1msg) then
        if (lowest = 1) and (highest > 1) then
          lowest := 2;
    Lasterror := IOResult;
  end;

  procedure getpaths;

     procedure badpath(const s:string);
     begin
       writeln('The ',s,' path is bad.  Please correct it.');
       halt;
     end;

  begin
    s := fsearch ('RENEGADE.DAT', getenv ('PATH') );
    assign (statusf, s);
    reset (statusf);
    if (ioresult <> 0) or (s = '') then
      begin
        writeln ('RENEGADE.DAT must be in the current directory or the path.');
        halt (1);
      end;
    read (statusf, statusr);
    datapath := statusr.datapath;
    if not (existdir(datapath)) then
      badpath('DATA');
    netmailpath := statusr.netmailpath;
    if not (existdir(netmailpath)) then
      badpath('NETMAIL');
    msgpath := statusr.msgpath;
    if not (existdir(msgpath)) then
      badpath('MSGS');
    close (statusf);
    if ioresult <> 0 then
      aborterror('error reading from RENEGADE.DAT');
  end;

  procedure updatehiwater (const dir:string; x:integer);
  begin
     assign (hiwaterf, dir + 'HI_WATER.MRK');
     rewrite (hiwaterf);
     write (hiwaterf, x);
     close (hiwaterf);
     i := ioresult;
  end;

  procedure purgedir (const dir : string);
  var purged : boolean;
  begin
{$IFDEF MSDOS}
    if fastpurge then
      begin
        chdir (copy (dir, 1, length (dir) - 1) );
        if (IOResult <> 0) then
          exit;
        if (dir[2] = ':') then
          fcb [1] := chr(ord(dir[1]) - 64)
        else
          fcb [1] := chr(ord(startdir[1]) - 64);
        regs.ds := seg (fcb);
        regs.dx := ofs (fcb);
        regs.ax := $1300;
        msdos (regs);
        purged := (lo (regs.ax) = 0);
      end
    else
      begin
{$ENDIF}
        purged := TRUE;
        findfirst (dir + '*.MSG', AnyFile, dirinfo);
        if doserror <> 0 then
          purged := FALSE
        else
          while doserror = 0 do
            begin
              assign (hiwaterf, dir + dirinfo.name);
              erase (hiwaterf);
              i := ioresult;
              findnext (dirinfo);
             end;
{$IFDEF MSDOS}
      end;
{$ENDIF}
      if not purged then write ('No messages')
         else write ('Purged');
      updatehiwater (dir, 1);
  end;

  function readmsg (x:integer ; const dir:string) : boolean;
  var
    q : boolean;
  begin
    assign (msgtfile, dir + cstr (x) + '.MSG');
    reset (msgtfile, 1);
    q := FALSE;
    if ioresult = 0 then
      begin
        if filesize (msgtfile) >= sizeof(header) then
          begin
          blockread (msgtfile, header, sizeof(header));

          s := StrPas(Header.FromUserName);

          if ((header.attribute and 16) = 16) then
            MsgHdr.fileattached := 1;

          MsgHdr.from.as := s;
          MsgHdr.from.real := s;
          MsgHdr.from.name := s;

          s := StrPas(Header.ToUserName);

          MsgHdr.mto.as := s;
          MsgHdr.mto.real := s;
          MsgHdr.mto.name := s;

          MsgHdr.Subject := StrPas(Header.Subject);

          MsgHdr.OriginDate := StrPas(Header.DateTime);

          q := TRUE;

          if (Header.Attribute and 1 = 1) then
            msghdr.status := [Sent, Prvt]
          else
            msghdr.status := [Sent];

          if isnetmail then
            begin
              q:=FALSE;
              msghdr.from.node := Header.OrigNode;
              msghdr.from.net := Header.OrigNet;
              msghdr.mto.node := Header.DestNode;
              msghdr.mto.net := Header.DestNet;
              msghdr.from.point := 0;
              msghdr.mto.point := 0;
              msghdr.from.zone := 0;
              msghdr.mto.zone := 0;
              if (Header.Attribute and 256 = 0) and
                 (Header.Attribute and 4 = 0) then
                for i := 0 to 19 do
                    if (msghdr.mto.node = statusr.aka[i].node) and
                       (msghdr.mto.net = statusr.aka[i].net) then
                        begin
                          msghdr.mto.zone := statusr.aka[i].zone;
                          msghdr.from.zone := statusr.aka[i].zone;
                          q := TRUE;
                        end;
            end;

        if q then
          begin
            if (filesize(msgtfile) - 190) <= sizeof(buffer) then
              x := filesize(msgtfile) - 190
            else
              x := sizeof(buffer);
            blockread (msgtfile, buffer, x, msglength);
          end;
       end;
       if isnetmail then
         if q and purge_netmail then
            begin
              close (msgtfile);
              erase (msgtfile)
            end
         else if q then
           begin
             Header.Attribute := 260;
             seek (msgtfile, 0);
             blockwrite (msgtfile, header, sizeof(Header));
           end;
       if not (isnetmail and q and purge_netmail) then close(msgtfile);
    end;
    readmsg := q;
    i := ioresult;
  end;

  procedure nextboard(Scanning:boolean);
  var
    GoodBoard:boolean;
  begin
    if board = 0 then
      begin
        i := ioresult;
        assign (boardf, datapath + 'MBASES.DAT');
        reset (boardf);
        i := ioresult;
        if i <> 0 then
          begin
            writeln (i,':Problem accessing ' + datapath + 'MBASES.DAT. Please fix.');
            halt (1);
          end;
      end;

    if board = filesize (boardf) then
      begin
        board := 32767;
        exit;
      end;

    boardr.mbtype := 0;  boardr.mbstat := []; GoodBoard := FALSE;
    while not GoodBoard and (board < filesize(boardf)) do
      begin
        read (boardf, boardr);
        GoodBoard := (boardr.mbtype = 1) and
                     (not scanning or (absolute_scan or (mbscanout in boardr.mbstat)));
        inc(board);
      end;

    if (not GoodBoard) then
      board := 32767
    else
      if scanning and (mbscanout in boardr.mbstat) then
        begin
          seek(boardf, board - 1);
          boardr.mbstat := boardr.mbstat - [mbscanout];
          write(boardf, boardr);
        end;
  end;


  procedure toss;
  var i,j:word;
      z:string [20];
      left, right, gap, oldgap : integer;
  begin
       msghdr.from.anon := 0;
       msghdr.from.usernum := 0;
       msghdr.mto.anon := 0;
       msghdr.mto.usernum := 0;
       msghdr.replyto := 0;
       msghdr.replies := 0;
       msghdr.fileattached := 0;

       getdayofweek (msghdr.dayofweek);
       msghdr.date := getpackdatetime;
       getmsglst (boardr.msgpath);
       if isnetmail and (highest > 1) then lowest := 1;

       if (lowest <= highest) and ((highest > 1) or isnetmail) then begin

          assign (msghdrf, msgpath + boardr.filename + '.HDR');
          reset (msghdrf);
          if (ioresult = 2) then rewrite (msghdrf);

          assign (msgtxtf, msgpath + boardr.filename + '.DAT');
          reset (msgtxtf, 1);
          if (ioresult = 2) then rewrite (msgtxtf, 1);

          seek (msghdrf, filesize (msghdrf) );
          seek (msgtxtf, filesize (msgtxtf) );

          if ioresult <> 0 then
            aborterror('error accessing ' + msgpath + boardr.filename + '.*');

          for msgnumber := lowest to highest do begin
              write (msgnumber : 4);
              if readmsg (msgnumber, boardr.msgpath) then
                with msghdr do begin
                  inc (date);
                  pointer := filesize (msgtxtf) + 1;
                  textsize := 0;
                  msgpointer := 0;
                  nos := '';
                  while (msgpointer < msglength) do begin
                    msgtxt := nos;
                    repeat
                      inc (msgpointer);
                      c := buffer [msgpointer];
                      if not (c in [#0, #10, #13, #141]) then
                        if (length(msgtxt) < 255) then  {msgtxt := msgtxt + c;}
                          begin
                            inc(msgtxt[0]);
                            msgtxt[length(msgtxt)] := c;
                          end;
                    until (
                          (nos = #13) or (c in [#13,#141])
                          or
                          ((length(msgtxt) > 79) and (pos(#27, msgtxt) = 0))
                          or
                          (length(msgtxt) = 254)
                          or
                          (msgpointer >= msglength)
                          );

                    if length (msgtxt) = 254 then
                       msgtxt := msgtxt + #29;

                    i := pos('INTL ', msgtxt);
                    if (i > 0) then
                      begin
                        inc(i, 6);
                        for j := 1 to 8 do
                          begin
                            z := '';
                            while (msgtxt[i] in ['0'..'9']) and (i <= length(msgtxt)) do
                              begin
                                z := z + msgtxt[i];
                                inc(i);
                              end;
                            case j of
                              1:msghdr.mto.zone := value(z);
                              2:msghdr.mto.net := value(z);
                              3:msghdr.mto.node := value(z);
                              4:msghdr.mto.point := value(z);
                              5:msghdr.from.zone := value(z);
                              6:msghdr.from.net := value(z);
                              7:msghdr.from.node := value(z);
                              8:msghdr.from.point := value(z);
                            end;
                            if (j = 3) and (msgtxt[i] <> '.') then
                              inc(j);
                            if (j = 7) and (msgtxt[i] <> '.') then
                              break;
                            inc(i);
                          end;
                      end;

                    if (length (msgtxt) > 79) then
                      begin
                        i := length (msgtxt);
                        while (msgtxt [i] = ' ') and (i > 1) do
                          dec (i);
                        while (i > 65) and (msgtxt [i] <> ' ') do
                          dec (i);

                        nos[0] := chr(length(msgtxt) - i);
                        move(msgtxt[i + 1], nos[1], length(msgtxt) - i);
                        msgtxt[0] := chr(i - 1);

                      end
                    else
                      nos := '';

                    if ( (msgtxt [1] = #1) and (mbskludge in boardr.mbstat) ) or
                       ( (pos ('SEEN-BY', msgtxt) > 0) and (mbsseenby in boardr.mbstat) ) or
                       ( (pos ('* Origin:', msgtxt) > 0) and (mbsorigin in boardr.mbstat) ) then
                       msgtxt := ''
                    else begin
                       inc (msghdr.textsize, length (msgtxt) + 1);
                       blockwrite (msgtxtf, msgtxt, length (msgtxt) + 1);
                    end;
                  end;
                  if isnetmail then begin
                     msghdr.status := msghdr.status + [netmail];
                     msghdr.mto.usernum := SearchUser(msghdr.mto.as);
                     if msghdr.mto.usernum = 0 then
                       msghdr.mto.usernum := 1;
                     seek (uf, msghdr.mto.usernum);
                     read (uf, user);
                     inc (user.waiting);
                     seek (uf, msghdr.mto.usernum);
                     write (uf, user);
                  end;
                  write (msghdrf, msghdr);
                end;
              if msgnumber < highest then write (#8#8#8#8);
              i := ioresult;
          end;
          close (msghdrf);
          close (msgtxtf);
          if not isnetmail then updatehiwater (boardr.msgpath, highest);
       end else write ('No messages');
    Lasterror := IOResult;
  end;

  procedure scan;
  var rgmsgnumber : integer;
      highestwritten : integer;
      AnsiOn,
      scanned : boolean;
  begin
       AnsiOn := FALSE;
       scanned := FALSE;
       getmsglst (boardr.msgpath);
       msgnumber := highest;
       if (not existdir(boardr.msgpath)) then
         begin
           writeln('WARNING: Cannot access ', boardr.msgpath);
           exit;
         end;

       assign (msghdrf, msgpath + boardr.filename + '.HDR');
       reset (msghdrf);
       if ioresult <> 0 then exit;

       assign (msgtxtf, msgpath + boardr.filename + '.DAT');
       reset (msgtxtf, 1);
       if ioresult <> 0 then begin close (msghdrf); exit; end;

       for rgmsgnumber := 1 to filesize (msghdrf) do begin
           seek (msghdrf, rgmsgnumber - 1);
           read (msghdrf, msghdr);
           if not (sent in msghdr.status) and (ioresult = 0) and
              not (mdeleted in msghdr.status) and
              not (isnetmail and not (netmail in msghdr.status)) and
              not (unvalidated in msghdr.status) then begin
              scanned := TRUE;
              inc (msgnumber);
              assign (msgtfile, boardr.msgpath + cstr (msgnumber) + '.MSG');
              rewrite (msgtfile, 1);
              write (rgmsgnumber : 5);

              msghdr.status := msghdr.status + [sent];

              if isnetmail then
                msghdr.status := msghdr.status + [mdeleted];

              seek (msghdrf, rgmsgnumber - 1);
              write (msghdrf, msghdr);

              if (mbrealname in boardr.mbstat) then
                s := caps (msghdr.from.real)
              else
                s := caps (msghdr.from.as);

              s := usename(msghdr.from.anon, s);

              fillchar(Header,sizeof(Header),#0);

              move(s[1],Header.FromUserName[0],length(s));

              if (mbrealname in boardr.mbstat) then
                s := caps (msghdr.mto.real)
              else
                s := caps (msghdr.mto.as);

              s := usename(msghdr.mto.anon, s);

              move(s[1],Header.ToUserName[0],length(s));

              MsgHdr.Subject := stripcolor(MsgHdr.Subject);

              if (not isnetmail) and (msghdr.fileattached > 0) then
                MsgHdr.Subject := StripName(MsgHdr.Subject);

              move(MsgHdr.Subject[1],Header.Subject[0],length(MsgHdr.Subject));

              packtodate (dt, msghdr.date);
              with dt do begin
               s := cstr (day);
                if length (s) < 2 then s := '0' + s;
               s := s + ' ' + copy ('JanFebMarAprMayJunJulAugSepOctNovDec', (month - 1) * 3 + 1, 3) + ' ';
               s := s + copy (cstr (year), 3, 2) + '  ';
               nos := cstr (hour);
               if length (nos) < 2 then nos := '0' + nos;
               s := s + nos + ':';
               nos := cstr (min);
               if length (nos) < 2 then nos := '0' + nos;
               s := s + nos + ':';
               nos := cstr (sec);
              end;
              if length (nos) < 2 then nos := '0' + nos;
              s := s + nos;

              move(s[1],Header.DateTime[0],length(s));

              if isnetmail then begin
                 Header.OrigNet := msghdr.from.net;
                 Header.OrigNode := msghdr.from.node;
                 Header.DestNet := msghdr.mto.net;
                 Header.DestNode := msghdr.mto.node;
              end else begin
                 Header.OrigNet := statusr.aka [boardr.aka].net;
                 Header.OrigNode := statusr.aka [boardr.aka].node;
                 Header.DestNet := 0;
                 Header.DestNode := 0;
              end;

              if isnetmail then
{$IFDEF MSDOS}
                Header.Attribute := word(msghdr.netattribute)
{$ENDIF}
{$IFDEF WIN32}
                Header.Attribute := NetAttribsToWord(msghdr.netattribute)
{$ENDIF}	
                {word(statusr.netattribute)}
              else
                if (prvt in msghdr.status) then
                  Header.Attribute := 257
                else
                  Header.Attribute := 256;

              if (msghdr.fileattached > 0) then
                Header.Attribute := Header.Attribute + 16;

              blockwrite (msgtfile, header, sizeof(Header));
              seek (msgtxtf, msghdr.pointer - 1);

              if isnetmail then begin
                s := 'INTL ' + cstr (msghdr.mto.zone) + ':' + cstr (msghdr.mto.net) + '/' + cstr (msghdr.mto.node);
                s := s + ' ' + cstr (msghdr.from.zone) + ':' + cstr (msghdr.from.net) + '/' + cstr (msghdr.from.node);
                s := s + #13;
                blockwrite (msgtfile, s [1], length (s) );
                if msghdr.mto.point >0 then
                  begin
                    s := #1'TOPT ' + cstr(msghdr.mto.point);
                    blockwrite (msgtfile, s [1], length (s) );
                  end;
                if msghdr.from.point > 0 then
                  begin
                    s := #1'FMPT ' + cstr(msghdr.from.point);
                    blockwrite (msgtfile, s [1], length (s) );
                  end;

                s := ^A'MSGID: ' + cstr (msghdr.from.zone) + ':' + cstr (msghdr.from.net) +
                   '/' + cstr (msghdr.from.node) + ' ' + Hex(Random($FFFF), 4) + Hex(Random($FFFF),4);

                if msghdr.from.point > 0 then s := s + '.' + cstr (msghdr.from.point);
                s := s + {' '} #13;  { *** }
                blockwrite (msgtfile, s [1], length (s) );
{$IFDEF MSDOS}
                s := #1'PID: Renemail ' + ver + #13;
{$ENDIF}
{$IFDEF WIN32}
                s := #1'PID: Renemail/32 ' + ver + #13;
{$ENDIF}
{$IFDEF OS2}
                s := #1'PID: Renemail/2 ' + ver + #13;
{$ENDIF}
                blockwrite (msgtfile, s [1], length (s) );
              end;

              j := 0;
              if msghdr.textsize > 0 then
              repeat
                blockread (msgtxtf, s [0], 1);
                blockread (msgtxtf, s [1], ord (s [0]) );
                inc (j, length (s) + 1);
                while pos(#0,s) > 0 do
                  delete(s,pos(#0,s),1);
                if s [length (s) ] = #29 then
                  dec(s[0])
                else
                  if pos (#27, s) = 0 then
                    s := stripcolor(s)
                  else
                    AnsiOn := TRUE;
                s := s + #13;
                blockwrite (msgtfile, s [1], length (s) );
              until (j >= msghdr.textsize);
              close (msgtfile);
              write (#8#8#8#8#8);
           end;
           highestwritten := msgnumber;
       end;
       i := ioresult;
       if not isnetmail then updatehiwater (boardr.msgpath, highestwritten);
       close (msghdrf);
       close (msgtxtf);
       if not scanned then write ('No messages');
    Lasterror := IOResult;
  end;

begin
  Randomize;
  getdir (0, startdir);
  for x := 1 to 37 do
     fcb [x] := ' ';
  fcb [1] := chr (ord (startdir [1]) - 64);
  fcb [2] := '*';
  fcb [10] := 'M';
  fcb [11] := 'S';
  fcb [12] := 'G';
  filemode := 66;
  msghdr.from.zone := 0;
  msghdr.from.point := 0;
  clrscr;
  textcolor (3);
{$IFDEF MSDOS}
  writeln ('Renegade Echomail Interface DOS v.' + ver);
{$ENDIF}
{$IFDEF WIN32}
  writeln ('Renegade Echomail Interface Win32 v.' + ver);
{$ENDIF}
{$IFDEF OS2}
  writeln ('Renegade Echomail Interface nos/2 v.' + ver);
{$ENDIF}
  writeln ('Copyright (C)MM by Jeff Herrings. All Rights Reserved.');
{$IFDEF WIN32}
  writeln ('Ported to Win32 by Rick Parrish');
{$ENDIF}
  writeln;
  textcolor (10);

  if paramstr (1) = '' then
    begin
      writeln (' Commands:  -T  Toss incoming messages');
      writeln ('            -S  Scan outbound messages');
      writeln ('            -P  Purge echomail dirs');
      writeln (' Options:       -A  Absolute scan');
{$IFDEF MSDOS}
      writeln ('                -F  No fast purge');
{$ENDIF}
      writeln ('                -N  No Netmail');
      writeln ('                -D  Do not delete Netmail');
{$IFDEF MSDOS}
      writeln ('                -B  Bios video output');
{$ENDIF}
      writeln ('                -O  Only Netmail');
      writeln ('                -I  Import 1.MSG');
      writeln;
      halt;
    end;
  for i := 1 to paramcount do
      if pos ('-N', allcaps (paramstr (i) ) ) > 0 then
         process_netmail := FALSE
      else
         if pos ('-F', allcaps (paramstr (i) ) ) > 0 then
            fastpurge := FALSE
         else
            if pos ('-D', allcaps (paramstr (i) ) ) > 0 then
               purge_netmail := FALSE
            else
{$IFDEF MSDOS}
              if pos ('-B', allcaps (paramstr (i) ) ) > 0 then
                 directvideo := FALSE
              else
{$ENDIF}
                if pos ('-O', allcaps (paramstr (i) ) ) > 0 then
                   netmailonly := TRUE
                else
                  if pos ('-A', allcaps (paramstr (i) ) ) > 0 then
                     absolute_scan := TRUE
                  else
                    if pos ('-I', allcaps (paramstr (i) ) ) > 0 then
                       ignore_1msg := FALSE;
                       (* 09-16-96 Changed to allow processing of 1.msg
                       *)
  board := 0;
  getpaths;

  if process_netmail then
    begin
       boardr.msgpath := netmailpath;
       boardr.filename := 'EMAIL';
       boardr.mbstat := [mbskludge];
       assign (uf, datapath + 'users.dat');
       reset (uf);
       if ioresult <> 0 then
         aborterror('Cannot find users.dat in your DATA directory');
       assign (sf, datapath + 'users.idx');
       reset (sf);
       if ioresult <> 0 then
         aborterror('Cannot find users.idx in your DATA directory');

       isnetmail := TRUE;
       textcolor (3);
       write ('Processing: ');
       textcolor (14);
       write (' NETMAIL - ');
       textcolor (11);
       if pos ('-T', allcaps (paramstr (1) ) ) > 0 then
          toss;
       if pos ('-S', allcaps (paramstr (1) ) ) > 0 then
          scan;
       close (uf);
       close (sf);
       Lasterror := IOResult;
       writeln;
       isnetmail := FALSE;
    end;

  if netmailonly then halt;

  while board <> 32767 do begin
    nextboard(pos('-S', allcaps(paramstr(1))) > 0);
       if board <> 32767 then begin
       textcolor (3);
       write ('Processing: ');
       textcolor (14);
       write (boardr.filename : 8, ' - ');
       textcolor (11);
       if pos ('-P', allcaps (paramstr (1) ) ) > 0 then purgedir (boardr.msgpath)
          else if pos ('-T', allcaps (paramstr (1) ) ) > 0 then toss
               else if pos ('-S', allcaps (paramstr (1) ) ) > 0 then scan;
        writeln;
    end else close (boardf)
  end;
  chdir (startdir);
end.
