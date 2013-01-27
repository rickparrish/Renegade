{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ BBS List related functions }

unit BBSList;

interface

uses crt, dos, overlay, common;

procedure AddEditBBSList(const filename:astr);
procedure viewbbslist(const filename:astr);

implementation

uses timefunc;

function BBSListMCI(const s:astr; Data1, Data2:Pointer):string;
var
  i:integer;
  u:userrec;
  BBSListPtr: ^BBSListRec;
begin
  BBSListPtr := Data1;
  BBSListMCI := s;
  case s[1] of
    'B':if (s[2] = 'N') then
          BBSListMCI := BBSListPtr^.BBSName;
    'D':case s[2] of
         'A':BBSListMCI := pd2date(BBSListPtr^.DateAdded);
         'E':BBSListMCI := pd2date(BBSListPtr^.DateEdited);
         'S':BBSListMCI := BBSListPtr^.Description;
        end;
    'P':if (s[2] = 'N') then
          BBSListMCI := BBSListPtr^.PhoneNumber;
    'S':case s[2] of
         'N':BBSListMCI := BBSListPtr^.SysOpName;
         'P':BBSListMCI := BBSListPtr^.Speed;
         'W':BBSListMCI := BBSListPtr^.Software;
        end;
    'U':if (s[2] = 'N') then
          begin
            loadurec(u, BBSListPtr^.UserID);
            BBSListMCI := u.name;
          end;
  end;
end;

procedure viewbbslist(const filename:astr);
var
  s:astr;
  BBSList:BBSListRec;
  BBSListFile:file of BBSListRec;
  Extended:boolean;
  Junk:Pointer;
begin
  if (FileName = '') then
    s := 'bbslist.bbs'
  else
    if (pos('.', FileName) = 0) then
      s := FileName + '.bbs'
    else
      s := FileName;
  assign(BBSListFile, General.DataPath + s);
  reset(BBSListFile);
  if (ioResult <> 0) then
    begin
      print(^M^J'error accessing bbslist.');
      exit;
    end;

  Extended := pynq(^M^J'View extended version? ');

  if (Extended) then
    begin
      if not ReadBuffer('bbsme') then
        exit;
      printf('bbseh');
    end
  else
    begin
      if not ReadBuffer('bbsmn') then
        exit;
      printf('bbsnh');
    end;

  BBSList.Next := 0;
  Abort := FALSE;
  AllowContinue := TRUE;

  while (not EOF(BBSListFile)) and (BBSList.Next <> -1) and not (Abort) do
    begin
      read(BBSListFile, BBSList);
      DisplayBuffer(BBSListMCI, @BBSList, Junk);
      if (BBSList.Next <> - 1) then
         seek(BBSListFile, BBSList.Next);
    end;
  AllowContinue := FALSE;
  close(BBSListFile);
  if (not Abort) then
    if (Extended) then
      printf('bbset')
    else
      printf('bbsnt');
end;

procedure AddEditBBSList(const FileName:astr);
var
  s:astr;
  BBSList,
  BBSList2:BBSListRec;
  BBSListFile:file of BBSListRec;
  Found:boolean;
  Previous,
  NextPointer,
  RecordNumber:longint;
begin
  if (FileName = '') then
    s := 'bbslist.bbs'
  else
    if (pos('.', FileName) = 0) then
      s := FileName + '.bbs'
    else
      s := FileName;

  assign(BBSListFile, General.DataPath + s);

  if (not (ramsg in thisuser.flags)) then
    begin
      nl;
      if pynq('Do you want to add to or edit the BBS list? ') then
        begin
          print(^M^J'^1Enter the phone number of the BBS:');
          prt(':');
          inputformatted(s, '###-###-####', FALSE);

          if (s = '') then
            exit;

          reset(BBSListFile);
          if (ioresult = 2) then
            rewrite(BBSListFile);
          if (ioresult <> 0) then
            begin
              print(^M^J'error accessing bbslist.');
              exit;
            end;

          Found := FALSE;
          RecordNumber := 0;
          Previous := -1;

          BBSList.Next := 0;

          if (not EOF(BBSListFile)) then
            repeat
              read(BBSListFile, BBSList);
              if (BBSList.PhoneNumber = s) then
                Found := TRUE
              else
                begin
                  if (BBSList.PhoneNumber > s) then
                    break;
                  Previous := RecordNumber;
                  if (BBSList.Next <> -1) then
                    RecordNumber := BBSList.Next;
                end;
              if (BBSList.Next > -1) then
                seek(BBSListFile, BBSList.Next);
            until eof(BBSListFile) or (BBSList.Next = -1) or (Found);

          if (not Found) then
            begin
              fillchar(BBSList, sizeof(BBSList), 0);
              BBSList.PhoneNumber := s;
              RecordNumber := filesize(BBSListFile);
            end;

          close(BBSListFile);

          if (Found) and (BBSList.UserID <> Usernum) and (not CoSysOp) then
            begin
              print('That BBS already exists in the listing.'^M^J);
              exit;
            end;

          Abort := FALSE;

          print(^M^J'^1Enter the name of the BBS:');
          prt(':'); mpl(sizeof(BBSList.BBSName) - 1);
          inputmain(BBSList.BBSName, sizeof(BBSList.BBSName) - 1, 'CI');
          Abort := (BBSList.BBSName = '');

          if (not Abort) then
            begin
              print(^M^J'^1Enter the name of the SysOp:');
              prt(':'); mpl(sizeof(BBSList.SysOpName) - 1);
              inputmain(BBSList.SysOpName, sizeof(BBSList.SysOpName) - 1, 'CI');
              Abort := (BBSList.SysOpName = '');
            end;

          if (not Abort) then
            begin
              print(^M^J'^1Enter a description of the system:');
              prt(':'); mpl(sizeof(BBSList.Description) - 1);
              inputmain(BBSList.Description, sizeof(BBSList.Description) - 1, 'CI');
              Abort := (BBSList.Description = '');
            end;

          if (not Abort) then
            begin
              print(^M^J'^1Enter the BBS software used:');
              prt(':'); mpl(sizeof(BBSList.Software) - 1);
              inputmain(BBSList.Software, sizeof(BBSList.Software) - 1, 'CI');
            end;

          if (not Abort) then
            begin
              print(^M^J'^1Enter max speed of system (ie, 300,2400,14400).');
              prt(':'); mpl(sizeof(BBSList.Speed) - 1);
              inputmain(BBSList.Speed, sizeof(BBSList.Speed) - 1, 'CI');
              Abort := (BBSList.Speed = '');
            end;

          nl;

          if (not Abort) and (pynq('Save this entry? ')) then
            begin
              BBSList.DateEdited := getpackdatetime;
              if (not Found) then
                begin
                  BBSList.DateAdded := getpackdatetime;
                  BBSList.UserID := Usernum;
                end;
              reset(BBSListFile);
              Lasterror := ioresult;

              if (Found) or (filesize(BBSListFile) = 0) then { update old or create list }
                begin
                  seek(BBSListFile, RecordNumber);
                  if (not Found) then
                    BBSList.Next := -1;
                  write(BBSListFile, BBSList);
                end
              else
                if (Previous = -1) then  { replaces first record }
                  begin
                    seek(BBSListFile, 0);
                    read(BBSListFile, BBSList2);
                    seek(BBSListFile, 0);
                    BBSList.Next := RecordNumber;
                    write(BBSListFile, BBSList);
                    seek(BBSListFile, RecordNumber);
                    write(BBSListFile, BBSList2);
                  end
                else
                  begin
                    seek(BBSListFile, Previous);
                    read(BBSListFile, BBSList2);
                    BBSList.Next := BBSList2.Next;
                    BBSList2.Next := RecordNumber;
                    seek(BBSListFile, Previous);
                    write(BBSListFile, BBSList2);
                    seek(BBSListFile, RecordNumber);
                    write(BBSListFile, BBSList);
                  end;

              close(BBSListFile);
              sysoplog('Added to BBS list:');
              sl1(BBSList.BBSName + ' ' + BBSList.PhoneNumber);
            end;
        end;
    end
  else
    print('^7You are restricted from adding to the BBS list.');
  Lasterror := IOResult;
end;

end.
