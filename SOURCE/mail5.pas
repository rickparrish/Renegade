{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit mail5;

interface

uses crt, dos, overlay, common, timefunc;

procedure Post(replyto:longint; var ttoi:fromtoinfo; private:boolean);
procedure ReadMessages;
procedure ScanMessages(mstr:astr);
procedure NewScan(b:integer; var quit:boolean);
procedure GlobalNewScan;
procedure StartNewScan(var mstr:astr);
procedure ScanYours;
function firstnew:word;

implementation

uses sysop3, sysop4, mail0, mail1, Email, mail6, cuser, multnode, menus;

var
	TempLastRead:longint;

procedure Post(replyto:longint; var ttoi:fromtoinfo; private:boolean);
var mheader,mheader2:mheaderrec;
		ok:boolean;

	procedure nope(s:astr);
	begin
		if (ok) then
      print(^M^J + s + ^M^J);
		ok:=FALSE;
	end;

begin
	ok:=TRUE;
	loadboard(board);
	if (not aacs(memboard.postacs)) then
		nope('Your access does not allow you to post on this base.');
	if (AccountBalance < General.CreditPost) and not (fnocredits in thisuser.flags) then
		nope('Insufficient account balance to post a message.');
	if ((rpost in thisuser.flags) or (not aacs(general.normpubpost))) then
		nope('Your access priviledges do not include posting.');
	if ((ptoday>=general.maxpubpost) and (not MsgSysOp)) then
		nope('Too many messages posted today.');
	if (ok) then begin
		{xbread := readboard;}
		initboard(board);

		mheader.fileattached:=0;
		mheader.status := [];

		if (replyto <> -1) then begin
			mheader.mto := ttoi;
			if (mheader.mto.anon > 0) then
				begin
					mheader.mto.as := Usename(mheader.mto.anon,mheader.mto.as);
					{ mheader.mto.real := mheader.mto.as; }
				end;
		end else
			begin
				fillchar(mheader.mto,sizeof(mheader.mto),0);
				irt := '';
			end;
		if (InputMessage(TRUE,(replyto<>-1),'',mheader,'')) then
			begin
				if (replyto <> -1) then
					mheader.replyto := (HiMsg + 1) - replyto;

				if Private then
					mheader.status := mheader.status + [Prvt];

				saveheader(HiMsg+1,mheader);

				if (replyto<> -1) then
					begin
						loadheader(replyto,mheader2);
						inc(mheader2.replies);
						saveheader(replyto,mheader2);
					end;

				sysoplog(mheader.subject+' posted on ^5'+memboard.name);
				if (mheader.mto.as<>'') then
					sysoplog('  To: "'+mheader.mto.as+'"');

				print('^9Message posted on ^5'+memboard.name+'^9.'^M^J);

				inc(thisuser.msgpost);
				if not (fnocredits in thisuser.flags) then
					AdjustBalance(General.CreditPost);
				saveurec(thisuser, usernum);
				inc(ptoday);
				update_screen;
			end;
		{initboard(xbread);}
	end;
end;

procedure MainRead(var quit:boolean; oneonly:boolean);
var
	u:userrec;
	mheader:mheaderrec;
	old_menu, cmd, newmenucmd, s, s1:astr;
	getm:longint;
	i,j:integer;
	threadstart:word;
	Done,Cmdnothid,Cmdexists,ShowPrompt,b,
	AskPost,ContList,DoneScan,HadUnval:boolean;

	procedure ListMessages;
	var
		q:word;
		adate:datetime;
		numdone:byte;

	begin
		abort:=FALSE; numdone:=0;
		q:=HiMsg;
		if ((Msg_On<1) or (Msg_On>q)) then exit;
		cls;
		printacr('旼컴컴컫컴컴컴컴컴컴컴컴컴컫컴컴컴컴컴컴컴컴컴컴쩡컴컴컴컴컴컴컴컴컴쩡컴컴컴커');
		printacr('� Msg# � Sender            � Receiver           �  '+
						 'Subject           �! Posted �');
		printacr('읕컴컴컨컴컴컴컴컴컴컴컴컴컨컴컴컴컴컴컴컴컴컴컴좔컴컴컴컴컴컴컴컴컴좔컴컴컴켸');
    dec(Msg_On);

    while ((not hangup) and (not abort) and (numdone < pagelength - 7) and (Msg_On >= 0) and (Msg_On < q)) do begin
      inc(Msg_On);
			loadheader(Msg_On,mheader);
			if ((not (unvalidated in mheader.status))
					 and not (mdeleted in mheader.status))
					 or (MsgSysOp) then begin
						 if (mdeleted in mheader.status) then s:='''D '
								else if (unvalidated in mheader.status) then s:='''U '
									 else if ToYou(mheader) or FromYou(mheader) then s:='''> '
										 else if (TempLastRead < mheader.date) then s:='''* '
													else s:='  ';
						 s:=s + '"' + mln(cstr(Msg_On),5)+'  #';
						 if (mbrealname in memboard.mbstat) then
							 s1:=Usename(mheader.from.anon,mheader.from.real)
						 else
							 s1:=Usename(mheader.from.anon,mheader.from.as);
						 s:=s+mln(s1,18)+'  $';
						 if ((mbrealname in memboard.mbstat) and (mheader.mto.real<>'')) then
							 s1:=Usename(mheader.mto.anon,mheader.mto.real)
						 else
							 s1:=Usename(mheader.mto.anon,mheader.mto.as);
             s:=s+mln(s1,19)+' % ';
						 if (mheader.fileattached = 0) then
							 s := s + mln(mheader.subject,18)
						 else
							 s := s + mln(stripname(mheader.subject),18);
						 packtodate(adate,mheader.date);
						 s:=s+' &'+Zeropad(cstr(adate.month))+'/'+Zeropad(cstr(adate.day))+'/'+Zeropad(cstr(adate.year));
						 if (allowmci in mheader.status) then
							 printacr(s)
						 else
							 print(s);
						 inc(numdone);
			end;
			wkey;
		end;
		ShowPrompt := TRUE;
    {if (Msg_On>=q) and (Msg_On-2>=1) then dec(Msg_On,2) else dec(Msg_On);}
    if (Msg_On = q) then
      begin
        dec(Msg_On);
        loadheader(Msg_On, mheader);
      end;
	end;

	function CantBeSeen:boolean;
	begin
		CantBeSeen := (not MsgSysOp) and ((unvalidated in mheader.status) or (mdeleted in mheader.status) or
							 ((prvt in mheader.status) and not (ToYou(Mheader) or FromYou(Mheader))));
	end;


begin
	AskPost:=FALSE; ContList:=FALSE; DoneScan:=FALSE; HadUnval:=FALSE;
	threadstart:=0;  treadprompt := 0;	Abort:=FALSE;

	old_menu := curmenu;			{ otherwise it fucks up calling other menus }
	curmenu := general.menupath + 'readp.mnu';

	if (not newmenutoload) then
		readin2;

	AllowContinue := TRUE;

	i:=1;
	newmenucmd:='';
	while ((i<=noc) and (newmenucmd='')) do
		begin
			if (MenuCommand^[i].ckeys='FIRSTCMD') then
				begin
					if (aacs(MenuCommand^[i].acs)) then
						begin
							newmenucmd:='FIRSTCMD';
							domenuexec(cmd,newmenucmd);
						end;
				end;
			inc(i);
		end;

	repeat
		if (ContList) and (abort) then
			begin
				ContList := FALSE;
        print(^M^J'Continuous message listing off.'^M^J);
				treadprompt := 255;
			end;

		if (Msg_On < 1) or (Msg_On > HiMsg) then
			begin
				if (not ContList) then
					begin
						DoneScan := TRUE;
						AskPost := TRUE;
					end
				else
					begin
						ContList := FALSE;
						Msg_On := HiMsg;
						print(^M^J'Continuous message listing off.'^M^J);
						treadprompt := 255;
					end;
			end;

		if (not DoneScan) and (treadprompt in [0..2,8..10,18]) then
			begin
				if (ContList) then
					next := TRUE;
				loadheader(Msg_On, mheader);
				if (unvalidated in mheader.status) then
					HadUnval := TRUE;

				while (((Msg_On < HiMsg) and (treadprompt <> 2)) or
							 ((Msg_On > 1) and (treadprompt = 2))) and
							 CantBeSeen do
					begin
						if (treadprompt = 2) then
							dec(Msg_On)
						else
							inc(Msg_On);
						loadheader(Msg_On, mheader);
					end;
				if ((Msg_On = 1) or (Msg_On = HiMsg)) and CantBeSeen then
					begin
						DoneScan := TRUE;
						AskPost := TRUE;
					end
				else
					begin
						if ((clsmsg in thisuser.sflags) and (not ContList)) then
							cls
						else
							nl;
						readmsg(Msg_On, Msg_On, HiMsg);
						if (TempLastRead < mheader.date) and (mheader.date <= getpackdatetime) then
								TempLastRead := mheader.date;
						inc(mread);
					end;
			end;

	if (not ContList) and (not DoneScan) then
		repeat
			treadprompt := 0;
			mainmenuhandle(cmd);
			newmenucmd := ''; j := 0; done := FALSE;
			repeat
				fcmd(cmd, j, noc, cmdexists, cmdnothid);
				if (j <> 0) and (MenuCommand^[j].cmdkeys <> '-^') and
					 (MenuCommand^[j].cmdkeys <> '-/') and (MenuCommand^[j].cmdkeys <> '-\') then
					domenucommand(done, MenuCommand^[j].cmdkeys + MenuCommand^[j].options, newmenucmd);
			until (j = 0) or (done) or (hangup);
			abort := FALSE;  next := FALSE;
			case treadprompt of
				1:;
				2:if (Msg_On = 1) then
						print(^M^J'Already at the first message.'^M^J)
					else
						dec(Msg_On, 1);
				3:if MsgSysOp then movemsg(msg_on);
				4:if CoSysOp then extract(msg_on);
				5:if (MsgSysOp) or FromYou(mheader) then
						begin
							repeat
								prt(^M^J'Message editing (^5?^4=^5Help^4) : ');
								if (MsgSysOp) then
									onek(cmd[1],'?VPRAFTSEODQ'^M)
								else
									onek(cmd[1],'?FTSEODQ'^M);
								nl;
								case cmd[1] of
									'?':begin
												lcmds(15,5,'From', 'To');
												lcmds(15,5,'Subject', 'Edit text');
												lcmds(15,5,'Oops', 'Display header');
												if (MsgSysOp) then
													begin
														lcmds(15,5,'Permanent', 'Validation');
														lcmds(15,5,'Rescan', 'Anonymous');
													end;
												lcmds(15,5,'Quit','');
											end;
									'D':for i:=1 to 5 do
												printacr(headerline(mheader,msg_on,himsg,i));
									'O':if pynq('Reload old information? ') then
												loadheader(msg_on,mheader);
									'E':begin
												editmessage(msg_on);
												loadheader(msg_on,mheader);
											end;
									'S':if (mheader.fileattached = 0) or (MsgSysOp) then
												inputdefault(mheader.subject, mheader.subject, 40, 'C', TRUE)
											else
												print('Sorry, you can''t edit that.^M^J');
									'T':begin
												prt('Edit name (P)osted to, (R)eal name, (S)ystem name : ');
												onek(cmd[1],'PRS'^M);
												case cmd[1] of
													'P':inputdefault(mheader.mto.as,mheader.mto.as,36,'',TRUE);
													'R':inputdefault(mheader.mto.real,mheader.mto.real,36,'',TRUE);
													'S':inputdefault(mheader.mto.name,mheader.mto.name,36,'',TRUE);
												end;
											end;
									'F':if (mheader.from.anon > 0) or (MsgSysOp) then
											begin
												prt('Edit name (P)osted as, (R)eal name, (S)ystem name : ');
												onek(cmd[1],'PRS'^M);
												case cmd[1] of
													'P':inputdefault(mheader.from.as,mheader.from.as,36,'',TRUE);
													'R':inputdefault(mheader.from.real,mheader.from.real,36,'',TRUE);
													'S':inputdefault(mheader.from.name,mheader.from.name,36,'',TRUE);
												end;
											end
											else
												print('Sorry, you can''t edit that.^M^J');
									'A':begin
												if (mheader.from.anon in [1,2]) then
													mheader.from.anon:=0
												else begin
													i:=mheader.from.usernum;
													loadurec(u,i);
													b:=aacs1(u,i,general.csop);
													if (b) then mheader.from.anon:=2 else mheader.from.anon:=1;
												end;
												if (mheader.from.anon=0) then s:='not '
													 else s:='';
												s:='Message is '+s+'anonymous';
												print(s);
												sysoplog(s);
											end;
									'R':if (MsgSysOp) then begin
												if (sent in mheader.status) then
													begin
														mheader.status:=mheader.status-[sent];
														if not (mbscanout in memboard.mbstat) then
															UpdateBoard;
														s:='not ';
													end
												else
													begin
														mheader.status:=mheader.status+[sent];
														s:='';
													end;
												s:='Message '+s+'marked as scanned.';
												print(s);
												sysoplog(s);
											end;
									'P':if (MsgSysOp) then begin
												if (permanent in mheader.status) then begin
													mheader.status:=mheader.status-[permanent];
													s:='not ';
													s1:='un';
												end else begin
													mheader.status:=mheader.status+[permanent];
													s:='';
													s1:='';
												end;
												s:='Message is '+s+'permanent.';
												print(s);
												sysoplog(s);
											end;
									'V':begin
												if (unvalidated in mheader.status) then begin
													s:='';
													mheader.status:=mheader.status-[unvalidated];
												end else begin
													s:='un';
													mheader.status:=mheader.status+[unvalidated];
												end;
												print(^M^J'Message '+s+'validated.'^M^J);
												sysoplog('* '+s+'validated '+mheader.subject);
											end;
								end;
							until (cmd[1] in ['Q',^M]) or (hangup);
							saveheader(msg_on,mheader);
						end;
				6:begin
						dumpquote(mheader);
						nl;
						if (prvt in mheader.status) then dyny := TRUE;
						if (mheader.from.anon = 0) or (aacs(general.anonpubread)) then
							if pynq('Is this to be a private reply? ') then
								if (mbprivate in memboard.mbstat) then
									if pynq('Reply in Email? ') then
										autoreply(mheader)
									else
										Post(msg_on,mheader.from,TRUE)
								else
									autoreply(mheader)
							else
								Post(msg_on,mheader.from,FALSE)
						 else
							 Post(msg_on,mheader.from,FALSE);
					 end;
				7:begin
						Msg_On := himsg + 1;
						loadheader(himsg, mheader);
						if (mheader.date <= getpackdatetime) then
							TempLastRead := Mheader.Date;
					end;
				8:if (msg_on - mheader.replyto > 0) and (mheader.replyto > 0) then
							begin
								if (threadstart = 0) then
									threadstart := msg_on;
								dec(Msg_On, mheader.replyto);
							end;
				9:if ((threadstart > 0) and (threadstart <= himsg)) then
						begin
							Msg_On := threadstart;
							threadstart := 0;
						end;
			 10:begin
						contlist:=TRUE; abort:=FALSE;
						print(^M^J'Continuous message listing on.'^M^J);
					end;
			 11:if (permanent in mheader.status) then
						 print(^M^J'This is a permanent message.'^M^J)
					else
						begin
							if (msg_on > 0) and (msg_on <= himsg) and
								(MsgSysOp or FromYou(mheader)) then
								begin
									loadheader(Msg_On, mheader);
                  if (mdeleted in mheader.status) then
                    mheader.status := mheader.status - [mdeleted]
                  else
                    mheader.status := mheader.status + [mdeleted];
                  saveheader(Msg_On, mheader);
                  if not (mdeleted in mheader.status) then
										begin
                      if FromYou(mheader) then
                        begin
                          if (thisuser.msgpost < 65535) then inc(thisuser.msgpost);
                          AdjustBalance(General.CreditPost);
                        end;
											print(^M^J'Undeleted message.');
											sysoplog('* Undeleted '+mheader.subject);
										end
									else
										begin
                      if FromYou(mheader) then
                        begin
                          if (thisuser.msgpost > 0) then dec(thisuser.msgpost);
                          AdjustBalance(-General.CreditPost);
                        end;
											print(^M^J'Deleted message.');
											sysoplog('* Deleted '+mheader.subject);
										end;
									nl;
								end
							else
								print(^M^J'That isn''t your message.'^M^J);
					 end;
			 12:begin
						print(^M^J'Highest-read pointer for this base set to message #'+
									cstr(msg_on)+'.'^M^J);
						if (mheader.date <= getpackdatetime) then
							TempLastRead := Mheader.Date;
					end;
			 13:DoneScan := TRUE;
			 14:begin
						DoneScan := TRUE;
						Quit := TRUE;
					end;
			 15:ListMessages;
			 16:if (CoSysOp) and CheckPw then
						if lastauthor <> 0 then
							uedit(lastauthor)
						else
							uedit(1);
       17:if not (mbforceread in memboard.mbstat) then begin
						if ToggleNewScan then
							begin
								s:='will NOT';
								s1:='out of';
							end
						else
							begin
								s:='WILL';
								s1:='back in';
							end;
						sysoplog('* Toggled ^5'+memboard.name+'^1 '+s1+' new scan.');
						print(^M^J'^5'+memboard.name+'^3 '+s+' be scanned in future new scans.'^M^J);
          end
        else
          print('^5' + memboard.name + '^3 cannot be removed from your newscan.');
				18:inc(Msg_On); { Next }
			end;
		until (treadprompt in [1..2,7..10,13..15,18]) or (abort) or (next) or (hangup)
	else
		inc(Msg_On);

	if (OneOnly) and (treadprompt in [13,14,18]) then
		DoneScan := TRUE;

	until (DoneScan) or (HangUp);

	AllowContinue := FALSE;
	curmenu := Old_menu;
	newmenutoload := TRUE;

	if ((HadUnval) and (MsgSysOp)) then
		begin
			nl;
			if pynq('Validate messages here? ') then
				begin
					reset(msghdrf);
					for i:=1 to HiMsg do
						begin
							loadheader(i,mheader);
							if (unvalidated in mheader.status) then
								mheader.status:=mheader.status-[unvalidated];
							saveheader(i,mheader);
						end;
					close(msghdrf);
				end;
		end;
	if ((AskPost) and (aacs(memboard.postacs)) and
		 (not (rpost in thisuser.flags)) and (ptoday<general.maxpubpost)) then
		begin
			nl;
			if (treadprompt <> 7) then
				if pynq('Post on ^5'+memboard.name+'^7? ') then
						if (mbprivate in memboard.mbstat) then
							Post(-1,mheader.from,pynq('Is this to be a private message? '))
						else
							Post(-1,mheader.from,FALSE);
		end;
end;

procedure ReadMessages;
var
		i:integer;
		s:astr;
		quit:boolean;
		OldActivity:byte;
begin
	initboard(board);
	OldActivity := update_node(3);
	nl;
	if (HiMsg = 0) then
		print('No messages on ^5'+memboard.name+'^1.')
	else
		begin
			prompt(^M^J + fstring.readq);
			scaninput(s,'Q');
			i := value(s);
			Msg_On := 1;
			if (i < 1) then
				i := 0
			else
				if (i <= HiMsg) then
					Msg_On := i;
			TempLastRead := LastMsgRead;

			if (s <> 'Q') then
				MainRead(quit,FALSE);

			SaveLastRead(TempLastRead);

	end;
	update_node(OldActivity);
end;

function firstnew:word;
var
	done:boolean;
	MaxMsgs,cn,i:integer;
	mheader:mheaderrec;
begin
	MaxMsgs := filesize(msghdrf);
	cn := 0;
	if (MaxMsgs > 0) then
		begin
			cn := 1;
			done := FALSE;
			i := (MaxMsgs div 20) + 1;
			while not done do
				begin
					loadheader(cn,mheader);
					if not (LastMsgRead < mheader.date) then	{ LastMsgRead used instead
																											of TempLastRead 'cause it
																											won't matter here }
						begin
							if cn + i < MaxMsgs then
								inc(cn,i)
							else
								done:=TRUE;
						 end
					 else
						 begin
							 if (cn - i - 1) > 0 then
								 dec(cn,i + 1);
							 done:=TRUE;
						 end;
				end;
			loadheader(cn,mheader);
			while (cn < MaxMsgs) and not (LastMsgRead < mheader.date) do
				begin
					inc(cn);
					loadheader(cn,mheader);
				end;
			if not (LastMsgRead < mheader.date) then
				cn := 0;
		end;
	firstnew := cn;
end;

procedure ScanMessages(mstr:astr);
var
	c:char;
	CurrentMessage,CurrentBoard:integer;
	ScanFor:string[40];
	ScanNew, ScanGlobal, Quit:boolean;
	OldActivity:byte;

	procedure searchboard;
	var
		OldBoard:word;
		MsgHeader:mheaderrec;
		Match,
		Anyshown:boolean;
		Searched:string;
		TotalLoaded:longint;
	begin
		OldBoard := Board;
		if Board <> CurrentBoard then changeboard(CurrentBoard);
		if (Board = CurrentBoard) then
			begin
				initboard(Board);
				Anyshown := FALSE;
				prompt('^1Scanning ^5'+memboard.name+' #'+cstr(cmbase(Board))+'^1...');
				reset(msghdrf);
				reset(msgtxtf,1);
				if (IOResult <> 0) then
					exit;
				if ScanNew then
					CurrentMessage := Firstnew
				else
					CurrentMessage := 1;
				if (CurrentMessage > 0) and (filesize(msghdrf) > 0) then
				while (CurrentMessage <= filesize(msghdrf)) and (not quit) do
					begin
						loadheader(CurrentMessage, MsgHeader);
						Match:=FALSE;
						wkey;
						if abort then
							quit := TRUE;

						if (c in ['Y',^M]) then
							if ToYou(msgheader) then
								Match := TRUE;

						if (c in ['F','A']) then
							begin
								if (mbrealname in memboard.mbstat) then
									Searched := MsgHeader.From.Real
								else
									Searched := MsgHeader.From.As;
								if (Memboard.MbType = 0) then
									Searched := Searched;
								Searched := allcaps(usename(MsgHeader.From.Anon,Searched));
								if (pos(ScanFor,Searched) > 0) then
									Match := TRUE;
							end;

						if (c in ['T','A']) then
							begin
								 if (mbrealname in memboard.mbstat) then
									 Searched := MsgHeader.Mto.Real
								 else
									 Searched := MsgHeader.Mto.As;
								 if (Memboard.MbType = 0) then
									 Searched := Searched;
								 Searched := allcaps(usename(MsgHeader.Mto.Anon,Searched));
								 if (pos(ScanFor,Searched) > 0) then
									 Match := TRUE;
							end;

						if (c in ['S','A']) then
							if (pos(ScanFor,allcaps(MsgHeader.Subject)) > 0) then
								Match := TRUE;

						if (c = 'A') and (not Match) and (MsgHeader.TextSize > 0) and
							 (MsgHeader.Pointer - 1 + MsgHeader.TextSize <= filesize(msgtxtf)) and
							 (MsgHeader.Pointer > 0) then
							 with MsgHeader do
							begin
								seek(msgtxtf,pointer-1);
								TotalLoaded := 0;
								repeat
									blockread(msgtxtf, Searched[0],1);
									blockread(msgtxtf, Searched[1],ord(Searched[0]));
									Lasterror := IOResult;
									inc(TotalLoaded,length(Searched)+1);
									if (pos(ScanFor,allcaps(Searched)) > 0) then
										Match := TRUE;
								until (TotalLoaded >= textsize) or (Match);
							end;

						if Match then
							begin
								close(msghdrf);
								close(msgtxtf);
								Msg_On := CurrentMessage;
								MainRead(Quit, TRUE);
								nl;
								reset(msghdrf);
								reset(msgtxtf,1);
								AnyShown := TRUE;
							end;
						inc(CurrentMessage);
					end;
				close(msghdrf);
				close(msgtxtf);
			end; {if board=currentboard}
			if (not AnyShown) then
				BackErase(14 + lennmci(memboard.name) + length(cstr(cmbase(Board))));
			board := OldBoard;
			abort := quit;
	end; {searchboard}

begin
	ScanNew := FALSE; ScanGlobal := FALSE;
	OldActivity := update_node(3);
	mstr := AllCaps(mstr);

	if (mstr <> '') then
		c := 'Y'
	else
		c := #0;

	if (pos('N',mstr) > 0) then
		ScanNew := TRUE;

	if (pos('G',mstr) > 0) then
		ScanGlobal := TRUE;

	if (c = #0) then
		repeat
			prt(^M^J'Scan method (^5?^4=^5Help^4) : ');
			onek(c,'FTSAY?Q'^M);
			if (c = '?') then
				begin
					nl;
					lcmds(15,5,'From field','To field');
					lcmds(15,5,'Subject field','All text');
					lcmds(15,5,'Your messages','Quit');
				end;
    until (c <> '?') or (hangup);
	nl;
  if (c <> 'Q') and (c <> ^M) then
		begin
      if (c <> 'Y') then
				begin
					prt('Text to scan for : ');
					input(ScanFor,40);
					if ScanFor = '' then exit;
					nl;
				end;
			if (mstr = '') then
				begin
					dyny := TRUE;
					ScanNew := pynq('Scan new messages only? ');
				end;
			quit := FALSE;
			abort := FALSE;
			if (ScanGlobal) or ((mstr = '') and pynq('Global scan? ')) then
				begin
					CurrentBoard:=1;
					repeat
						if (cmbase(CurrentBoard) > 0) then
							SearchBoard;
						inc(CurrentBoard);
						wkey;
					until ((CurrentBoard > MaxMBases) or (quit) or (abort) or (hangup));
				end
			else
				begin
					CurrentBoard := Board;
					SearchBoard;
				end;
		end;
	update_node(OldActivity);
end;

procedure ScanYours;
var
	oldboard:integer;
	found:integer;
	CurrentMessage:integer;
	CurrentBoard:integer;
	MsgHeader:mheaderrec;
	OldConf,AnyFound:boolean;
	FoundMap:array[0..127] of set of 0..7;
	s:string[20];
begin
	fillchar(foundmap, sizeof(foundmap), 0);
	oldboard := board;
	CurrentBoard := 1;
	abort := FALSE;
	AnyFound := FALSE;
	OldConf := ConfSystem;
	ConfSystem := FALSE;
	if oldconf then
		newcomptables;
	print(^M^J'Scanning for your new messages...'^M^J);
	repeat
		if (cmbase(CurrentBoard) > 0) then
			if Board <> CurrentBoard then changeboard(CurrentBoard);
				if (Board = CurrentBoard) then
					begin
						initboard(Board);
						Found := 0;
						if (NewScanMBase) then
							begin
								reset(msghdrf);
								reset(msgtxtf, 1);
								if (IOResult = 0) then
									begin
										str(trunc(Board / MaxMBases * 100):3,s);
										prompt(^H^H^H^H + s + '%');
										CurrentMessage := Firstnew;
										if (CurrentMessage > 0) and (filesize(msghdrf) > 0) then
										while (CurrentMessage <= filesize(msghdrf)) and (not abort) do
											begin
												loadheader(CurrentMessage, MsgHeader);
												if ToYou(msgheader) then
													begin
														inc(Found);
														FoundMap[CurrentBoard div 8] := FoundMap[CurrentBoard div 8] +
															[CurrentBoard mod 8];
													end;
												inc(CurrentMessage);
											end;
										close(msghdrf);
										close(msgtxtf);
									end;
								if (Found > 0) then
									begin
										print(^H^H^H^H + mln(memboard.name, 30) + ' ^1' + cstr(Found));
										AnyFound := TRUE;
									end;
							end;
					end;
		inc(CurrentBoard);
		wkey;
	until (CurrentBoard > MaxMBases) or (abort) or (hangup);
	if (not abort) and (not hangup) then printacr(^H^H^H^H + '100%');
	board := oldboard;
	if AnyFound and pynq(^M^J'Read these now? ') then
		for Board := 1 to MaxMBases do
			if (Board mod 8) in FoundMap[Board div 8] then
				begin
					ScanMessages('N');
					if abort then break;
					if pynq('Update message read pointers on this base? ') then
						SaveLastRead(getpackdatetime);
				end
			else
	else
    if (not AnyFound) then
      print('No messages found.'^M^J);
	confsystem:=oldconf;
	if oldconf then
		newcomptables;
    board := oldboard;
	Lasterror := ioResult;
end;

procedure NewScan(b:integer; var quit:boolean);
var
		oldboard:word;
begin
	if (not quit) then begin
		oldboard := board;
		if (board<>b) then changeboard(b);
		if (board = b) then begin
			nl;
			initboard(board);
			TempLastRead := LastMsgRead;
			lil := 0;
			prompt('^3'+fstring.newscan1);
			Lasterror := IOResult;
			reset(msghdrf);
      if (IOResult = 2) then
				rewrite(msghdrf);
			Msg_On := firstnew;
			close(msghdrf);
			if (Msg_On > 0) then
				MainRead(quit,FALSE);
			if (not quit) then
				begin
					lil:=0;
					prompt(fstring.newscan2);
				end;
		end;
		wkey;
		if abort then quit:=TRUE;
		SaveLastRead(TempLastRead);
		board := oldboard;
		initboard(board);
	end;
end;

procedure GlobalNewScan;
var
	bb:integer;
	quit:boolean;
begin
	sysoplog('Newscan of message bases');
	print(^M^J + fstring.newscanall);
	bb := 1;
	quit := FALSE;
	repeat
		if (cmbase(bb) > 0) then
			begin
				initboard(bb);
				if (NewScanMBase) or ((mbforceread in memboard.mbstat) and (not CoSysOp)) then
					NewScan(bb,quit);
			end;
		inc(bb);
	until ((bb > MaxMBases) or (quit) or (hangup));
	print(^M^J + fstring.newscandone);
end;

procedure StartNewScan(var mstr:astr);
begin
	update_node(3);
	abort:=FALSE; next:=FALSE;
	if (upcase(mstr[1])='C') then NewScan(board,next)
	else if (upcase(mstr[1])='G') then GlobalNewScan
	else if (value(mstr)<>0) then NewScan(value(mstr),next)
	else begin
		nl;
		if pynq('Global NewScan? ') then
			GlobalNewScan
		else
			NewScan(board,next);
	end;
	update_node(0);
end;

end.
