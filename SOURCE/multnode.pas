{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

Unit Multnode;

Interface

Uses crt, overlay, common;

procedure list_nodes;
procedure toggle_chat_avail;
procedure page_user;
procedure check_status;
procedure multiline_Chat;
procedure dump_node;
procedure send_message(const b:astr);

implementation

uses ShortMsg, Script, timefunc, menus, doors;

procedure pick_node(var x:word; ischat:boolean);
var s:string[5];
begin
  list_nodes;
  prt('Which node: ');
  input(s, sizeof(s) - 1);
  x := value(s);
  nl;
  if (x > 0) and (x <= maxnodes) and (x <> node) then
    with noder do
      begin
       loadnode(x);
       if (not (NActive in Status) or (not (NAvail in Status) and ischat)) and not
          ((NInvisible in Status) and not CoSysOp) then
          begin
            print('That node is unavailable.');
            x:=0;
          end;
       if (User = 0) or not (NAvail in Status) or ((NInvisible in Status) and not CoSysOp) then
          x := 0;
      end
  else
    x := 0;
end;

procedure dump_node;
var x:word;
begin
  pick_node(x, FALSE);
  if (x > 0) then
    if pynq('Hang up user on node '+cstr(x)+'? ') then
      begin
        loadnode(x);
        if pynq('Recycle node '+cstr(x)+' after logoff? ') then
          noder.status := noder.status + [NHangup]
        else
          noder.status := noder.status + [NRecycle];
        savenode(x);
      end;
end;

procedure page_user;
var b:word;
begin
  if not general.multinode then exit;
  pick_node(b, TRUE);
  if (b>0) and (b<>node) then
    send_message(cstr(b) + ';^8' + Caps(thisuser.name)+' on node '+cstr(node)+' has paged you for chat.'^M^J);
end;

procedure check_status;
var j:byte;
    f:file;
    s:string[255];
begin
  loadnode(node);
    with noder do
    begin
     if (NUpdate in status) then
        begin
          j := thisuser.waiting;
          reset(uf);
          seek(uf,usernum);
          read(uf,thisuser);
          close(uf);
          Lasterror := IOResult;
          update_screen;
          if thisuser.waiting > j then
            print(^M^J'^8You have new private mail waiting.'^M^J'');
          status := status - [NUpdate];
          savenode(node);
          if (smw in thisuser.flags) then
            begin
              rsm;
              nl;
            end;
        end;
     if (NHangup in status) or
         (NRecycle in status) then
       begin
         hangup := TRUE;
         if (NRecycle in status) then
           QuitAfterDone := TRUE;
       end;
     if (not MultinodeChat) and (maxchatrec > nodechatlastrec) then
       begin
         assign(f,general.multpath + 'message.'+cstr(node));
         reset(f,1);
         seek(f,nodechatlastrec);
         while not eof(f) do
           begin
             blockread(f,s[0],1);
             blockread(f,s[1],ord(s[0]));
             print(s);
           end;
         close(f);
         Lasterror := IOResult;
         nodechatlastrec := maxchatrec;
         Pausescr(FALSE);
       end;
    end;
end;

procedure LowLevelSend(s:string; node:integer);
var
  f:file;
begin
  if (node < 0) then exit;
  assign(f, general.multpath + 'message.' + cstr(node));
  reset(f,1);
  if (ioresult = 2) then
    rewrite(f,1);
  seek(f, filesize(f));
  blockwrite(f, s[0], length(s) + 1);
  close(f);
  Lasterror := IOResult;
end;


procedure multiline_chat;

type
  WhyNot = (NotModerator, NotOnline, NotRoom, NotInRoom);

var
  done,ChannelOnly:boolean;
  s:string[255];
  s2,s3,execs:astr;
  i,j:integer;
  ActionsFile:Text;
  oldactivity:byte;
  c:char;
  u:userrec;
  RoomFile:file of RoomRec;
  Room:RoomRec;
  OldTimeOut, OldTimeOutBell:integer;
  SaveName:string[36];

  function ActionMCI(s:astr):string;
  var
    Temp:Astr;
    Index:integer;
  begin
    Temp := '';
    for Index := 1 to length(s) do
      if (s[Index] = '%') then
        case (upcase(s[Index + 1])) of
        'S':begin
              Temp := Temp + Caps(Thisuser.Name);
              inc(Index);
            end;
        'R':begin
              Temp := Temp + Caps(SaveName);
              inc(Index);
            end;
        'G':begin
              Temp := Temp + aonoff(thisuser.sex = 'M', 'his', 'her');
              inc(Index);
            end;
        'H':begin
              Temp := Temp + aonoff(thisuser.sex = 'M', 'him', 'her');
              inc(Index);
            end;
        end
      else
        Temp := Temp + s[Index];

    ActionMCI := Temp;
  end;

  procedure loadRoom(var chan:integer);
  begin
    reset(RoomFile);
    seek(RoomFile, Chan - 1);
    read(RoomFile, Room);
    close(RoomFile);
    Lasterror := IOResult;
  end;

  procedure saveRoom(var chan:integer);
  begin
    reset(RoomFile);
    seek(RoomFile, Chan - 1);
    write(RoomFile, Room);
    close(RoomFile);
    Lasterror := IOResult;
  end;

  procedure sendmessage(s:string; showhere:boolean);
  var
    i:word;
    trap:text;
  begin
    if (General.TrapTeleConf) then
      begin
        assign(trap, General.LogsPath + 'ROOM'+cstr(RoomNumber) + '.TRP');
        append(trap);
        if (ioResult = 2) then
          rewrite(trap);
        writeln(trap, stripcolor(s));
        close(trap);
      end;
    with noder do
      for i:=1 to maxnodes do
        begin
          loadnode(i);
          if (i <> node) and ((not ((Node mod 8) in Forget[Node div 8])) and
             ((not ChannelOnly) and (Activity = 7) and (Room = RoomNumber)) or
             ((Noder.Channel = ChatChannel) and (ChatChannel > 0) and ChannelOnly)) then
             LowLevelSend(s,i);
        end;
    if (ShowHere) then
      begin
        if Multinodechat and not aacs(general.TeleConfMCI) then
          mciallowed := FALSE;
        print(s);
        mciallowed := TRUE;
      end;
  end;

  procedure AddToRoom(var Chan:integer);
  var
    People:word;
    i:word;
  begin
    if (not Invisible) and not ((Chan Mod 8) in Noder.Booted[Chan div 8]) then
      sendmessage('^0[ ^9' + Caps(Thisuser.Name) + ' ^0has entered the room. ]', FALSE);

    print('^1You are now in conference room ^3' + cstr(Chan));

    loadRoom(Chan);
    if (not room.occupied) then
      begin
        room.occupied := TRUE;
        saveRoom(Chan);
      end;

    People := 0;

    for i:=1 to maxnodes do
      begin
        if (i = node) then continue;
        loadnode(i);
        with noder do
          if (room = Chan) and (Activity = 7) then
            inc(People);
      end;

    with room do
      begin
        if (Chan = 1) then
          Topic := 'Main';
        if (Topic <> '') then
          print('^1The Current Topic is: ^3' + Topic);
        if (People = 0) then
          print('^1You are the only one present.')
        else
          print('^1There ' + aonoff(People = 1, 'is','are') + ' ' + cstr(People) +
                ' other ' + aonoff(People = 1,'person','people')  + ' present.');
      end;
    loadnode(node);
    Noder.Room := Chan;
    savenode(node);
  end;

  procedure RemoveFromRoom(var Chan:integer);
  var
    People:word;
    i:word;
  begin
    if (not Invisible) and not ((Chan Mod 8) in Noder.Booted[Chan div 8]) then
      sendmessage('^0[^9 ' + Caps(Thisuser.Name) + '^0 has left the room. ]', FALSE);
    loadRoom(Chan);
    with Room do
      begin
        if (Moderator = Usernum) then
          Moderator := 0;
     {  if (people = 0) then
          fillchar(Room,sizeof(Room),0);   }
      end;
    People := 0;

    for i:=1 to maxnodes do
      begin
        if (i = node) then continue;
        loadnode(i);
        with noder do
          if (room = Chan) and (Activity = 7) then
            inc(People);
      end;
    if (People = 1) then
      room.occupied := FALSE;
    if (not Invisible) then
      saveRoom(Chan);
  end;

  function Name2Number(var s, sname:astr):integer;
  var
    i:integer;
    Temp:string;
  begin
    Name2Number := 0;
    if (pos(' ',s) > 0) then
      Sname := copy(s,1,pos(' ',s))
    else
      Sname := s;
    i := value(sqoutsp(Sname));
    if (sqoutsp(Sname) = cstr(i)) and ((i > 0) and (i <= MaxNodes)) then
      begin
        loadnode(i);
        with Noder do
          if (User > 0) then
            begin
              if ((not (NInvisible in status)) or (CoSysOp)) then
                Name2Number := i
              else
                Name2Number := 0;
              writeln('here-', username);
              s := copy(s, length(Sname) + 1, 255);
              Sname := Caps(username);
              exit;
            end;
      end;
    i := 1;
    Sname := '';
    if (pos(' ',s) > 0) then
      Temp := allcaps(copy(s,1, pos(' ',s) - 1))
    else
      Temp := allcaps(s);
    while (i <= MaxNodes) do
      begin
        loadnode(i);
        with noder do
        if (User > 0) then
          begin
            if ((username = allcaps(copy(s,1,length(username)))) or
               (pos(Temp, Username) > 0)) then
              begin
                Name2Number := i;
                if (username = allcaps(copy(s,1,length(username)))) then
                  s := copy(s, length(username) + 2, 255)
                else
                  s := copy(s, length(temp) + 2, 255);
                sname := Caps(username);
                break;
              end;
          end;
        inc(i);
      end;
  end;

  procedure Nope(Reason:WhyNot);
  begin
    case Reason of
      NotModerator:print(^M^J'|10You are not the moderator.'^M^J);
      NotOnline:print(^M^J'|10That user is not logged on.'^M^J);
      NotRoom:print(^M^J'|10Invalid room number.'^M^J);
      NotInRoom:print(^M^J'|10That user is not in this room.'^M^J);
    end;
  end;

  procedure showroom(Chan:integer);
  var
    People:word;
    i:word;
  begin
    loadRoom(Chan);
    if (not room.occupied) then exit;
    People := 0;

    for i:=1 to maxnodes do
      begin
        if (i = node) then continue;
        loadnode(i);
        with noder do
          if (room = Chan) and (Activity = 7) then
            inc(People);
      end;

    if (People > 0) then
      begin
        nl;
        if (Room.Moderator > 0) then
          loadurec(u,Room.Moderator)
        else
          U.Name := 'Nobody';
        printacr('^9Conference Room: ^3' + mn(Chan,5) + ' ^9Moderator: ^3' + Caps(U.Name));

        if (Room.Private) then
          s := 'Private'
        else
          s := 'Public';

        printacr('^9Type: ^3' + mln(s,17) + '^9Topic: ^3' + Room.Topic);
        if (Room.Anonymous) then
          printacr('This room is in anonymous mode.');
        nl;
        j := 1;
        while (J <= MaxNodes) and (not abort) do
          begin
            loadnode(j);
            if (Noder.Activity = 7) and (Noder.Room = Chan) then
              if not (NInvisible in Noder.Status) or (CoSysOp) then
                printacr('^1' + Caps(noder.username) + ' on node ' + cstr(j));
            inc(j);
          end;
        nl;
      end;
  end;

  procedure inputmain(var s:string);
  var os,cs:string;
      cp:integer;
      c:char;
      ml, origcolor:byte;
      cb:word;
      LastCheck:longint;

    procedure dobackspace;
    var i,j,c:byte;
        wascolor:boolean;

      procedure set_color;
      begin
        c:=origcolor;
        i:=1;
        while (i < cp) do begin
          if (s[i]='^') then begin
            c:=Scheme.Color[ord(s[i+1]) + ord('1')];
            inc(i);
          end;
          if (s[i]='|') and (i + 1 < length(s)) and
             (s[i + 1] in ['0'..'9']) and (s[i + 2] in ['0'..'9']) then begin
            cs:=s[i + 1] + s[i + 2];
            case cb of
              0..15:c := (c - (c mod 16) + cb);
              16..23:c:= ((cb - 16) * 16) + (c mod 16);
            end;
          end;
          inc(i);
        end;
        setc(c);
      end;

    begin
      wascolor:=FALSE;
      if (cp>1) then begin
        dec(cp);
        if (cp>1) then begin
          if (s[cp] in ['0'..'9']) then begin
            if (s[cp-1]='^') then begin
              dec(cp);
              wascolor:=TRUE;
              set_color;
            end else begin
              j:=0;
              while (s[cp-j]<>'|') and (s[cp-j] in ['0'..'9']) and (j<cp) do begin
                inc(j);
              end;
              if s[cp-j]='|' then begin
                 wascolor:=TRUE;
                 dec(cp,j);
                 set_color;
              end;
            end;
          end;
        end;
        if not wascolor then begin
           backspace;
           if (trapping) then write(trapfile,^H' '^H);
        end;
      end;
    end;

  begin
    origcolor := curco; os:=s; s:='';
    ml := 253 - length(MCI(Liner.TeleConfNormal));

    checkhangup;
    if (hangup) then exit;
    cp := 1;
    LastCheck := 0;
    repeat
      mlc:=s;
      MultiNodeChat := TRUE;
      if (cp > 1) and MultiNodeChat and not Thisuser.TeleConfInt then
        MultiNodeChat := FALSE;

      c := char(getkey);

      if (Timer - LastCheck > 1) then
        begin
          loadnode(node);

          if ((RoomNumber mod 8) in Noder.Booted[RoomNumber div 8]) then
            begin
              s := '';
              print('^5You have been ^0EJECTED^5 from the room.'^M^J);
              if (RoomNumber = 1) then
                Done := TRUE
              else
                begin
                  RemoveFromRoom(RoomNumber);
                  RoomNumber := 1;
                  AddToRoom(RoomNumber);
                end;
              exit;
            end
        end;

      case c of
      ^H:dobackspace;
      ^P:if (cp < ml) then begin
             c := char(getkey);
             if (c in ['0'..'9']) then
               begin
                 UserColor(ord(c)-48);
                 s[cp]:='^'; s[cp+1]:=c;
                 inc(cp,2);
               end;
           end;
         #32..#123,#125..#255:
            if (cp <= ml) then
              begin
                s[cp]:=c; inc(cp);
                outkey(c);
                if (trapping) then write(trapfile,c);
              end;
        '|':if (cp + 1 <= ml) then
              begin
                cs:='';
                c:='0';
                cb:=0;
                while (c in ['0'..'9']) and (cb < 2) do
                  begin
                    c := char(getkey);
                    if (c in ['0'..'9']) then
                      cs:=cs+c;
                    inc(cb);
                  end;
                cb:=value(cs);
                case cb of
                   0..15:setc(curco - (curco mod 16) + cb);
                  16..23:setc(((cb - 16) * 16) + (curco mod 16));
                end;
                if not (c in ['0'..'9']) then
                  begin
                    outkey(c);
                    if (trapping) then write(trapfile,c);
                    cs:=cs+c;  {here was buf}
                  end;
                s:=s+'|'+cs;
                inc(cp,length(cs)+1);
              end
            else
              if (cp <= ml) then
                begin
                  s[cp]:=c; inc(cp); outkey(c);
                  if (trapping) then write(trapfile,c);
                end;
        ^X:begin while (cp<>1) do dobackspace; setc(origcolor); end;
      end;
      s[0]:=chr(cp-1);
    until ((c=^M) or (c=^N) or (hangup));
    mlc:='';
    nl;
  end;

begin
  mlc:='';
  RoomNumber := 1;
  if exist(general.multpath + 'ACTIONS.LST') then
    assign(ActionsFile, general.multpath + 'ACTIONS.LST')
  else
    assign(ActionsFile, general.miscpath + 'ACTIONS.LST');
  reset(ActionsFile);
  if (IOResult = 2) then
    rewrite(ActionsFile);
  close(ActionsFile);

  assign(RoomFile,general.multpath + 'ROOM.DAT');
  reset(RoomFile);
  if (IOResult = 2) then
    rewrite(RoomFile);

  fillchar(Room,sizeof(Room),0);
  seek(RoomFile,filesize(RoomFile));
  while (filesize(RoomFile) < 255) do
    write(RoomFile, Room);

  close(RoomFile);

  if (IOResult <> 0) then
    exit;


  OldTimeOut := General.TimeOut;  General.TimeOut := -1;
  OldTimeOutBell := General.TimeOutBell;  General.TimeOutBell := -1;
  nodechatlastrec:=0;
  kill(general.multpath + 'message.' + cstr(node));
  loadnode(node);
  ChannelOnly := FALSE;

  oldactivity:=noder.activity;
  noder.activity:=7;
  savenode(node);
  cls;
  sysoplog('Entered Teleconferencing');
  printf('teleconf');
  if (nofile) then
    print('^0  Welcome to Teleconferencing.  Type ^5/?^0 for help or ^5/Q^0 to quit.'^M^J);

  AddToRoom(RoomNumber);

  nl;

  done:=FALSE;
  while (not done) and (not hangup) do begin
    tleft;
    MultiNodeChat:=TRUE;
    loadnode(node);
    Usercolor(3);

    check_status;
    inputmain(s);

    ChannelOnly := FALSE;

    MultiNodeChat:=FALSE;

    if (hangup) then
      s := '/Q';

    if (s = '`') then
      if (ChatChannel > 0) then
        begin
          j := 1;
          print('^0The following people are in global channel '+cstr(ChatChannel)+': '^M^J);
          while (J <= MaxNodes) and (not abort) do
            begin
              loadnode(j);
              with noder do
                if (Activity = 7) and (Channel = ChatChannel) and (j <> Node) then
                  begin
                    printacr('^9' + Caps(username) + ' on node ' + cstr(j));
                    ChannelOnly := TRUE;
                  end;
              inc(j);
            end;
          if not ChannelOnly then
            print('^9None.')
          else
            ChannelOnly := FALSE;
          nl;
          s := '';
        end
      else
        begin
          print('^0You are not in a global channel.'^M^J);
          s := '';
        end;

    if (not done) and (s <> '') and (s[1]='/') then begin
      c:=upcase(s[2]);
      s3 := allcaps(copy(s,2,255));
      if (pos(' ',s3) > 0) then
        begin
          SaveName := copy(s3, pos(' ',s3) + 1, 255);
          s3 := copy(s3, 1, pos(' ', s3) - 1);
        end
      else
        SaveName := '';

      s2 := SaveName;

      if (SaveName <> '') then
        begin
          i := Name2Number(s2, SaveName);
          if (SaveName = '') then
            i := -1;
        end
      else
        i := 0;
      writeln(savename,'-',i);

      reset(ActionsFile);
      while not eof(ActionsFile) do
        begin
          readln(ActionsFile, s2);            { Action word }
          if (Allcaps(s2) = s3) then
            begin
              readln(ActionsFile, s2);        { What sender sees }
              s2 := MCI(s2);
              if (copy(allcaps(s2), 1, 5) <> ':EXEC') then
                begin
                  print('^0'+ActionMCI(s2));
                  execs := '';
                end
              else
                execs := copy(s2, 6, 255);    { strip ":EXEC" }
              readln(ActionsFile, s2);        { What everybody else sees }
              if (i = 0) then
                readln(ActionsFile, s2);      { What evrybdy sees if no rcvr }
              s2 := MCI(s2);
              s2 := '^0' + ActionMCI(s2);
              with noder do
                for j := 1 to maxnodes do
                  begin
                    loadnode(j);
                    if (Activity = 7) and (Room = RoomNumber) and
                       (j <> node) and not ((Node mod 8) in Forget[Node div 8]) and
                       (j <> i) then
                      LowLevelSend(s2,j);
                  end;
              if (i > 0) then
                readln(ActionsFile, s2);
              readln(ActionsFile, s2);        { What receiver sees }
              s2 := MCI(s2);
              if (i > 0) then
                begin
                  loadnode(i);
                  if (Noder.Activity = 7) and (Noder.Room = RoomNumber) and
                    not ((Node mod 8) in noder.Forget[Node div 8]) then
                    LowLevelSend('^0'+ActionMCI(s2), i);
                end;
              s := '';
              if (execs <> '') then
                begin
                  c := execs[1];
                  execs := copy(execs, 2, 255);
                  dodoorfunc(c, execs);
                end;
              break;
            end
          else
            for j := 1 to 4 do
              readln(ActionsFile, s2);
        end;
      close(ActionsFile);

      if (s <> '') then
        case c of
        '/':if (copy(s,2,3) = '/\\') and (so) then
              domenucommand(done, Allcaps(copy(s, 5, 255)), s2);
        'F':if (Allcaps(copy(s,2,6)) = 'FORGET') then
              begin
                s := copy(s,pos(' ',s) + 1,length(s));
                i := Name2Number(s, SaveName);
                s := '';
                if (i > 0) and (i <= maxnodes) then
                  begin
                    loadurec(u, noder.user);
                    if (aacs1(u, noder.user, General.csop)) then
                      print('^9You cannot forget a sysop.'^M^J)
                    else
                      begin
                        loadnode(node);
                        Noder.Forget[i div 8] := Noder.Forget[i div 8] + [i mod 8];
                        savenode(node);
                        print('^0' + SaveName + '^9 has been forgotten.');
                      end;
                  end
                else
                  Nope(NotOnLine);
              end;
        'R':if (Allcaps(copy(s,2,8)) = 'REMEMBER') then
              begin
                s := copy(s,pos(' ',s) + 1, 255);
                i := Name2Number(s,SaveName);
      writeln(savename,'-',i);
                if (i > 0) and (i <= maxnodes) then
                  begin
                    loadnode(node);
                    Noder.Forget[i div 8] := Noder.Forget[i div 8] - [i mod 8];
                    savenode(node);
                    print('^0' + SaveName + '^9 has been remembered.');
                  end
                else
                  Nope(NotOnLine);
              end
            else
              begin
                s:= copy(s,pos(' ',s) + 1, 255);
                i := SearchUser(s, FALSE);
                readasw(i, 'registry');
                s := '';
              end;
        'A':if (Allcaps(copy(s,2,4)) <> 'ANON') then
              begin
                s := copy(s,4,length(s) - 3);
                s := '^0' + Caps(thisuser.name) + ' ' + s;
              end
            else
             begin
               if (Room.Moderator = Usernum) or (CoSysOp) then
                 begin
                   loadRoom(RoomNumber);
                   Room.Anonymous := not Room.Anonymous;
                   saveRoom(RoomNumber);
                   sendmessage('^0[ This room is now in ^2' + aonoff(Room.Anonymous,'Anonymous','Regular') +
                               '^0 ]', TRUE);
                 end
               else
                 Nope(NotModerator);
             end;
        'I':if (Allcaps(Copy(s,2,9)) = 'INTERRUPT') then
              begin
                Thisuser.TeleConfInt := not Thisuser.TeleConfInt;
                print('^9Your message interruption is now ' + onoff(Thisuser.TeleConfInt));
              end
            else
            begin
              if (Room.Moderator = Usernum) or (CoSysOp) then
                begin
                  if (length(s) = 2) then
                    begin
                      loadRoom(RoomNumber);
                      Room.Private := not Room.Private;
                      saveRoom(RoomNumber);
                      sendmessage('^0[ This room is now ^2'+aonoff(Room.Private,'private','public') + '^0 ]', TRUE);
                    end
                  else
                    begin
                      s := copy(s,4,length(s)-3);
                      i := Name2Number(s,SaveName);
                      if (i > 0) and (i <= maxnodes) then
                        begin
                          loadnode(i);
                          s := ^M^J+'^9[^0 ' + Caps(thisuser.name) + '^9 is inviting you to join conference room ' +
                               cstr(RoomNumber) + ' ]';
                          noder.invited[RoomNumber div 8] := noder.invited[RoomNumber div 8] + [RoomNumber mod 8];
                          noder.booted[RoomNumber div 8] := noder.booted[RoomNumber div 8] - [RoomNumber mod 8];
                          print('^0' + SaveName + '^9 on node ' + cstr(i) + ' has been invited.');
                          savenode(i);
                          if (i <> node) then
                            LowLevelSend(s,i);
                        end
                      else
                        Nope(NotOnline);
                      s := '';
                    end;
                end
              else
                Nope(NotModerator);
            end;
        'W':list_nodes;
        'G':if (Allcaps(copy(s,2,6)) = 'GLOBAL') then
              begin
                loadnode(node);
                noder.channel := value(copy(s,pos(' ',s) + 1,255));
                print(^M^J'^0You are now in global channel ' + cstr(noder.channel)+'.'^M^J);
                ChatChannel := Noder.Channel;
                savenode(node);
                ChannelOnly := TRUE;
                if (not Invisible) then
                  sendmessage('^9' + Caps(Thisuser.Name) + ' has joined global channel '+cstr(chatchannel)+'.', FALSE);
              end
            else
              if (AllCaps(s) = '/G') and pynq('Are you sure you want to disconnect? ') then
                begin
                  if (not Invisible) then
                    sendmessage('^0[ ^2' + Caps(Thisuser.Name) + '^0 has disconnected on node ' + cstr(node) + ' ]',FALSE);
                  hangup := TRUE;
                end;
        'E':begin
              if (Allcaps(copy(s,2,4)) = 'ECHO') then
                begin
                  Thisuser.TeleConfEcho := not Thisuser.TeleConfEcho;
                  print('^9Your message echo is now ' + onoff(Thisuser.TeleConfEcho));
                end
              else
                if (Allcaps(copy(s,2,5)) = 'EJECT') then
                 begin
                   if (Room.Moderator = Usernum) or (CoSysOp) then
                     begin
                       s := copy(s,pos(' ',s) + 1,length(s));
                       i := Name2Number(s,SaveName);
                       if (i > 0) and (i <= MaxNodes) then
                         begin
                           loadnode(i);
                           if (noder.activity = 7) and (Noder.Room = RoomNumber) then
                             begin
                               loadurec(u, noder.user);
                               if (aacs1(u, noder.user, General.csop)) then
                                 print('^9You cannot eject that person.'^M^J)
                               else
                                 begin
                                   Noder.Booted[RoomNumber div 8] := Noder.Booted[RoomNumber div 8] + [RoomNumber mod 8];
                                   Noder.Room := 1;
                                   savenode(i);
                                   if (not Invisible) then
                                     sendmessage('^0' + SaveName + '^9 has just been ejected from the room by ^0'+
                                          caps(thisuser.name), TRUE);
                                   sysoplog('Ejected ' + SaveName);
                                 end;
                             end
                           else
                             Nope(NotInRoom);
                         end
                       else
                         Nope(NotOnline);
                       s := '';
                     end
                 else
                   Nope(NotModerator);
                 end;
            end;
        'S':begin
              i := 1;  abort := FALSE;
              while (i <= 255) and (not abort) do
                begin
                  ShowRoom(i);
                  inc(i);
                end;
              loadRoom(RoomNumber);
              s := '';
            end;
        'M':begin
              s := copy(s,4,40);
              nl;
              if (CoSysOp) or (Room.Moderator = Usernum) or ((Room.Moderator = 0) and (RoomNumber <> 1)) then
                begin
                  loadRoom(RoomNumber);
                  Room.Topic := S;
                  if (not Invisible) then
                    sendmessage('^0[ Conference ''^2' + Room.Topic + '^0'' is now moderated by ^2' +
                              Caps(Thisuser.Name) + '^0 ]', TRUE);
                  if (Room.Moderator = 0) then
                    begin
                      for i := 1 to MaxNodes do
                        begin
                          loadnode(i);
                          noder.invited[RoomNumber div 8] := noder.invited[RoomNumber div 8] - [RoomNumber mod 8];
                          noder.booted[RoomNumber div 8] := noder.booted[RoomNumber div 8] - [RoomNumber mod 8];
                          savenode(i);
                        end;
                    end;
                  Room.Moderator := Usernum;
                  saveRoom(RoomNumber);
                end
              else
                Nope(NotModerator);
              s := '';
            end;
        'P':begin
              s := copy(s,4,length(s) - 3);
              i := Name2Number(s,SaveName);
              if (i > 0) and (i <= maxnodes) then
                begin
                  loadnode(i);
                  if ((Node mod 8) in Noder.Forget[Node div 8]) then
                    print('^9That user has forgotten you.'^M^J)
                  else
                    if not (NAvail in Noder.status) then
                      print('^9That user is unavailable.'^M^J)
                    else
                      if not (NInvisible in Noder.status) then
                        begin
                          print('^9Private message sent to ^0' + SaveName);
                          if aacs(general.TeleConfMCI) then
                            s := MCI(s);
                          s := MCI(Liner.TeleConfPrivate) + s;
                          LowLevelSend(s,i)
                        end
                      else
                        Nope(NotOnline);
                end
              else
                Nope(NotOnline);
              s := '';
            end;
        'J':begin
              s := copy(s, 4, length(s) - 3);
              i := value(s);
              nl;
              if (i > 0) and (i <= 255) then
                begin
                  loadnode(node);
                  if ((i Mod 8) in Noder.Booted[i div 8]) then
                    begin
                      print('^5You were ^0EJECTED^5 from that room.'^M^J);
                    end
                  else
                    begin
                      loadRoom(i);
                      if (Room.Private) and not (CoSysOp) and not
                        ((i Mod 8) in Noder.Invited[i div 8]) then
                        begin
                          print('^9You must be invited to private conference rooms.'^M^J);
                          loadRoom(RoomNumber);
                        end
                      else
                        begin
                          RemoveFromRoom(RoomNumber);
                          RoomNumber := i;
                          AddToRoom(RoomNumber);
                          sysoplog('Joined room ' + cstr(RoomNumber) + ' ' + Room.Topic);
                        end;
                   end;
                end
              else
                Nope(NotRoom);
              s := '';
            end;
        '?':printf('telehelp');
        'L':if (Allcaps(copy(s,2,4)) = 'LIST') then printf('actions');
        'Q':begin
              s := copy(s,4,40);
              if (s <> '') then
                s := '^0' + Caps(thisuser.name) + ' ' + s;
              loadnode(node);
              savenode(node);
              done:=TRUE;
            end;
        'U':begin
              ShowRoom(RoomNumber);
              s := '';
            end;
      end;
      if (s[1] = '/') then
        s := '';
    end
  else
    if (s > #0) then
      begin
        loadRoom(RoomNumber);
        if (s[1] <> '`') then
          if (Room.Anonymous) then
            s := MCI(Liner.TeleConfAnon) + s
          else
            s := MCI(Liner.TeleConfNormal) + s
        else
          begin
            s := MCI(Liner.TeleConfGlobal) + copy(s, 2, 255);
            ChannelOnly := TRUE;
          end;
      end
    else
      s := '';
  if (s <> '') then
    begin
      MultiNodeChat := TRUE;
      if (aacs(general.TeleConfMCI)) then
        s := MCI(s);
      sendmessage(s, Thisuser.TeleConfEcho);
    end;
  end;
  MultiNodeChat := FALSE;
  loadnode(node);
  noder.activity:=oldactivity;
  savenode(node);
  RemoveFromRoom(RoomNumber);
  NodeChatLastRec := 0;
  kill(general.multpath + 'message.'+cstr(node));
  General.TimeOut := OldTimeOut;
  General.TimeOutBell := OldTimeOutBell;
end;

procedure toggle_chat_avail;
begin
  if not general.multinode then
    exit;
  loadnode(node);
  with Noder do
    if (NAvail in Status) then
      Status := Status - [NAvail]
    else
      Status := Status + [NAvail];
  savenode(node);
  nl;
  if (NAvail in Noder.Status) then
    print('You are now available for chat.')
  else
    print('You are not available for chat.');
end;

procedure send_message(const b:astr);
var
  x:word;
  f:file;
  s:string[255];
  forced:boolean;
  c:char;

begin
  s := b;
  if not general.multinode then
    exit;
  x := value(s);

  if (b <> '') and (Invisible) then
    exit;

  forced := (s <> '');

  if (x = 0) and (copy(s,1,1) <> '0') then
     begin
       pick_node(x, TRUE);
       forced :=FALSE;
       if (x = 0) then
         exit;
     end;

  if (x = node) then exit;

  if (forced or aacs(general.TeleConfMCI)) then
    s := MCI(s);

  if (x > 0) then
    begin
      loadnode(x);
      if noder.user = 0 then
        exit;
    end;

  if (s <> '') then
    s := '^1' + copy(s, pos(';',s) + 1, 255)
  else
    begin
      prt('Message: ');
      inputmain(s,sizeof(s)-1,'c');
    end;

   if (forced or aacs(general.TeleConfMCI)) then
     s := MCI(s);

   if (s <> '') then
     begin
       if not forced then
         begin
           loadnode(x);
           if (not ((Node mod 8) in Noder.Forget[Node div 8])) then
             LowLevelSend(^M^J'^5Message from ' + caps(thisuser.name) + ' on node '+cstr(node) + ':^1'^M^J, x)
           else
             print(^M^J'That node has forgotten you.');
         end;
       if (x = 0) then
         for x := 1 to MaxNodes do
           if (x <> node) then
             begin
               loadnode(x);
               if (Noder.User > 0) then
                 LowLevelSend(s, x)
             end
           else
       else
         LowLevelSend(s, x);
     end;
end;

function NodeListMCI(const s:astr; Data1, Data2:Pointer):string;
var
  NodeRecPtr: ^NodeRec;
  i:^word;
begin
  NodeRecPtr := Data1;
  i := Data2;
  NodeListMCI := s;

  if (not (NActive in NodeRecPtr^.Status)) or (NodeRecPtr^.User > MaxUsers) or
     (NodeRecPtr^.User < 1) or
     ((NInvisible in NodeRecPtr^.Status) and (not CoSysOp)) then
    begin
      NodeListMCI := '-';
    end
  else
    with NodeRecPtr^ do
      case s[1] of
        'A':case s[2] of
              'C':NodeListMCI := Description;
              'G':NodeListMCI := cstr(Age);
              'T':NodeListMCI := aonoff((NActive in Status), 'Y', 'N');
              'V':NodeListMCI := aonoff((NAvail in Status), 'Y', 'N');
            end;
        'L':if (s[2] = 'C') then
              NodeListMCI := CityState;
        'N':if (s[2] = 'N') then
              NodeListMCI := cstr(i^);
        'U':if (s[2] = 'N') then
              NodeListMCI := Caps(Username);
        'R':if (s[2] = 'M') then
              NodeListMCI := cstr(Room);
        'S':if (s[2] = 'X') then
              NodeListMCI := Sex;
        'T':if (s[2] = 'O') then
              NodeListMCI := cstr((GetPackDateTime - Logontime) div 60);
      end;
end;


procedure list_nodes;
var
  i:word;
  avail:boolean;
begin
  if not general.multinode then exit;
  abort:=FALSE; next:=FALSE;
  if not ReadBuffer('nodelm') then
    exit;
  printf('nodelh');
  for i:=1 to maxnodes do
    begin
      loadnode(i);
      with Noder do
        case Activity of
          1:Description := 'Transferring files';
          2:Description := 'Out in a door';
          3:Description := 'Reading messages';
          4:Description := 'Writing a message';
          5:Description := 'Reading Email';
          6:Description := 'Using offline mail';
          7:Description := 'Teleconferencing';
        255:Description := Noder.Description;
        else Description := 'Miscellaneous';
        end;
      DisplayBuffer(NodeListMCI, @Noder, @i);
  end;
  if (not Abort) then
    printf('nodelt');
end;

end.
