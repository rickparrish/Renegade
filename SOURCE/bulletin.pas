{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Bulletin related functions }

unit Bulletin;

interface

uses crt, dos, overlay, common;

function newfiles(const spec:astr; var whichones:astr):boolean;
procedure bulletins(par:astr);
procedure ulist(x:astr);
procedure todayscallers(x:byte; cms:astr);

implementation

uses timefunc;

type
  LastCallerPtrType = ^LastCallerRec;
  UserPtrType = ^UserRec;

procedure bulletins(par:astr);
var
  main,subs,s:astr;
  i:integer;
begin
  nl;
  if (par='') then
    if (general.bulletprefix='') then
      par:='bulletin;bullet'
    else
      par:='bulletin;'+general.bulletprefix;
  if (pos(';',par)<>0) then begin
    main:=copy(par,1,pos(';',par)-1);
    subs:=copy(par,pos(';',par)+1,length(par)-pos(';',par));
  end else begin
    main:=par;
    subs:=par;
  end;
  printf(main);
  if (not nofile) then
    repeat
      i:=8-length(subs); if (i<1) then i:=1;
      nl;
      prt(fstring.bulletinline);
      scaninput(s,'ABCDEFGHIJKLMNOPQRSTUVWXYZ?');
      if (not hangup) then begin
        if (s='?') then printf(main);
        if (s <> '') and not (s[1] in ['Q','?']) then
          printf(subs+s);
      end;
    until (s='Q') or (hangup);
end;

function newfiles(const spec:astr; var whichones:astr):boolean;
var
  dt:datetime;
  Found:boolean;
begin
  findfirst(spec,anyfile,dirinfo);
  whichones := '';
  Found := FALSE;
  while (doserror = 0) do
    begin
      unpacktime(dirinfo.time, dt);
      if (date2pd(Zeropad(cstr(dt.month)) + '/' + Zeropad(cstr(dt.day)) + '/' + Zeropad(cstr(Dt.Year - 1900))) >
         thisuser.laston) then
           begin
             Found := TRUE;
             if (pos(general.bulletprefix, spec) > 0) and (pos('BULLETIN',allcaps(dirinfo.name)) = 0) then
               begin
                 if (WhichOnes <> '') then
                   WhichOnes := WhichOnes + ', ';
                 if (length(WhichOnes) > 65) then
                   WhichOnes := WhichOnes + ^M^J;
                 WhichOnes := WhichOnes +
                   copy(dirinfo.name, length(general.bulletprefix) + 1,
                     pos('.',dirinfo.name) - length(general.bulletprefix) - 1);
               end;
           end;
      findnext(dirinfo);
    end;
    NewFiles := Found;
end;

function UlistMCI(const s:astr; Data1, Data2:Pointer):string;
var
  UserPtr:UserPtrType;
begin
  UlistMCI := s;
  UserPtr := Data1;
  case s[1] of
    'A':if (s[2] = 'G') then
          UListMCI := cstr(ageuser(UserPtr^.BirthDate));
    'D':case s[2] of
          'K':UListMCI := cstr(UserPtr^.DK);
          'L':UListMCI := cstr(UserPtr^.Downloads);
        end;
    'L':case s[2] of
          'C':UListMCI := UserPtr^.CityState;
          'O':UListMCI := todate8(pd2date(UserPtr^.LastOn));
        end;
    'M':if (s[2] = 'P') then
          UListMCI := cstr(UserPtr^.MsgPost);
    'N':if (s[2] = 'O') then
          UListMCI := Userptr^.Note;
    'R':if (s[2] = 'N') then
          UListMCI := UserPtr^.RealName;
    'S':if (s[2] = 'X') then
          UListMCI := UserPtr^.Sex;
    'U':case s[2] of
          'K':UListMCI := cstr(UserPtr^.UK);
          'L':UListMCI := cstr(UserPtr^.Uploads);
          'N':UListMCI := caps(UserPtr^.Name);
          '1':UListMCI := UserPtr^.UsrDefStr[1];
          '2':UListMCI := UserPtr^.UsrDefStr[2];
          '3':UListMCI := UserPtr^.UsrDefStr[3];
        end;
  end;
end;

procedure ulist(x:astr);
var
  u:userrec;
  i,q:integer;
  s:astr;
  Junk:Pointer;
begin
  if (ruserlist in thisuser.flags) then begin
    print('You are restricted from listing users.');
    exit;
  end;
  AllowContinue := TRUE;
  if (pos(';',x) > 0) then
    begin
      s := copy(x,pos(';',x) + 1, 255);
      x := copy(x,1,pos(';',x) - 1);
    end
  else
    s := 'user';

  if (not ReadBuffer(s + 'm')) then
    exit;

  printf(s + 'h');

  i:=1;  { skip first }
  reset(uf);
  q:=filesize(uf);
  while (not abort) and (i < q) do begin
    loadurec(u, i);
    inc(i);
    if (aacs1(u, i, x)) and not (deleted in u.sflags) then
      DisplayBuffer(UlistMCI, @u, Junk);
  end;
  close(uf);
  if (not Abort) then
    printf(s + 't');
  AllowContinue := FALSE;
  Lasterror := IOResult;
end;

function TodaysCallerMCI(const s:astr; Data1, Data2:Pointer):string;
var
  LastCallerPtr:LastCallerPtrType;
  s1:string[100];
begin
  LastCallerPtr := Data1;
  TodaysCallerMCI := s;
  case s[1] of
    'C':if (s[2] = 'A') then
          TodaysCallerMCI := FormatNumber(LastCallerPtr^.Caller);
    'D':case s[2] of
          'K':TodaysCallerMCI := cstr(LastCallerPtr^.DK);
          'L':TodaysCallerMCI := cstr(LastCallerPtr^.Downloads);
        end;
    'E':if (s[2] = 'S') then
          TodaysCallerMCI := cstr(LastCallerPtr^.EmailSent);
    'F':if (s[2] = 'S') then
          TodaysCallerMCI := cstr(LastCallerPtr^.FeedbackSent);
    'L':case s[2] of
          'C':TodaysCallerMCI := LastCallerPtr^.Location;
          'O':begin
                s1 := pdt2dat(LastCallerPtr^.LogonTime, 0);
                s1[0] := char(pos('m', s1) - 2);
                s1[length(s1)] := s1[length(s1) + 1];
                TodaysCallerMCI := s1;
              end;
          'T':begin
                s1 := pdt2dat(LastCallerPtr^.LogoffTime, 0);
                s1[0] := char(pos('m', s1) - 2);
                s1[length(s1)] := s1[length(s1) + 1];
                TodaysCallerMCI := s1;
              end;
        end;
    'M':case s[2] of
          'P':TodaysCallerMCI := cstr(LastCallerPtr^.MsgPost);
          'R':TodaysCallerMCI := cstr(LastCallerPtr^.MsgRead);
        end;
    'N':case s[2] of
          'D':TodaysCallerMCI := cstr(LastCallerPtr^.Node);
          'U':if (LastCallerPtr^.NewUser) then
                TodaysCallerMCI := '*'
              else
                TodaysCallerMCI := ' ';
        end;
    'S':if (s[2] = 'P') then
          if (LastCallerPtr^.Speed = 0) then
            TodaysCallerMCI := 'Local'
          else
            TodaysCallerMCI := cstr(LastCallerPtr^.Speed);
    'T':if (s[2] = 'O') then
          with LastCallerPtr^ do
            TodaysCallerMCI := cstr((LogoffTime - LogonTime) div 60);
    'U':case s[2] of
          'K':TodaysCallerMCI := cstr(LastCallerPtr^.UK);
          'L':TodaysCallerMCI := cstr(LastCallerPtr^.Uploads);
          'N':TodaysCallerMCI := LastCallerPtr^.UserName;
        end;
  end;
end;

procedure todayscallers(x:byte; cms:astr);
var
  LastCallerFile:file of LastCallerRec;
  LastCaller:LastCallerRec;
  i:integer;
  Junk:Pointer;
begin
   abort:=FALSE; next:=FALSE;
   if (cms = '') then
     cms := 'last';

   if not ReadBuffer(cms + 'm') then
     exit;

   assign(LastCallerFile,general.datapath+'laston.dat');
   reset(LastCallerFile);
   if ioresult<>0 then exit;
   i := 0;
   if (x > 0) and (x <= filesize(LastCallerFile)) then
     i := filesize(LastCallerFile) - x;

   printf(cms + 'h');
   AllowContinue := TRUE;
   seek(LastCallerFile, i);
   while (not eof(LastCallerFile)) and (not abort) do begin
       read(LastCallerFile, LastCaller);
       if (((LastCaller.LogonTime div 86400)<>(getpackdatetime div 86400)) and (x > 0)) or
          (((LastCaller.LogonTime div 86400)=(getpackdatetime div 86400))) and
          (not LastCaller.Invisible) then
          DisplayBuffer(TodaysCallerMCI, @LastCaller, Junk);
   end;
   if (not Abort) then
     printf(cms + 't');
   AllowContinue := FALSE;
   close(LastCallerFile);
   Lasterror := IOResult;
end;

end.
