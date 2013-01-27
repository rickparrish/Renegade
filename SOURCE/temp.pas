procedure TeleConfCheck;
var
	i:byte;
	f:file;
	s:string;
	oldmciallowed:boolean;
{ Only check if we're bored and not slicing }
begin
	if (maxchatrec > nodechatlastrec) then
		begin
			for i := 1 to lennmci(mlc) + 5 do
				backspace;
			assign(f, general.multpath + 'message.'+cstr(node));
			reset(f, 1);
			seek(f, nodechatlastrec);
			while not eof(f) do
				begin
					blockread(f,s[0],1);
					blockread(f,s[1],ord(s[0]));
					multinodechat := FALSE;  {avoid recursive calls during pause!}
					oldmciallowed := mciallowed;
					mciallowed := FALSE;
					print(s);
					mciallowed := oldmciallowed;
					multinodechat := TRUE;
				end;
			close(f);
			Lasterror := IOResult;
			nodechatlastrec := maxchatrec;
			prompt('^3' + mlc);
		end;
end;

