{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S-,V-}

{ Text editor }

unit sysop4;

interface

uses crt, dos, overlay, common;

procedure tedit1;
procedure tedit(const fspec:astr);

implementation

type strptr=^strrec;
     strrec=
       record
         i:astr;
         next,last:strptr;
       end;

var topheap:^byte;
    lastvar:byte;

procedure tedit1;
var espec,s1,s2,s3:astr;
begin
  prt(^M^J'Filename: ');
  if (FileSysOp) then begin
    mpl(50); input(espec,50);
  end else begin
    mpl(12); input(espec,12);
    fsplit(espec,s1,s2,s3); espec:=s2+s3;
  end;
  tedit(espec);
end;

procedure tedit(const fspec:astr);
var fil:text;
    cur,nex,las,top,bottom,used:strptr;
    i1,i2,ps1,ps2,ps3:astr;
    tline,curline,c1:integer;
    done,allread:boolean;

  procedure inli(var i:astr);
  var cp,rp:integer; c,c1:char; cv,cc:integer;

    procedure bkspc;
    begin
      if (cp>1) then begin
        if (i[cp-2] = '^') and (i[cp-1] in ['0'..'9']) then begin
          UserColor(1);
          dec(cp);
        end else
          if i[cp-1]=#8 then begin
            prompt(' ');
            inc(rp);
          end else
            if i[cp-1]<>#10 then begin
              prompt(#8+' '+#8);
              dec(rp);
            end;
        dec(cp);
      end;
    end;

  begin
    rp:=1; cp:=1;
    i:='';
    if (ll<>'') then begin
      prompt(ll);
      i:=ll; ll:='';
      cp:=length(i)+1;
      rp:=cp;
    end;
    repeat
      c := char(getkey);
      case c of
      #32..#255:if (cp<strlen) and (rp<thisuser.linelen) then begin
                  i[cp]:=c; inc(cp); inc(rp);
                  outkey(c);
                end;
             ^H:bkspc;
             ^I:begin
                  cv:=5-(cp mod 5);
                  if (cp+cv<strlen) and (rp+cv<thisuser.linelen) then
                    for cc:=1 to cv do begin
                      prompt(' '); i[cp]:=' ';
                      inc(rp); inc(cp);
                    end;
                end;
             ^P:if (okansi or okavatar) and (cp < strlen - 1) then
                  begin
                    c1 := char(getkey);
                    if c1 in ['0'..'9'] then
                      begin
                        i[cp] := '^';
                        inc(cp);
                        i[cp] := c1;
                        inc(cp);
                        UserColor(ord(i[cp-1]));
                      end;
                  end;
             ^X:begin
                  cp:=1;
                  for cv:=1 to rp-1 do prompt(#8+' '+#8);
                  UserColor(1);
                  rp:=1;
                end;
      end;
    until ((c=^M) or (rp=thisuser.linelen) or (hangup));
    i[0]:=chr(cp-1);
    if c<>^M then begin
      cv:=cp-1;
      while (cv>1) and (i[cv]<>' ') and ((i[cv]<>^H) or (i[cv-1]='^')) do dec(cv);
      if (cv>(rp div 2)) and (cv<>cp-1) then begin
        ll:=copy(i,cv+1,cp-cv); for cc:=cp-2 downto cv do prompt(^H);
        for cc:=cp-2 downto cv do prompt(' ');
        i[0]:=chr(cv-1);
      end;
    end;
    nl;
{    if c=^M then i:=i+chr(1);}
  end;

  function newptr(var x:strptr):boolean;
  begin
    if (used<>nil) then begin
      x:=used;
      used:=used^.next;
      newptr:=TRUE;
    end else begin
      if (maxavail > 2048) then
        begin
          new(x);
          newptr:=TRUE;
        end
      else
        newptr:=FALSE;
    end;
  end;

  procedure oldptr(var x:strptr);
  begin
    x^.next:=used;
    used:=x;
  end;

  procedure pline(cl:integer; var cp:strptr);
  var
    i:astr;
  begin
    if (not abort) then begin
      if (cp=nil) then i:='      ^5' + '[^3' + 'END^5' + ']' else begin
        i:=cstr(cl);
        while length(i)<4 do i:=' '+i;
        i:=i+': '+cp^.i;
      end;
      printacr(i);
    end;
  end;

  procedure pl;
  begin
    abort:=FALSE;
    pline(curline,cur);
  end;

begin
{$IFDEF MSDOS}
  mark(topheap);
{$ENDIF}
{$IFDEF WIN32}
  // REETODO mark() not implemented in VP -- Win32 version will leak memory as a result
{$ENDIF}
  used:=nil; top:=nil; bottom:=nil;
  allread:=TRUE;
  fsplit(fspec,ps1,ps2,ps3);
  if (fspec='') then begin
      print('Illegal filename.');
  end else begin
    nl;
    assign(fil,fspec); abort:=FALSE;
    reset(fil);
    tline:=0;
    new(cur);
    cur^.last:=nil; cur^.i:='';
    if (ioresult<>0) then begin
      rewrite(fil);
      if (ioresult<>0) then begin
        print('error reading file.');
        abort:=TRUE;
      end else begin
        close(fil); erase(fil);
        print('New file.');
        tline:=0;
        cur:=nil; top:=cur; bottom:=cur;
      end;
    end else begin
      abort:=not newptr(nex);
      top:=nex;
      print('^1Loading...');
      while ((not eof(fil)) and (not abort)) do begin
        inc(tline);
        cur^.next:=nex;
        nex^.last:=cur;
        cur:=nex;
        readln(fil,i1);
        cur^.i:=i1;
        abort:=not newptr(nex);
      end;
      close(fil);
      cur^.next:=nil;
      if (tline=0) then begin cur:=nil; top:=nil; end;
      bottom:=cur;
      if (abort) then
        begin
          print(^M^J^G^G'|12WARNING: |10Not all of file read.^3'^M^J);
          allread:=FALSE;
        end;
      abort:=FALSE;
    end;
    if (not abort) then begin
      print('Total lines: '+cstr(tline));
      cur:=top;
      if (top<>nil) then top^.last:=nil;
      curline:=1;
      done:=FALSE;
      pl;
      repeat
        prt(':');
        input(i1,10);
        if (i1='') then i1:='+';
        if (value(i1)>0) then begin
          c1:=value(i1);
          if ((c1>0) and (c1<=tline)) then begin
            while (c1<>curline) do
              if (c1<curline) then begin
                if (cur=nil) then begin
                  cur:=bottom;
                  curline:=tline;
                end else begin
                  dec(curline);
                  cur:=cur^.last;
                end;
              end else begin
                inc(curline);
                cur:=cur^.next;
              end;
            pl;
          end;
        end else
        case i1[1] of
          '?':begin
                lcmds(14,3,'+Forward line','-Back line');
                lcmds(14,3,'Top','Bottom');
                lcmds(14,3,'Print line','List');
                lcmds(14,3,'Insert lines','Delete line');
                lcmds(14,3,'Replace line','Clear all');
                lcmds(14,3,'Quit (abort)','Save');
                lcmds(14,3,'*Center line','');
              end;
          '!':print('Heap space available: '+cstr(memavail));
          '*':if (cur<>nil) then cur^.i:=#2+cur^.i;
          '+':if (cur<>nil) then begin
                c1:=value(copy(i1,2,9));
                if (c1=0) then c1:=1;
                while (cur<>nil) and (c1>0) do begin
                  cur:=cur^.next;
                  inc(curline);
                  dec(c1);
                end;
                pl;
              end;
          '-':begin
                c1:=value(copy(i1,2,9));
                if (c1=0) then c1:=1;
                if (cur=nil) then begin
                  cur:=bottom;
                  curline:=tline;
                  dec(c1);
                end;
                if (cur<>nil) then
                  if (cur^.last<>nil) then begin
                    while ((cur^.last<>nil) and (c1>0)) do begin
                      cur:=cur^.last;
                      dec(curline);
                      dec(c1);
                    end;
                    pl;
                  end;
              end;
          'B':begin
                cur:=nil;
                curline:=tline+1;
                pl;
              end;
          'C':if pynq('Clear workspace? ') then begin
                tline:=0; curline:=1;
                cur:=nil; top:=nil; bottom:=nil;
{$IFDEF MSDOS}
                release(topheap);
{$ENDIF}
{$IFDEF WIN32}
  // REETODO release() not implemented in VP -- Win32 version will leak memory as a result
{$ENDIF}
              end;
          'D':begin
                c1:=value(copy(i1,2,9));
                if (c1=0) then c1:=1;
                while (cur<>nil) and (c1>0) do begin
                  las:=cur^.last;
                  nex:=cur^.next;
                  if (las<>nil) then las^.next:=nex;
                  if (nex<>nil) then nex^.last:=las;
                  oldptr(cur);
                  if (bottom=cur) then bottom:=las;
                  if (top=cur) then top:=nex;
                  cur:=nex;
                  dec(tline); dec(c1);
                end;
                pl;
              end;
          'I':begin
                abort:=FALSE; ll:='';
                print(^M^J'   Enter "." on a separate line to exit insert mode.');
                if (okansi or okavatar) then
                  print('^2   อออออออออออออออออออออออออออออออออออออออออออออออออ^1');
                i1:=''; dec(thisuser.linelen,6);
                while (not hangup) and (not abort) and
                      (i1<>'.') and (i1<>'.'+#1) do begin
                  i2:=cstr(curline);
                  while length(i2)<>4 do i2:=' '+i2;
                  i2:=i2+': '; prompt(i2);
                  inli(i1);
                  if (i1<>'.') and (i1<>'.'+#1) then begin
                    abort:=not newptr(nex);
                    if not abort then begin
                      nex^.i:=i1;
                      if (top=cur) then
                        if (cur=nil) then begin
                          nex^.last:=nil;
                          nex^.next:=nil;
                          top:=nex;
                          bottom:=nex;
                        end else begin
                          nex^.next:=cur;
                          cur^.last:=nex;
                          top:=nex;
                        end
                      else begin
                        if cur=nil then begin
                          bottom^.next:=nex;
                          nex^.last:=bottom;
                          nex^.next:=nil;
                          bottom:=nex;
                        end else begin
                          las:=cur^.last;
                          nex^.last:=las;
                          nex^.next:=cur;
                          cur^.last:=nex;
                          las^.next:=nex;
                        end;
                      end;
                      inc(curline);
                      inc(tline);
                    end else print('Out of space.');
                  end;
                end;
                inc(thisuser.linelen,6);
              end;
          'L':begin
                abort:=FALSE;
                nex:=cur;
                c1:=curline;
                while (not abort) and (nex<>nil) do begin
                  pline(c1,nex);
                  nex:=nex^.next;
                  inc(c1);
                end;
              end;
          'P':pl;
          'R':if (cur<>nil) then begin
                pl;
                i2:=cstr(curline);
                while length(i2)<>4 do i2:=' '+i2;
                i2:=i2+': '; prompt(i2);
                inli(i1);
                cur^.i:=i1;
              end;
          'Q':done:=TRUE;
          'S':begin
                if (not allread) then begin
                  UserColor(5); prompt('Not all of file read.  ');
                  allread:=pynq('Save anyway? ');
                end;
                if allread then begin
                  done:=TRUE; c1:=0;
                  writeln('Saving...');
                  sysoplog('Saved "'+fspec+'"');
                  rewrite(fil);
                  cur:=top;
                  while cur<>nil do begin
                    writeln(fil,cur^.i);
                    cur:=cur^.next;
                    dec(c1);
                  end;
                  if (c1=0) then writeln(fil);
                  close(fil);
                end;
              end;
          'T':begin
                cur:=top;
                curline:=1;
                pl;
              end;
        end;
      until ((done) or (hangup));
    end;
  end;
{$IFDEF MSDOS}
  release(topheap);
{$ENDIF}
{$IFDEF WIN32}
  // REETODO release() not implemented in VP -- Win32 version will leak memory as a result
{$ENDIF}
  printingfile:=FALSE;
  Lasterror := IOResult;
end;

end.
