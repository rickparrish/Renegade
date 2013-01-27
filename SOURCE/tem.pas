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

