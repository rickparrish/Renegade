{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit mail1;

interface

uses crt, dos, overlay, common, timefunc, dfFix;

function InputMessage(pub,uti:boolean; const ftit:astr; var mheader:mheaderrec; const ReadInMsg:astr):boolean;
procedure InputLine(var i:astr);
procedure anonymous(offline:boolean; var mheader:mheaderrec);

implementation

uses file8, file0, mail0;

const
   TopScreen = 3;       {first screen line for text entry}
   ScrollSize = 5;      {number of lines to scroll by}
   MsgMaxLen = 78;
var
  ImportFile:text;
  ImportFileOpen:boolean;
  LastLine:astr;
  ScreenLines:byte;
  Escp:boolean;

  procedure anonymous(offline:boolean; var mheader:mheaderrec);
  var
    an:anontyp;
    c:char;
    b:byte;
    s:string[36];
  begin
    if (readboard<>-1) then
      begin
        an:=memboard.anonymous;
        if (an=atno) and (aacs(general.anonpubpost) and (not offline)) then
          an:=atyes;
        if (rpostan in thisuser.flags) then
          an:=atno;
      end
    else
      if (aacs(general.anonprivpost)) then
        an:=atyes
      else
        an:=atno;

    if offline then
      begin
        abort:=FALSE; next:=FALSE;
        if an=atno then
          for b := 1 to 5 do
            begin
              s:=headerline(mheader,filesize(msghdrf),filesize(msghdrf),b);
              if s<>'' then printacr(s);
            end
        else
          begin
            readmsg(filesize(msghdrf),filesize(msghdrf),filesize(msghdrf));
            reset(msghdrf);
            if (IOResult = 2) then
              rewrite(msghdrf);
            reset(msgtxtf);
            if (IOResult = 2) then
              rewrite(msgtxtf);
            if (IOResult <> 0) then
              sysoplog('Anon: error opening message bases.');
          end;
      end;

    case an of
      atno      :;
      atforced  :if (CoSysOp) then
                   mheader.from.anon:=2
                 else
                   mheader.from.anon:=1;
      atyes     :begin
                   nl;
                   if pynq(aonoff(readboard<>-1,'Post anonymously? ',
                           'Send anonymously? ')) then
                     if (CoSysOp) then
                       mheader.from.anon:=2
                     else
                       mheader.from.anon:=1;
                 end;
      atdearabby:begin
                   print(^M^J + aonoff(readboard<>-1,'Post as:','Send as:') + ^M^J);

                   print('1. Abby');
                   print('2. Problemed Person');
                   print('3. '+caps(thisuser.name));

                   prt(^M^J'Which? '); onek(c,'123N'^M);
                   case c of
                     '1':mheader.from.anon:=3;
                     '2':mheader.from.anon:=4;
                   end;
                 end;
      atanyname :begin
                   print(^M^J'You can post under any name in this base.'^M^J);

                   prt('Name: ');
                   inputdefault(s,mheader.from.as,36,'l',TRUE);
                   if (s<>mheader.from.as) then
                     begin
                       mheader.from.anon:=5;
                       mheader.from.as:=caps(s);
                     end;
                 end;
    end;
  end;

function InputMessage(pub,uti:boolean; const ftit:astr; var mheader:mheaderrec;const ReadInMsg:astr):boolean;
type
  LinePointer = ^LineArray;
  LineArray = array[1..200] of string[100];

var LinePtr : LinePointer;
    mftit,fto,s,s1,s2:astr;
    i,j,k,MaxLi,quoteli,lastquoteline,MaxQuoteLines,CurrentLine:integer;
    nodesave:byte;
    LineTotal:1..200;
    c:char;
    cantabort,saveline,exited,save,
    abortit:boolean;
    topline,
    ccol:integer;
    insert_mode:boolean;
    oldtimewarn:boolean;
    phyline:array[1..20] of string[79];

procedure fileattach;
var
  dok,kabort,addbatch:boolean;
  tooktime:longint;
begin
  nl;
  if pynq('Attach a file to this message? ') then
    begin
      prt(^M^J'File name: ');
      input(s,40);
      nl;
      if (not CoSysOp) or (not isul(s)) then
        s:=general.fileattachpath+stripname(s);
      if not exist(s) and not incom and not exist(s) and (s<>'') then
        begin
          print('That file does not exist.');
          exit;
        end;
      if exist(s) and not CoSysOp then
        print('You cannot use that file name.')
      else
        begin
          if not exist(s) and incom then
            begin
              receive(s, tempdir + '\UP', FALSE, dok, kabort, addbatch, tooktime);
              mheader.fileattached := 1;
            end
          else
            if exist(s) then
              begin
                dok := TRUE;
                mheader.fileattached := 2;
              end;
          if dok then
            begin
              mftit:=s;
              if CoSysOp and not (netmail in mheader.status) then
                 if pynq('Delete file upon receipt? ') then
                   mheader.fileattached := 1
                 else
                   mheader.fileattached := 2
              else
                mheader.fileattached := 1;
            end
          else
            mheader.fileattached := 0;
        end;
    end;
end;

procedure ansig(x,y:integer);
begin
  if (Speed > 0) then
    if okavatar then
      SerialOut(^V^H+chr(y)+chr(x))
    else
      SerialOut(#27+'['+cstr(y)+';'+cstr(x)+'H');
  if (wantout) then
    gotoxy(x, y);
end;

procedure dolines;
begin
   if (okansi or okavatar) then
     print('^4ÚÄÄÄ:ÄÄÄÄ:ÄÄÄÄ:ÄÄÄÄ:ÄÄÄÄ:ÄÄÄÄ:ÄÄÄÄ:ÄÄÄÄÂÄÄÄÄ:ÄÄÄÄ:ÄÄÄÄ:ÄÄÄÄ:ÄÄÄÄ:ÄÄÄÄ:ÄÄÄÄ:ÄÄÄ¿^1')
   else
     print('[---:----:----:----:----:----:----:----|----:----:----:----:----:----:----:---]');
end;

procedure count_lines;
begin
     LineTotal := MaxLi;
     while (LineTotal>0) and (length(LinePtr^[LineTotal])=0) do dec(LineTotal);
end;

procedure append_space;
begin
   LinePtr^[CurrentLine]:=LinePtr^[CurrentLine]+' ';
end;

function curlength:byte;
begin
   curlength:=length(LinePtr^[CurrentLine]);
end;

function line_boundry: boolean;
   {is the cursor at either the start of the end of a line?}
begin
   line_boundry:=(ccol=1) or (ccol>curlength);
end;

function curchar:char;
   {return the character under the cursor}
begin
   if ccol<=curlength then
      curchar:=LinePtr^[CurrentLine][ccol]
   else
      curchar:=' ';
end;

function lastchar: char;
   {return the last character on the current line}
begin
   if curlength=0 then
      lastchar:=' '
   else
      lastchar:=LinePtr^[CurrentLine][curlength];
end;

procedure remove_trailing;
begin
   while (length(LinePtr^[CurrentLine])>0) and
         (LinePtr^[CurrentLine][length(LinePtr^[CurrentLine])]<=' ') do
     dec(LinePtr^[CurrentLine][0]);
end;

function delimiter: boolean;
   {return true if the current character is a delimiter for words}
begin
   case curchar of
      '0'..'9','a'..'z','A'..'Z','_':
         delimiter:=false;
      else
         delimiter:=true;
   end;
end;

procedure reposition(x:boolean);
var eol:byte;
begin
   if x then begin
      eol:=curlength+1;
      if ccol>eol then
         ccol:=eol;
   end;
   count_lines;
   ansig(ccol,CurrentLine-topline+TopScreen);
   if pos('>',copy(LinePtr^[CurrentLine],1,4))>0 then
     UserColor(3)
   else
     UserColor(1);
end;

procedure set_phyline;
   {set physical line to match logical line (indicates display update)}
begin
   phyline[CurrentLine-topline+1]:=LinePtr^[CurrentLine];
end;

procedure clear_eol;
begin
   if not okavatar then SerialOut(#27'[K')
      else SerialOut(^V^G);
   if (wantout) then clreol;
end;

procedure truncate_line;
   {update screen after changing end-of-line}
begin
   if ccol>0 then LinePtr^[CurrentLine][0]:=chr(ccol-1);
   reposition(TRUE);
   clear_eol;
   {set_phyline;  don't understand this}
end;

procedure refresh_screen;
var pline, pcol, phline, junk:byte;

begin
   if (CurrentLine >= MaxLi) then CurrentLine:=MaxLi;
   pline:=CurrentLine;
   CurrentLine:=topline;
   pcol:=ccol;
   ccol:=1;

   for junk:=topline to topline+ScreenLines-1 do begin
      CurrentLine:=junk;
      phline:=CurrentLine-topline+1;

      if CurrentLine>MaxLi then begin
         reposition(TRUE);
         prompt('^9--');
         phyline[phline]:='--';
         clear_eol;
      end else begin
         if LinePtr^[CurrentLine] <> phyline[phline] then begin
            reposition(TRUE);
            mciallowed:=FALSE;
            colorallowed:=FALSE;
            allowabort:=FALSE;
            printmain(copy(LinePtr^[CurrentLine],1,79));
            mciallowed:=TRUE;
            colorallowed:=TRUE;
            allowabort:=TRUE;
            if curlength < length(phyline[phline]) then
               clear_eol;
            set_phyline;
         end;
      end;
   end;

   tleft;

   ccol:=pcol;
   CurrentLine:=pline;
   reposition(TRUE);
end;


procedure scroll_screen(lines: integer);
begin
   inc(topline,lines);

   if (CurrentLine<topline) or (CurrentLine>=topline+ScreenLines) then
      topline:=CurrentLine-ScreenLines div 2;

   if topline<1 then
      topline:=1
   else
   if topline>=MaxLi then
      dec(topline,ScrollSize div 2);

   refresh_screen;
end;


procedure cursor_up;
begin
   if CurrentLine>1 then
      dec(CurrentLine);

   if CurrentLine<topline then
      scroll_screen(-ScrollSize)
   else
      reposition(FALSE);
end;


procedure cursor_down;
begin
   inc(CurrentLine);
   if (CurrentLine>=MaxLi) then begin
      CurrentLine:=MaxLi;
      if (ImportFileOpen) then begin
         ImportFileOpen:=FALSE;
         close(ImportFile);
      end;
   end;

   if (CurrentLine-topline>=ScreenLines) then
      scroll_screen(ScrollSize)
   else
      reposition(FALSE);
end;

procedure cursor_endline;
begin
   ccol:=79;
   reposition(TRUE);
end;

procedure cursor_startline;
begin
   ccol:=1;
   reposition(TRUE);
end;

procedure cursor_left;
begin
   if ccol=1 then
   begin
      cursor_up;
      cursor_endline;
   end
   else begin
      dec(ccol);
      if not okavatar then SerialOut(#27'[D')
         else SerialOut(^V^E);
      gotoxy(WhereX - 1, WhereY);
   end;
end;

procedure cursor_right;
begin
   if ccol>curlength then begin
      ccol:=1;
      cursor_down;
   end else begin
      outkey(curchar); { prompt }
      inc(ccol);
   end;
end;

procedure cursor_wordright;
begin
   if delimiter then begin
      {skip blanks right}
      repeat
         cursor_right;
         if line_boundry then exit;
      until not delimiter;
   end
   else begin
      {find next blank right}
      repeat
         cursor_right;
         if line_boundry then exit;
      until delimiter;

      {then move to a word start (recursive)}
      cursor_wordright;
   end;
end;


procedure cursor_wordleft;
begin
   if delimiter then begin
      {skip blanks left}
      repeat
         cursor_left;
         if line_boundry then exit;
      until not delimiter;

      {find next blank left}
      repeat
         cursor_left;
         if line_boundry then exit;
      until delimiter;

      {move to start of the word}
      cursor_right;
   end
   else begin
      {find next blank left}
      repeat
         cursor_left;
         if line_boundry then exit;
      until delimiter;

      {and then move a word left (recursive)}
      cursor_wordleft;
   end;
end;

procedure delete_line;
   {delete the line at the cursor}
var i:byte;
begin
   for i := CurrentLine to MaxLi-1 do
      LinePtr^[i] := LinePtr^[i+1];
   LinePtr^[MaxLi] := '';

   if (CurrentLine <= LineTotal) and (LineTotal > 1) then
      dec(LineTotal);
end;

procedure insert_line(const contents: astr);
   {open a new line at the cursor}
var
   i:byte;
begin
   for i:=MaxLi downto CurrentLine+1 do
      LinePtr^[i]:=LinePtr^[i-1];
   LinePtr^[CurrentLine]:=contents;

   if CurrentLine<LineTotal then
      inc(LineTotal);
   if CurrentLine>LineTotal then
      LineTotal:=CurrentLine;
end;

procedure reformat_paragraph;
begin
   remove_trailing;
   ccol:=curlength;

   {for each line of the paragraph}
   while curchar <> ' ' do
   begin

      {for each word of the current line}
      repeat
         {determine length of first word on the following line}
         inc(CurrentLine);
         remove_trailing;
         ccol := 1;
         while curchar<>' ' do
            inc(ccol);
         dec(CurrentLine);

         {hoist a word from the following line if it will fit}
         if (ccol > 1) and (ccol + curlength < MsgMaxLen) then begin
            if curlength > 0 then begin
               {add a second space after sentences}
               case lastchar of
                  '.','?','!':
                     append_space;
               end;
               append_space;
            end;
            LinePtr^[CurrentLine]:=LinePtr^[CurrentLine]+copy(LinePtr^[CurrentLine+1],1,ccol-1);

            {remove the hoisted word}
            inc(CurrentLine);
            while (curchar = ' ') and (ccol <= curlength) do
               inc(ccol);
            delete(LinePtr^[CurrentLine],1,ccol-1);
            if curlength = 0 then
               delete_line;
            dec(CurrentLine);
         end
         else
            ccol := 0;  {end of line}
      until ccol = 0;

      {no more lines will fit - either time for next line, or end of paragraph}
      inc(CurrentLine);
      ccol := 1;
      remove_trailing;
   end;

end;

procedure word_wrap;
   {line is full and a character must be inserted.  perform word-wrap,
    updating screen and leave ready for the insertion}
var
   pcol,
   pline:byte;

begin
   remove_trailing;
   pline := CurrentLine;
   pcol := ccol;

   {find start of word to wrap}
   ccol:=curlength;


   while (ccol > 0) and (curchar <> ' ') do
      dec(ccol);

   {cancel wrap if no spaces in whole line}
   if ccol=0 then begin
      ccol:=1;
      cursor_down;
      exit;
   end;

   {get the portion to be moved down}
   inc(ccol);
   s := copy(LinePtr^[CurrentLine],ccol,MsgMaxLen);

   {remove it from current line and refresh screen}
   truncate_line;

   {place text on open a new line following the cursor}
   inc(CurrentLine);
   insert_line(s);

   {join the wrapped text with the following lines of text}
   reformat_paragraph;

   {restore cursor to proper position after the wrap}
   CurrentLine := pline;
   if pcol > curlength then begin
      ccol := pcol-curlength{-1};   {position cursor after wrapped word}
      inc(CurrentLine); {cursor_down;}
   end
   else
      ccol := pcol;               {restore original cursor position}

   if (CurrentLine-topline >= ScreenLines) then
      scroll_screen(ScrollSize)
   else
      refresh_screen;
end;

procedure join_lines;
   {join the current line with the following line, if possible}
begin
   inc(CurrentLine);
   remove_trailing;
   dec(CurrentLine);
   remove_trailing;
   if (curlength+length(LinePtr^[CurrentLine+1]))>=MsgMaxLen then exit;

   if (lastchar<>' ') then
      append_space;
   LinePtr^[CurrentLine]:=LinePtr^[CurrentLine]+LinePtr^[CurrentLine+1];

   inc(CurrentLine);
   delete_line;
   dec(CurrentLine);

   refresh_screen;
end;

procedure split_line;
   {splits the current line at the cursor, leaves cursor in original position}
var
   pcol:byte;

begin
   pcol:=ccol;
   remove_trailing;                      {get the portion for the next line}
   s:=copy(LinePtr^[CurrentLine],ccol,MsgMaxLen);

   truncate_line;

   ccol:=1;                             {open a blank line}
   inc(CurrentLine);
   insert_line(s);

   if CurrentLine-topline > ScreenLines-2 then scroll_screen(ScrollSize)
      else refresh_screen;

   dec(CurrentLine);
   ccol := pcol;
end;


procedure cursor_newline;
begin
   if (insert_mode) then split_line;
   ccol := 1;
   cursor_down;
end;

procedure fs_reformat;
   {reformat paragraph, update display}
var
   pline:byte;

begin
   pline:=CurrentLine;
   reformat_paragraph;

   {find start of next paragraph}
   while (curlength = 0) and (CurrentLine <= LineTotal) do
      inc(CurrentLine);

   {find top of screen for redisplay}
   while CurrentLine-topline > ScreenLines-2 do
   begin
      inc(topline,ScrollSize);
      pline := topline;
   end;

   refresh_screen;
end;



procedure insert_char(c: char);
begin

   if ccol < curlength then begin
      remove_trailing;
      if ccol > curlength then
         reposition(TRUE);
   end;

   if (insert_mode and (curlength >= MsgMaxLen)) or (ccol > MsgMaxLen) then begin
      if (ccol <= MsgMaxLen) then word_wrap
      else if c = ' ' then begin
         cursor_newline;
         exit;
      end else
          if lastchar = ' ' then cursor_newline   {nonspace w/space at end-line is newline}
             else word_wrap;                      {otherwise wrap word down and continue}
   end;

   {insert character into the middle of a line}

   if insert_mode and (ccol <= curlength) then begin

      insert(c,LinePtr^[CurrentLine],ccol);

      {update display line following cursor}
      mciallowed:=FALSE;
      colorallowed:=FALSE;
      allowabort:=FALSE;
      printmain(copy(LinePtr^[CurrentLine],ccol,MsgMaxLen));
      mciallowed:=TRUE;
      colorallowed:=TRUE;
      allowabort:=TRUE;

      {position cursor for next insertion}
      inc(ccol);
      reposition(TRUE);
   end else begin {append a character to the end of a line}
      while curlength < ccol do
         append_space;

      LinePtr^[CurrentLine][ccol] := c;

      {advance the cursor, updating the display}
      cursor_right;
   end;

   set_phyline;
end;

procedure delete_char;
begin
   {delete whole line if it is empty}
   if (ccol>curlength) and (curlength>0) then
      join_lines
   else if ccol<=curlength then begin {delete in the middle of a line}
      delete(LinePtr^[CurrentLine],ccol,1);
      mciallowed:=FALSE;
      colorallowed:=FALSE;
      allowabort:=FALSE;
      printmain(copy(LinePtr^[CurrentLine],ccol,MsgMaxLen)+' ');
      mciallowed:=TRUE;
      colorallowed:=TRUE;
      allowabort:=TRUE;
      reposition(TRUE);
      set_phyline;
   end;
end;

procedure delete_wordright;
begin
   if curchar=' ' then
      repeat   {skip blanks right}
         delete_char;
      until (curchar<>' ') or (ccol>curlength)
   else
     begin
       repeat   {find next blank right}
         delete_char;
       until delimiter;
       delete_char;
     end;
end;

procedure page_down;
begin
   if topline+ScreenLines<MaxLi then begin
      inc(CurrentLine,ScrollSize);
      scroll_screen(ScrollSize);
   end;
end;

procedure page_up;
begin
   if topline>1 then begin
      dec(CurrentLine,ScrollSize);
      if CurrentLine<1 then
         CurrentLine:=1;
      scroll_screen(-ScrollSize);
   end else begin
      CurrentLine:=1;
      ccol:=1;
      scroll_screen(0);
   end;
end;

procedure fs_insert_line;
   {open a blank line, update display}
begin
   insert_line('');
   if CurrentLine-topline > ScreenLines-2 then
      scroll_screen(ScrollSize)
   else
      refresh_screen;
end;

procedure fs_delete_line;
   {delete the line at the cursor, update display}
begin
   delete_line;
   refresh_screen;
end;

procedure display_insert_status;
begin
   ansig(69,1);
   prompt('^1(Mode: ');
   if insert_mode then prompt('INS)')
      else prompt('OVR)');
end;

procedure prepare_screen;
var i:byte;
begin
   cls;

   ansig(1,1);
   if (timewarn) then
      prompt(^G^G'          |12Warning: |10You have less than '+cstr(nsl div 60 + 1)+' minute'+
             Plural(nsl div 60 + 1)+' remaining online!')
   else
     begin
       prompt('^1(Ctrl-Z = Help)  ^5To:^1 '+mln(fto,20)+ ' ^5Subj: ^1');

       if (mheader.fileattached = 0) then
         print(mln(mftit,20))
       else
         print(mln(stripname(mftit),20));

       display_insert_status;
     end;

   ansig(1,2);
   dolines;

   for i:=1 to ScreenLines do  {physical lines are now invalid}
      phyline[i]:='';

   scroll_screen(0); {causes redisplay}
end;

procedure redisplay;
begin
   topline:=CurrentLine-ScreenLines div 2;
   prepare_screen;
end;

procedure fs_help;
begin
  cls;
  printf('fshelp');
  pausescr(FALSE);
  prepare_screen;
end;

procedure doquote (ReDrawScreen : boolean);
var fline,nline:word;
    qf:text;
    done:boolean;

   procedure getout(x:boolean);
   begin
     if x then close(qf);
     if invisedit and ReDrawScreen then prepare_screen;
     mciallowed:=TRUE;
   end;

begin
   assign(qf,'TEMPQ'+cstr(node));
   reset(qf);
   if ioresult<>0 then exit;

   if (MaxQuoteLines = 0) then
     begin
       while not eof(qf) do
         begin
           readln(qf,s);
           inc(MaxQuoteLines);
         end;
       close(qf);
       reset(qf);
     end;
   mciallowed:=FALSE;

   done:=FALSE;

   repeat
     abort:=FALSE;
     quoteli:=0;
     cls;

     if lastquoteline>0 then
        while not eof(qf) and (quoteli<lastquoteline) do begin
          readln(qf,s);
          inc(quoteli);
        end;

     if eof(qf) then
      begin
        lastquoteline:=0;
        quoteli:=0;
        reset(qf);
      end;

     while (not eof(qf)) and (quoteli - lastquoteline < pagelength - 4) do
       begin
         readln(qf,s);
         inc(quoteli);
         if (quoteli < 10) then
           s := ' ' + cstr(quoteli) + ':' + s
         else
           s := cstr(quoteli) + ':' + s;
         s:=copy(s,1,79);
         printacr('^3'+s);
       end;

     close(qf);
     reset(qf);

     repeat
       prt(^M^J'First line to quote [?=Help] : ');
       scaninput(s,'HQ?'^M);
       if s='?' then
         print(^M^J'^1<^3Q^1>uit, <^3H^1>eader, <^3?^1>Help, or first line to quote.');
       if (s = 'H') then begin
          while (s<>'') and (not eof(qf)) and (CurrentLine <= MaxLi) do begin
             readln(qf,s);
             if invisedit then
               insert_line(s)
             else
               begin
                 LinePtr^[LineTotal]:=s;
                 inc(LineTotal);
               end;
             inc(CurrentLine);
          end;
          close(qf); reset(qf);
          s:='H';
       end;
     until (hangup) or ((s<>'?') and (s<>'H'));

     fline:=value(s);
     if fline<=0 then lastquoteline:=quoteli;
     if s='Q' then done:=TRUE;
     if (fline>MaxQuoteLines) or (hangup) then begin getout(TRUE); exit; end;

     if (fline>0) then begin
       prt('Last line to quote : ');
       scaninput(s,'Q'^M);

       if s<>#13 then nline:=value(s) else nline:=fline;

       if (nline<fline) or (nline>MaxQuoteLines) then begin getout(TRUE); exit; end;

       nline:=nline-fline+1;

       while (not eof(qf)) and (fline>1) do begin
          dec(fline);
          readln(qf,s);
       end;

       if not invisedit then CurrentLine:=LineTotal;

       while (not eof(qf)) and (nline>0) and (CurrentLine<=MaxLi) do begin
          dec(nline);
          readln(qf,s);
          if invisedit then
            insert_line(s)
          else
            begin
              LinePtr^[LineTotal]:=s;
              inc(LineTotal);
            end;
          inc(CurrentLine);
       end;
       done:=TRUE;
     end;
   until (done) or hangup;
   getout(TRUE);
   Lasterror := IOResult;
end;

procedure fs_editor;

var
  c:word;
begin
   insert_mode:=TRUE;
   invisedit:=TRUE;
   oldtimewarn := timewarn;
   quoteli:=1;
   count_lines;
   if LineTotal>0 then CurrentLine:=LineTotal+1 else CurrentLine:=1;
   ccol:=1;
   topline:=1;
   ScreenLines := pagelength - 4;
   if ScreenLines > 20 then
     ScreenLines := 20;

   while (CurrentLine-topline) > (ScrollSize + 3) do
      inc(topline,ScrollSize);

   prepare_screen;

   repeat
     if ((ImportFileOpen) and (buf='')) then
       if (not eof(ImportFile)) then
         begin
           readln(ImportFile,buf);
           buf:=buf+^M
         end
       else
         begin
           close(ImportFile);
           ImportFileOpen:=FALSE;
         end;

       if (timewarn) and (not oldtimewarn) then
         begin
          ansig(1,1);
          prompt(^G^G'               |12Warning: |10You have  '+cstr(nsl div 60)+' minute(s) remaining online!');
          ansig(ccol,CurrentLine-topline+TopScreen);
          oldtimewarn := TRUE;
         end;

       c := getkey;

       case c of
          47:if (ccol = 1) and (not ImportFileOpen) then
                c := 27
              else
                insert_char(char(c));
         127:delete_char;
     32..254:insert_char(char(c));
           8:begin
                if ccol=1 then begin
                   cursor_left;
                   join_lines;
                 end else begin
                   cursor_left;
                   delete_char;
                 end;
              end;
 F_CTRLLEFT,1:cursor_wordleft;  { ^A }
            2:fs_reformat;      { ^B }
     F_PGDN,3:page_down;        { ^C }
    F_RIGHT,4:cursor_right;     { ^D }
       F_UP,5:cursor_up;        { ^E }
F_CTRLRIGHT,6:cursor_wordright; { ^F }
      F_DEL,7:delete_char;      { ^G }
            9:repeat insert_char(' '); until (ccol mod 5)=0;  { ^I }
           10:join_lines;       { ^J }
     F_END,11:cursor_endline;   { ^K }
           12:redisplay;        { ^L }
           13:cursor_newline;   { ^M }
           14:begin
                split_line;
                reposition(TRUE);
              end;              { ^N }
           16:begin             { ^P }
                c := getkey;
                if (c in [0..9,ord('0')..ord('9')]) then
                  begin
                    insert_char('^');
                    insert_char(char(c));
                  end
                else
                  buf := char(c);
              end;
           17:doquote(TRUE);   { ^Q }
    F_PGUP,18:page_up;         { ^R }
    F_LEFT,19:cursor_left;     { ^S }
           20:delete_wordright;{ ^T }

     F_INS,22:begin            { ^V }
                insert_mode:=not insert_mode;
                display_insert_status;
                reposition(TRUE);
              end;

    F_HOME,23:cursor_startline; { ^W }
    F_DOWN,24:cursor_down;      { ^X }
           25:fs_delete_line;   { ^Y }
           26:fs_help;          { ^Z }
       end;
   until ((c = 27) and not (ImportFileOpen)) or hangup;

   if ImportFileOpen then
     begin
       close(ImportFile);
       ImportFileOpen := FALSE;
     end;
   count_lines;
   invisedit:=FALSE;
end;

  procedure listit(stline:integer; linenum,disptotal:boolean);
  var lasts:astr;
      l:integer;
  begin
    mciallowed:=FALSE;
    if (disptotal) then nl;
    l:=stline;
    abort:=FALSE;
    next:=FALSE;
    dosansion:=FALSE;
    lasts:='';

    while ((l<LineTotal) and (not abort)) do begin
      if (linenum) then print(cstr(l)+':');
      {if ((pos(^[,LinePtr^[l])=0) and (pos(^[,lasts)=0)) then dosansion:=FALSE;}

      reading_a_msg:=TRUE;
      if not dosansion then
        if pos('>',copy(s,1,4))>0 then
          UserColor(3)
        else
          UserColor(1);
      printacr(LinePtr^[l]);
      reading_a_msg:=FALSE;

      lasts:=LinePtr^[l];
      inc(l);
    end;

    dosansion:=FALSE;
    if (disptotal) then
      print('  ^7** ^3'+cstr(LineTotal-1)+' lines ^7**');
    saveline:=FALSE;
    UserColor(1);
    mciallowed:=TRUE;
  end;

  procedure AddressMessage;
  var u:userrec;
      s1:string[50];
      i:integer;
  begin

    print(fstring.default + ^M^J);

    if pub and not (mbinternet in memboard.mbstat) then begin
      prt('To: ');
      if fto<>'' then
        inputdefault(s,fto,50,'lp',FALSE)
       else
         begin
           mpl(50);
           inputmain(s,50,'lp');
         end;

      UserColor(6);
      fto:=s;
      for i:=1 to lennmci(fto) do
        backspace;

      i:=value(fto);

      if (i>0) and (i<=maxusers-1) and not (netmail in mheader.status) then
        begin
          loadurec(u,i);
          fto:=caps(u.name);
          mheader.mto.usernum:=i;
          mheader.mto.real:=u.realname;
          if (pub) and (mbrealname in memboard.mbstat) then
            fto:=caps(u.realname)
          else
            fto:=caps(u.name);
        end;

      if (sqoutsp(fto)='') then
         fto:='All';

      if (fto <> '') then
        begin
          prompt(fto);
          UserColor(1);
          nl;
        end;

      nl;

    end else
      if not (mbinternet in memboard.mbstat) then
        print(mln('^4To: ^6'+caps(fto),49) + ^M^J);

    if (mheader.fileattached = 0) and (not cantabort) then
      begin
        prt('Subject: ');

        if (mftit<>'') then
          inputdefault(s,mftit,40,'L',FALSE)
        else
          begin
            mpl(40);
            inputmain(s,40,'l');
            nl;
          end;
        if s<>'' then
          begin
            UserColor(1);
            nl;
            mftit:=s;
          end
        else
          begin
            if mftit<>'' then
              print('^6'+mftit+'^1')
            else
              exit;
        end;
      end
    else
      mftit := mheader.subject;
  end;


  procedure Replace;
  begin
    if (LineTotal<=1) then print('^7Nothing to replace!') else begin
      print('^5Replace string -'^M^J);

      prt('On which line (1-'+cstr(LineTotal-1)+') ? ');
      input(s,4);
      if (value(s)<1) or (value(s)>LineTotal-1) then
        print('^7Invalid line number.')
      else begin
        print(^M^J'^3Original line:');
        abort:=FALSE; next:=FALSE;
        mciallowed:=FALSE;
        printacr(LinePtr^[value(s)]);
        mciallowed:=TRUE;
        print(^M^J'^4Enter string to replace:');
        prt(':');
        inputl(s1,78);
        if (s1<>'') then
          if (pos(s1,LinePtr^[value(s)])=0) then
            print('^7String not found.')
          else begin
            print('^4Enter replacement string:');
            prt(':');
            inputl(s2,78);
            if (s2<>'') then begin
              if pos(s1,LinePtr^[value(s)])>0 then begin
                 insert(s2,LinePtr^[value(s)],(pos(s1,LinePtr^[value(s)])+length(s1)));
                 delete(LinePtr^[value(s)],pos(s1,LinePtr^[value(s)]),length(s1));
              end;
              print(^M^J'^3Edited line:');
              abort:=FALSE;
              next:=FALSE;
              mciallowed:=FALSE;
              printacr(LinePtr^[value(s)]);
              mciallowed:=TRUE;
            end;
          end;
        end;
        nl;
    end;
  end;

  procedure printmsgtitle;
  begin
    print(fstring.entermsg1);
    print(fstring.entermsg2);
    dolines;
  end;

  procedure inputthemessage;
  var
    t1:integer;

    procedure uploadfile;
    var
      dok,kabort,addbatch:boolean;
      tooktime:longint;
    begin
      nl;
      s:='';
      if CoSysOp then begin
        prt('Enter file to import [Enter=Upload]: ');
        mpl(40);
        inputl(s,40);
      end;
      if s='' then begin
         s:='TEMPMSG.'+cstr(node);
         if exist(s) then
           kill(s);
      end;
      if (not exist(s)) and (incom) then
        begin
          receive(s,tempdir + 'UP\', FALSE,dok,kabort,addbatch,tooktime);
          s := tempdir + 'UP\' + s;
        end;
      UserColor(1);
      if ((s<>'') and (not hangup)) then begin
         assign(ImportFile, s);
         reset(ImportFile);
         if ioresult=0 then
           ImportFileOpen:=TRUE;
      end;
    end;

  begin
    fillchar(LinePtr^[1], 121 * MaxLi, 0);
    abort:=FALSE;
    next:=FALSE;
    quoteli:=1;
(*    if (diskfree(ExtractDriveNumber(general.msgpath) div 1024)<general.minspaceforpost) then*)
    if (diskKBfree(ExtractDriveNumber(general.msgpath))<general.minspaceforpost) then
      begin
        mftit:='';
        print(^M^J'Not enough disk space to save a message.');
        c:=chr(ExtractDriveNumber(general.msgpath)+64);
        if (c='@') then
          sysoplog('^8--->^3 Message save failure: Drive full.')
        else
          sysoplog('^8--->^3 Message save failure: '+c+' Drive full.');
      end
    else
      begin
        LineTotal:=1;
        LastLine:='';
        if (ReadInMsg <> '') then
          begin
            assign(ImportFile,ReadInMsg);
            reset(ImportFile);
            if (IOResult = 0) then
              begin
                while (not eof(ImportFile)) and (LineTotal <= MaxLi) do
                  begin
                    readln(ImportFile, LinePtr^[LineTotal]);
                    inc(LineTotal);
                  end;
                close(ImportFile);
              end;
          end
        else
          AddressMessage;
      end;

    if (mftit='') then
      if (not cantabort) then begin
        save:=FALSE;
        exit;
      end;

    if (fseditor in thisuser.sflags) then begin
       repeat
         fs_editor;
         repeat
           {***ansig(1,x);}
           prt(^M^J'Command (^5?^4=^5Help^4) : ');
           onekcr:=TRUE;
           onek(c,'SARITC?UQ');
           case c of
              '?':begin
                    nl;
                    lcmds(16,3,'Abort message','Continue message');
                    lcmds(16,3,'Title change','Include file');
                    lcmds(16,3,'Restart message','Save message');
                    lcmds(16,3,'Quote message','Upload message');
                  end;
              'T':begin
                    nl;
                    AddressMessage;
                    print('^0Continue message...');
                  end;
              'I':if aacs(general.fileattachacs) then
                     fileattach;
              'Q':begin invisedit:=TRUE; doquote(FALSE); invisedit:=FALSE; end;
              'U':uploadfile;
              'R':if pynq('Are you sure? ') then
                    for t1:=1 to LineTotal do LinePtr^[t1][0]:=#0;
          'A','S':if cantabort and ((LineTotal = 0) or (c = 'A')) then
                    begin
                      c := #0;
                      print(^M^J'You cannot abort this message.');
                    end
                  else
                    if (c='A') and pynq('Are you sure? ') then
                      begin
                        save := FALSE;
                        abortit := TRUE;
                        exit;
                      end
                    else
                      if (c = 'A') then
                        c := #0;
           end;
         until (pos(c,'USACRQ')>0) or (hangup);
       until (hangup) or (pos(c,'SA')>0);
       nl;
       inc(LineTotal);
       if (LineTotal>1) and (not hangup) then save:=TRUE
         else begin
           abortit:=TRUE;
         end;
       exit;
    end;
    printmsgtitle;
    repeat
      repeat
        saveline:=TRUE;
        exited:=FALSE;
        save:=FALSE;
        abortit:=FALSE;
        write_msg:=TRUE;
        InputLine(s);
        write_msg:=FALSE;
        if (s='/'^H) then begin
          saveline:=FALSE;
          if (LineTotal<>1) then begin
            dec(LineTotal);
            LastLine:=LinePtr^[LineTotal];
            if LastLine[length(LastLine)] = #1 then
              LastLine:=copy(LastLine,1,length(LastLine)-1);
            print('^0Backed up to line '+cstr(LineTotal)+':^1');
          end;
        end;
        if (s='/') and not (ImportFileOpen) then begin
          prompt('^3Command (^0?^3=^0help^3) : ^3');
          c := char(getkey);
          BackErase(19);
          saveline:=FALSE;
          case upcase(c) of
            'U':uploadfile;
            '?','H':printf('prhelp');
            'A':if (not cantabort) then
                  if pynq(^M^J'^7Abort message? ') then begin
                    exited:=TRUE;
                    abortit:=TRUE;
                  end else
                    print('^0Nothing done.'^M^J);
            'C':if pynq(^M^J'^7Clear message? ') then begin
                  print('^0Message cleared.... Start over...');
                  LineTotal:=1;
                  escp:=FALSE;
                end else
                  print('^0Nothing done.'^M^J);
            'E':exited:=TRUE;
            'I':if aacs(general.fileattachacs) then
                  fileattach;
            'L':listit(1,pynq(^M^J'^7List message with line numbers? '),TRUE);
            'O':printf('color');
            'P':Replace;
            'Q':if (not exist('TEMPQ'+cstr(node))) then
                  print('^0You are not replying to a message.'^M^J)
                else
                  begin
                    doquote(FALSE);
                    cls;
                    print('^0Quoting complete.  Continue:');
                    printmsgtitle;
                    if (LineTotal>1) then
                      if (LineTotal>10) then listit(LineTotal-10,FALSE,FALSE)
                        else listit(1,FALSE,FALSE);
                  end;
            'R':if (LineTotal>1) then begin
                  print('^0Last line deleted.  Continue:^1');
                  dec(LineTotal);
                end;
            'S':begin
                if ((not cantabort) or (LineTotal > 1)) then
                  begin
                    while ((LineTotal > 1) and ((LinePtr^[LineTotal - 1] = '') or (LinePtr^[LineTotal - 1] = ^J))) do
                      dec(LineTotal);
                    if (LineTotal > 1) then
                      Save := TRUE
                    else
                      if (not cantabort) then
                        abortit := TRUE
                      else
                        print(^M^J'You cannot abort this message.');
                    exited := (Save or Abortit);
                  end;
                end;
            'T':AddressMessage;
          end;
        end;


        if (saveline) then begin
          LinePtr^[LineTotal]:=s;
          inc(LineTotal);
          if (LineTotal>MaxLi) then begin
            print('You have used up your maximum amount of lines.');
            if (ImportFileOpen) then begin
              ImportFileOpen:=FALSE;
              close(ImportFile);
            end;
            exited:=TRUE;
          end;
        end;
      until ((exited) or (hangup));
      if (hangup) then abortit:=TRUE;
      if ((not abortit) and (not save)) then
        repeat
          prt('^3Message editor (^0?^3=^0help^3) : ');
          onek(c,'SACDILRTU?'); nl;
          case c of
            '?':begin
                  lcmds(15,3,'List message','Continue message');
                  lcmds(15,3,'Save message','Abort message');
                  lcmds(15,3,'Delete line','Insert line');
                  lcmds(15,3,'Replace line','Update line');
                  lcmds(15,3,'Title re-do','');
                end;
            'A':if (not cantabort) then
                  if pynq('Abort message? ') then abortit:=TRUE
                    else c:=' ';
            'C':if (LineTotal>MaxLi) then begin
                  print('^7Too many lines!');
                  c:=' ';
                end else
                  prompt('^0Continue...');
            'D':begin
                  prt('Delete which line (1-'+cstr(LineTotal-1)+') ? ');
                  input(s,4);
                  i:=value(s);
                  if (i>0) and (i<LineTotal) then begin
                    for t1:=i to LineTotal-2 do
                      LinePtr^[t1]:=LinePtr^[t1+1];
                    dec(LineTotal);
                  end;
                end;
            'I':if (LineTotal<MaxLi) then begin
                  prt('Insert before which line (1-'+cstr(LineTotal-1)+') ? ');
                  input(s,4);
                  i:=value(s);
                  if (i>0) and (i<LineTotal) then begin
                    for t1:=LineTotal downto i+1 do LinePtr^[t1]:=LinePtr^[t1-1];
                    inc(LineTotal);
                    print('^3New line:');
                    InputLine(s1);
                    LinePtr^[i]:=s1;
                  end;
                end else
                  print('^7Too many lines!');
            'L':listit(1,pynq('With line numbers? '),TRUE);
            'R':begin
                  prt('Line number to replace (1-'+cstr(LineTotal-1)+') ? ');
                  input(s,4);
                  i:=value(s);
                  if ((i>0) and (i<LineTotal)) then begin
                    abort:=FALSE;
                    print(^M^J'^3Old line:');
                    mciallowed:=FALSE;
                    printacr(LinePtr^[i]);
                    mciallowed:=TRUE;
                    print('^3Enter new line:');
                    InputLine(s);
                    if (LinePtr^[i][length(LinePtr^[i])]=#1) and
                       (s[length(s)]<>#1) then LinePtr^[i]:=s+#1 else LinePtr^[i]:=s;
                  end;
                end;
            'S':begin
                if ((not cantabort) or (LineTotal > 1)) then
                  begin
                    while ((LineTotal>1) and ((LinePtr^[LineTotal-1]='') or (LinePtr^[LineTotal-1]=^J))) do
                      dec(LineTotal);
                    if LineTotal>1 then save:=TRUE
                      else abortit:=TRUE;
                  end;
                end;
            'T':AddressMessage;
            'U':Replace;
          end;
          nl;
        until (c in ['A','C','S']) or (hangup);
    until ((abortit) or (save) or (hangup));
    if (LineTotal=1) then begin
      abortit:=TRUE;
      save:=FALSE;
    end;
  end;

  procedure saveit;
  var i,j:integer;
      c:char;
      s:astr;

  begin
    Lasterror := IOResult;
    Lasterror := 0;
    reset(msgtxtf,1);
    if (IOResult = 2) then
      rewrite(msgtxtf,1);
    mheader.textsize:=0;
    mheader.pointer:=filesize(msgtxtf)+1;
    seek(msgtxtf,filesize(msgtxtf));
    if (netmail in mheader.status) and (pos('@', mheader.mto.as) > 0) then
      begin
        for i := 1 to length(mheader.mto.as) do
          if (mheader.mto.as[i] in ['A'..'Z']) then
            inc(mheader.mto.as[i], 32);
        s := 'To: ' + fto;
        blockwrite(msgtxtf, s, length(s) + 1);
        inc(mheader.textsize, length(s) + 1);
        mheader.mto.as := 'UUCP';
      end;
    with memboard do begin
      if ((pub) and (mbfilter in mbstat)) then begin
        for i:=1 to LineTotal-1 do
          if length(LinePtr^[i])>0 then begin
            LinePtr^[i]:=stripcolor(LinePtr^[i]);
            for j:=1 to length(LinePtr^[i]) do begin
              c:=LinePtr^[i][j];
              if (c in [#0..#1,#3..#31,#127..#255]) then c:='*';
              LinePtr^[i][j]:=c;
            end;
          end;
      end;
      for i:=1 to LineTotal-1 do begin
        s:=LinePtr^[i];
        inc(mheader.textsize,length(s)+1);
        blockwrite(msgtxtf,s,length(s) + 1);
      end;
      if (mbtype in [1,2]) and (mbaddtear in mbstat) then begin
        s := '';
        inc(mheader.textsize,length(s) + 1);
        blockwrite(msgtxtf,s,1);
        s:=decode(';h•µlÚ?¦kÐðf', 183)+ver;
        inc(mheader.textsize,length(s)+1);
        blockwrite(msgtxtf,s,length(s)+1);
        s:=' * Origin: ';
        if (memboard.origin<>'') then
          s := s + memboard.origin
        else
          s := s + general.origin;
        s := s + ' (';
        if (aka > 19) then aka := 0;
        s := s + cstr(general.aka[aka].zone) + ':' +
                 cstr(general.aka[aka].net)  + '/' +
                 cstr(general.aka[aka].node);
        if (General.aka[aka].point > 0) then
          s := s + '.' + cstr(General.aka[aka].point);
        s := s + ')';
        inc(mheader.textsize,length(s) + 1);
        blockwrite(msgtxtf,s,length(s) + 1);
      end;
    end;
    close(msgtxtf);
    Lasterror := IOResult;
    if (Lasterror <> 0) then
      sysoplog('error saving message.');
  end;


begin
  MaxLi := (MaxAvail div 120) - 20;  { save 2400 bytes }
  if (MaxLi > 200) then
    MaxLi := 200;
  GetMem (LinePtr, MaxLi * 120);
  MaxQuoteLines := 0;
  loadnode(node);
  nodesave:=noder.activity;
  update_node(4);
  InputMessage:=FALSE;
  ImportFileOpen:=FALSE;
  Escp := FALSE;
  lastquoteline:=0;
  cls;
  if (uti) then
    begin
      if (mbrealname in memboard.mbstat) then
        fto:=caps(mheader.mto.real)
      else
        fto:=caps(mheader.mto.as)
    end
  else
    fto:='';
  if (irt <> '') then
    mftit := irt
  else
    mftit := ftit;

  if (copy(mftit,1,1) = '\') then
    begin
      mftit:=copy(mftit,2,length(mftit)-1);
      mheader.subject := mftit;
      cantabort:=TRUE;
    end
  else
    cantabort:=FALSE;

  if mftit[1]=#1 then
    begin
      mftit:=copy(mftit,2,length(mftit)-1);
      if mheader.subject[1] = #1 then
        mheader.subject:=copy(mheader.subject,2,length(mheader.subject)-1);
    end
  else
    if (mftit<>'') and (copy(mftit,1,3)<>'Re:') then
      mftit:='Re: '+copy(mftit,1,64);

  mheader.fileattached := 0;

  inputthemessage;

  if (ReadInMsg <> '') and (save) then
    begin
      assign(ImportFile, ReadInMsg);   { Just incase Importfile was used }
      rewrite(ImportFile);
      if (IOResult = 0) then
        begin
          for i := 1 to LineTotal - 1 do
            writeln(ImportFile, LinePtr^[i]);
          close(ImportFile);
        end;
      InputMessage := TRUE;
      FreeMem(LinePtr,Maxli * 120);
      update_node(nodesave);
      exit;
    end;

  dosansion:=FALSE;
  kill('TEMPQ'+cstr(node));

  if (not save) or (hangup) then
    begin
      print('Aborted.');
      update_node(nodesave);
    end
  else
    begin
      with mheader do begin
        subject:=mftit;
        origindate:='';
        from.anon:=0;
        mto.anon:=0;
        replies:=0;
        replyto:=0;
        date := getpackdatetime;
        getdayofweek(dayofweek);
        if (pub and (memboard.mbtype in [1, 2])) or (not pub and (netmail in mheader.status)) then
          begin
            newechomail:=TRUE;
            if not (mbscanout in memboard.mbstat) then
              UpdateBoard;
          end;
        with from do begin
          usernum:=common.usernum;
          s:=allcaps(thisuser.name);
          if (not pub) and (netmail in mheader.status) and (thisuser.name<>allcaps(thisuser.realname)) then
            begin
              dyny:=TRUE;
              if (general.allowalias) and pynq('Send this with your real name? ') then
                s:=allcaps(thisuser.realname);
            end;
          as:=s;
          real:=allcaps(thisuser.realname);
          name:=allcaps(thisuser.name);
        end;
        status:=[] + (status * [netmail]);
        if (pub) and (rvalidate in thisuser.flags) then
            status:=status+[unvalidated];
        if (aacs(memboard.mciacs)) then
          status:=status+[allowmci];
        if pub then
           with mto do
             begin
               name:=fto;
               real:=fto;
               as:=fto;
             end;
        if not (netmail in mheader.status) then
          anonymous(FALSE, mheader);
      end;

      prompt(^M^J'^7Saving...');

      saveit;

      update_node(nodesave);

      UserColor(5);
      BackErase(9);
      InputMessage := TRUE;
    end;

    FreeMem(LinePtr,Maxli * 120);
end;

procedure inputline(var i:astr);
var s:astr;
    cp,rp,cv,cc,j:integer;
    c,c1,ccc:char;
    hitcmdkey,hitbkspc,dothischar:boolean;

  procedure bkspc;
  begin
    if (cp>1) then begin
      if (i[cp-2]='^') and (i[cp-1] in [#0..#9]) then
        begin
          dec(cp);
          UserColor(1);
        end
      else
        begin
          backspace;
          dec(rp);
        end;
      dec(cp);
    end;
  end;

begin
  write_msg:=TRUE;
  hitcmdkey:=FALSE;
  hitbkspc:=FALSE;
  ccc:='1';
  rp:=1; cp:=1;
  i:='';
  if (LastLine<>'') then begin
    abort:=FALSE; next:=FALSE;
    allowabort := FALSE;
    reading_a_msg:=TRUE;
    printmain(LastLine);
    reading_a_msg:=FALSE;
    allowabort := TRUE;
    i:=LastLine; LastLine:='';
    if (pos(^[,i) > 0) then
      escp := TRUE;
    cp:=length(i)+1;
    rp:=cp;
  end;
  repeat
    if ((ImportFileOpen) and (buf='')) then
      if (not eof(ImportFile)) then begin
        j := 0;
        repeat
          inc(j);
          read(Importfile, buf[j]);
          if (buf[j] = ^J) then
            dec(j);
        until (j >= 255) or (buf[j] = ^M) or (eof(ImportFile));
        buf[0] := chr(j);
        {if (buf[j] <> ^M) then buf:=buf+^M;}
      end else begin
        close(ImportFile);
        ImportFileOpen:=FALSE;
        dosansion:=FALSE;
        buf:=^P+'1';
      end;
    c := char(getkey);

    dothischar:=FALSE;

      if ((c>=#32) and (c<=#255)) then begin
        if (c='/') and (cp=1) then hitcmdkey:=TRUE else dothischar:=TRUE;
      end else
        case c of
          ^[:dothischar:=TRUE;
          ^H:if (cp=1) then begin
               hitcmdkey:=TRUE;
               hitbkspc:=TRUE;
             end else
               bkspc;
          ^I:begin
               cv:=5-(cp mod 5);
               if (cp+cv<strlen) and (rp+cv<thisuser.linelen) then
                 for cc:=1 to cv do begin
                   outkey(' '); if (trapping) then write(trapfile,' ');
                   i[cp]:=' ';
                   inc(rp); inc(cp);
                 end;
             end;
          ^J:begin
               outkey(c); i[cp]:=c;
               if (trapping) then write(trapfile,^J);
               inc(cp);
             end;
          ^N:begin
               outkey(^H); i[cp]:=^H;
               if (trapping) then write(trapfile,^H);
               inc(cp); dec(rp);
             end;
          ^P:if (okansi or okavatar) and (cp<strlen-1) then begin
               c1 := char(getkey);
               if (c1 in ['0'..'9']) then begin
                 ccc:=c1; i[cp]:='^';
                 inc(cp); i[cp]:=c1;
                 inc(cp); UserColor(ord(c1) - ord('0'));
               end;
             end;
          ^W:if (cp=1) then begin
               hitcmdkey:=TRUE;
               hitbkspc:=TRUE;
             end else
               repeat bkspc until (cp=1) or (i[cp]=' ') or
                                  ((i[cp]=^H) and (i[cp-1]<>'^'));
          ^X,^Y:begin
               cp:=1;
               for cv:=1 to rp-1 do backspace;
               rp:=1;
               if (ccc<>'1') then begin
                 c1:=ccc; i[cp]:='^';
                 inc(cp); i[cp]:=c1;
                 inc(cp); UserColor(ord(c1) - ord('0'));
               end;
             end;
        end;

    if (dothischar) and ((c<>^G) and (c<>^M)) then
      if ((cp<strlen) and (escp)) or
         ((rp<thisuser.linelen{-5}) and (not escp)) then begin
        if (c=^[) then escp:=TRUE;
        i[cp]:=c; inc(cp); inc(rp);
        outkey(c);
        if (trapping) then write(trapfile,c);
      end;
  until ((rp = 78) and (not escp)) or (cp = strlen) or
        (c = ^M) or (hitcmdkey) or (hangup);

  if (hitcmdkey) then begin
    if (hitbkspc) then i:='/'^H else i:='/';
  end else begin
    i[0]:=chr(cp-1);
    if (c<>^M) and (cp<>strlen) and (not escp) then begin
      cv:=cp-1;
      while (cv>1) and (i[cv]<>' ') and ((i[cv]<>^H) or (i[cv-1]='^')) do dec(cv);
      if (cv>rp div 2) and (cv<>cp-1) then begin
        LastLine:=copy(i,cv+1,cp-cv);
        for cc:=cp-2 downto cv do backspace;
        i[0]:=chr(cv-1);
      end;
    end;

    if (escp) and (rp=thisuser.linelen) then cp:=strlen;

    if (cp<>strlen) then
      nl
    else begin
      rp:=1; cp:=1;
      i:=i+#29;
    end;
  end;

  write_msg:=FALSE;
end;

end.
