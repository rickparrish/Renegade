{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit mail0;

interface

uses crt, dos, overlay, common, timefunc;

procedure updateboard;
procedure extract(var x:longint);
procedure dumpquote(var mheader:mheaderrec);
procedure loadheader(x:word; var mhead:mheaderrec);
procedure saveheader(x:word; var mhead:mheaderrec);
procedure initboard(x:integer);
procedure readmsg(anum,mnum,tnum:word);
function headerline(var mhead:mheaderrec; mnum,tnum:word; line:byte):string;
procedure SaveLastRead(LastReadDate:longint);
function ToggleNewScan:boolean;
function ToYou(var MessageHeader:mheaderrec) : boolean;
function FromYou(var MessageHeader:mheaderrec) : boolean;

implementation

uses file0,sysop4, file8, file2, ShortMsg;

function FromYou(var MessageHeader:mheaderrec) : boolean;
begin
	if (MessageHeader.From.UserNum = Usernum) or
		 (Allcaps(MessageHeader.From.As) = thisuser.name) or
		 (Allcaps(MessageHeader.From.Name) = thisuser.name) or
		 (Allcaps(MessageHeader.From.As) = allcaps(thisuser.realname)) then
		FromYou := TRUE
	else
		FromYou := FALSE;
end;

function ToYou(var MessageHeader:mheaderrec) : boolean;
begin
	if (MessageHeader.Mto.UserNum = Usernum) or
		 (Allcaps(MessageHeader.Mto.As) = thisuser.name) or
		 (Allcaps(MessageHeader.Mto.Name) = thisuser.name) or
		 (Allcaps(MessageHeader.Mto.As) = allcaps(thisuser.realname)) then
		ToYou := TRUE
	else
		ToYou := FALSE;
end;

procedure updateboard;
var
	fo:boolean;
begin
	if (ReadBoard < 1) or (ReadBoard > MaxMBases) then exit;

	fo := (filerec(MBasesFile).mode <> fmclosed);
	if not fo then
		begin
			reset(MBasesFile);
			if (IOResult > 0) then
				begin
					sysoplog('error opening MBASES.DAT');
					exit;
				end;
		end;

	seek(MBasesFile, ReadBoard - 1);
	read(MBasesFile, memboard);
	memboard.mbstat := memboard.mbstat + [mbscanout];
	seek(MBasesFile, ReadBoard - 1);
	write(MBasesFile, memboard);

	if (IOResult > 0) then
		sysoplog('error saving message base ' + cstr(ReadBoard));

	if not fo then
		begin
			close(MBasesFile);
			if (IOResult > 0) then
				sysoplog('error closing MBASES.DAT');
		end;
end;

function ToggleNewScan:boolean;
var
	LastReadRecord:scanrec;
	Index:integer;
begin
	reset(msgscnf);
	Lasterror := IOResult;

	if (Usernum > filesize(msgscnf)) then 	{ was Usernum - 1 >= }
		begin
			LastReadRecord.LastRead := 0;
			LastReadRecord.NewScan := TRUE;
			seek(msgscnf, filesize(msgscnf));
			for Index := filesize(msgscnf) to Usernum - 2 do
				write(msgscnf, LastReadRecord);
		end
	else
		begin
			seek(msgscnf, Usernum - 1);
			read(msgscnf, LastReadRecord);
			seek(msgscnf, Usernum - 1);
		end;

	ToggleNewScan := LastReadRecord.NewScan;
	LastReadRecord.NewScan := not LastReadRecord.NewScan;
	NewScanMBase := LastReadRecord.NewScan;
	write(msgscnf, LastReadRecord);
	close(msgscnf);

	Lasterror := IOResult;
end;

procedure SaveLastRead(LastReadDate:longint);
var
	LastReadRecord:scanrec;
	Index:integer;
begin
	reset(msgscnf);
	Lasterror := IOResult;
	if (Usernum > filesize(msgscnf)) then 	{ was Usernum - 1 >= }
		begin
			LastReadRecord.LastRead := 0;
			LastReadRecord.NewScan := TRUE;
			seek(msgscnf, filesize(msgscnf));
			for Index := filesize(msgscnf) to Usernum - 2 do
				write(msgscnf, LastReadRecord);
		end
	else
		begin
			seek(msgscnf, Usernum - 1);
			read(msgscnf, LastReadRecord);
			seek(msgscnf, Usernum - 1);
		end;

	LastReadRecord.LastRead := LastReadDate;
	LastMsgRead := LastReadDate;
	write(msgscnf, LastReadRecord);
	close(msgscnf);
	Lasterror := IOResult;
end;

procedure loadheader(x:word; var mhead:mheaderrec);
var
	fo:boolean;
begin
	fo := filerec(msghdrf).mode <> fmclosed;
	if not fo then
		begin
			reset(msghdrf);
      if (IOResult = 2) then
				begin
					rewrite(msghdrf);
					if (IOResult <> 0) then
						begin
							sysoplog('error opening message file.');
							exit;
						end;
				end;
		end;

	seek(msghdrf,x-1);
	read(msghdrf,mhead);

	Lasterror := IOResult;

	if not fo then
		close(msghdrf);
end;

procedure saveheader(x:word; var mhead:mheaderrec);
var
	fo:boolean;
begin
	fo := filerec(msghdrf).mode <> fmclosed;
	if not fo then
		begin
			reset(msghdrf);
      if (IOResult = 2) then
				begin
					rewrite(msghdrf);
					if (IOResult <> 0) then
						begin
							sysoplog('error opening message file.');
							exit;
						end;
				end;
		end;

	seek(msghdrf,x-1);
	write(msghdrf,mhead);

	Lasterror := IOResult;

	close(msghdrf);

	if fo then
		reset(msghdrf);
end;

procedure initboard(x:integer); 	 { x=-1,0 = e-mail }
var
	LastReadRecord:scanrec;
begin
	loadboard(x);

	assign(msghdrf,general.msgpath+memboard.filename+'.HDR');
	assign(msgtxtf,general.msgpath+memboard.filename+'.DAT');

	if (x = -1) then
		exit;

	assign(msgscnf,general.msgpath+memboard.filename+'.SCN');
	reset(msgscnf);
  if (ioresult = 2) then
		rewrite(msgscnf);

	if (Usernum > filesize(msgscnf)) then  { was Usernum - 1 >= filesize }
		begin
			LastMsgRead := 0;
			NewScanMBase := TRUE;
		end
	else
		begin
			seek(msgscnf, Usernum - 1);
			read(msgscnf,LastReadRecord);
			LastMsgRead := LastReadRecord.LastRead;
			NewScanMBase := LastReadRecord.NewScan;
		end;
	close(msgscnf);
	Lasterror := IOResult;
end;

procedure dumpquote(var mheader:mheaderrec);
var t:text;
		totload:integer;
		s:string;
		s1,s2:string[80];
		dt:datetime;

begin
	if (mheader.textsize < 1) then exit;
	assign(t,'TEMPQ'+cstr(node));
	rewrite(t);
	if (IOResult <> 0) then
		begin
			sysoplog('error opening quote file.');
			exit;
		end;
	totload:=0;
	if (mbrealname in memboard.mbstat) then
		s := Caps(mheader.from.real)
	else
		s := Caps(mheader.from.as);

	for totload:=1 to 2 do begin
		s1:=fstring.quote_line[totload];
		s1:=substitute(s1,'@F',usename(mheader.from.anon,s));
		if (mbrealname in memboard.mbstat) then
			s2:=Caps(mheader.mto.real)
		else
			s2:=Caps(mheader.mto.as);
		s1:=substitute(s1,'@T',usename(mheader.mto.anon,s2));
		packtodate(dt,mheader.date);
		s2:=cstr(dt.day)+' '+copy(MonthString[dt.month],1,3)+' '+
				copy(cstr(dt.year),3,2)+'  '+Zeropad(cstr(dt.hour))+':'+Zeropad(cstr(dt.min));
		if mheader.origindate='' then s1:=substitute(s1,'@D',s2)
			 else s1:=substitute(s1,'@D',mheader.origindate);
		if (mheader.fileattached = 0) then
			s1:=substitute(s1,'@S',mheader.subject)
		else
			s1:=substitute(s1,'@S',stripname(mheader.subject));
		s1:=substitute(s1,'@B',memboard.name);
		if s1<>'' then writeln(t,s1);
	end;

	writeln(t);

	s1:=s[1];
	if (pos(' ',s) > 0) and (length(s) > pos(' ',s)) then
		s1 := s1 + s[pos(' ',s) + 1]
	else
		if (length(s1) > 1) then
			s1 := s1 + s[2];

	totload := 0;
	if (mheader.from.anon <> 0) then s1 := '';

	reset(msgtxtf,1);
	seek(msgtxtf,mheader.pointer-1);

	s1:=copy(s1,1,2);
	repeat
		blockread(msgtxtf,s[0],1);
		blockread(msgtxtf,s[1],ord(s[0]));
		Lasterror := IOResult;
		if (Lasterror <> 0) then
			begin
				sysoplog('error loading message text.');
				totload := mheader.textsize;
			end;
		inc(totload,length(s)+1);
		if (pos('> ',copy(s,1,4)) > 0) then
			s := copy(stripcolor(s),1,79)
		else
			s := copy(s1+'> '+stripcolor(s),1,79);
		writeln(t,s);
	until (totload>=mheader.textsize);
	close(t);
	close(msgtxtf);
	Lasterror := IOResult;
end;


procedure extract(var x:longint);
var t:text;
		totload:word;
		s:string;
		b:boolean;
		mheader:mheaderrec;

begin
		 prt(^M^J'Extract filename: ');
		 inputdefault(s,'MSG.TXT',40,'UL',TRUE);
		 if pynq('Are you sure? ') then begin
			 b:=pynq('Strip color codes from output? ');

			 loadheader(x,mheader);

			 assign(t,s);
			 append(t);

       if (ioresult = 2) then
				 begin
					 rewrite(t);
					 if (ioresult <> 0) then
						 begin
							 print('Cannot create file.');
							 exit;
						 end;
				 end;

			 for totload := 1 to 7 do
				 begin
					 s:=headerline(mheader,x,himsg,totload);
					 if s <> '' then writeln(t,stripcolor(s));
				 end;

			 writeln(t);

			 totload:=0;
			 reset(msgtxtf,1);
			 seek(msgtxtf,mheader.pointer-1);
			 repeat
					blockread(msgtxtf,s[0],1);
					blockread(msgtxtf,s[1],ord(s[0]));
					Lasterror := IOResult;
					if (Lasterror <> 0) then
						begin
							sysoplog('error loading message text.');
							totload := mheader.textsize;
						end;

					inc(totload,length(s)+1);
					if b then
						s:=stripcolor(s);
					if s[length(s)]=#29 then
						begin
							dec(s[0]);
							write(t,s);
						end
					else
						writeln(t,s);
				until (totload>=mheader.textsize);
				writeln(t);
				close(msgtxtf);
				close(t);
				print(^M^J'Message extracted.'^M^J);
		 end;
	 Lasterror := IOResult;
end;

function headerline(var mhead:mheaderrec; mnum,tnum:word; line:byte):string;
var
	pub,seeanon:boolean;
	s,s1:string;
	i:byte;
begin
	with mhead do begin
		pub:=(readboard<>-1);
		if (pub) then seeanon := (aacs(general.anonpubread) or MsgSysOp)
			else seeanon := aacs(general.anonprivread);

		if (from.anon = 2) then
			seeanon := CoSysOp;

		s:='';

		case line of
			1:begin
					if (fileattached > 0) then
						irt := stripname(subject)
					else
						irt:=subject;

					if ((from.anon = 0) or (seeanon)) then
						lastauthor := from.usernum
					else
						lastauthor := 0;

					if ((from.anon = 0) or (seeanon)) then
						s:=pdt2dat(date,dayofweek)
					else
						s:='[Unknown]';
					s:='^1Date: ^9'+s;
					s:=mln(s,39)+'^1Number : ^9'+cstr(mnum)+'^1 of ^9'+cstr(tnum);
				end;
			2:begin
					s1:=from.as;
					if (pub) and (mbrealname in memboard.mbstat) then
							s1:=from.real;
					s:='^1From: ^5'+caps(Usename(from.anon,s1));
					if (not pub) and (netmail in status) then
            begin
              s := s + '^2 (' + cstr(from.zone) + ':' +
                       cstr(from.net)  + '/' +
                       cstr(from.node);
              if (from.point > 0) then
                s := s + '.' + cstr(from.point);
              s := s + ')';
            end;

					s:=mln(s,38)+'^1 Base   : ^5';
					if (lennmci(memboard.name) > 30) then
						s := s + mln(memboard.name,30)
					else
						s := s + memboard.name;
				end;
			3:begin
					if (pub) and (mbrealname in memboard.mbstat) then
						s1:=caps(mto.real)
					else
						s1:=caps(mto.as);
					s:='^1To  : ^5'+Usename(mto.anon, s1);
					if (not pub) and (netmail in status) then
            begin
              s := s + '^2 (' + cstr(mto.zone) + ':' +
                       cstr(mto.net)  + '/' +
                       cstr(mto.node);
              if (mto.point > 0) then
                s := s + '.' + cstr(mto.point);
              s := s + ')';
             end;
					s:=mln(s,38)+'^1 Refer #: ^5';
					if (replyto > 0) and (replyto < mnum) then
						s:=s+cstr(mnum - replyto)
					else
						s:=s+'None';
				end;
			4:begin
					s:='^1Subj: ';
					if (fileattached = 0) then
						s := s + '^5' + subject
					else
						s := s + '^8' + stripname(subject);

					s:=mln(s,38)+'^1 Replies: ^5';

					if (replies<>0) then
						s:=s+cstr(replies)
					else
						s:=s+'None';
				end;
			5:begin
					s:='^1Stat: ^';
					if (mdeleted in status) then
						s:=s+'8Deleted'
					else
					if (prvt in status) then
						s:=s+'8Private'
					else
						if (unvalidated in status) then
							s:=s+'8Unvalidated'
						else
							if ((pub) and (permanent in status)) then
								s:=s+'5Permanent'
							else
								if (memboard.mbtype<>0) then
									if (sent in status) then
										s:=s+'5Sent'
									else
										s:=s+'5Unsent'
							 else
								s:=s+'5Normal';

					if (not pub) and (netmail in status) then s:=s+' Netmail';

					s:=mln(s,39)+'^1Origin : ^5';
					if (origindate<>'') then
						s:=s+origindate
					else
						s:=s+'Local';
				end;
			6:begin
					if ((seeanon) and ((mto.anon + from.anon) > 0) and (memboard.mbtype = 0)) then
						begin
							s:='^1Real: ^5';
							if (mbrealname in memboard.mbstat) then
								s:=s+caps(from.real)
							else
								s:=s+caps(from.name);
							s:=s+'^1 to ^5';
							if (mbrealname in memboard.mbstat) then
								s:=s+caps(mto.real)
							else
								s:=s+caps(mto.name);
						end;
				end;
		end;
	end;
	headerline := s;
end;


{ anum=actual, mnum=M#/t# <-displayed, tnum=m#/T# <- max? }

procedure readmsg(anum,mnum,tnum:word);
var
	mheader:mheaderrec;
	s:string;
	totload,i:word;
	dok,kabort:boolean;
	tooktime:longint;
	f:file;
begin
	allowabort := (CoSysOp) or not (mbforceread in memboard.mbstat);

  AllowContinue := TRUE;

	with mheader do begin

		loadheader(anum,mheader);

    if ((mdeleted in status) or (unvalidated in status)) and
       not (CoSysOp or FromYou(mheader) or ToYou(mheader)) then exit;

		abort:=FALSE;
		next:=FALSE;

    for i := 1 to 6 do
			begin
				s:=headerline(mheader,mnum,tnum,i);
				if (i <> 2) then
					mciallowed := (allowmci in status); { allowit in base name }
				if s<>'' then printacr(s);
				mciallowed := TRUE;
			end;

		nl;
		reset(msgtxtf,1);
		if (IOResult <> 0) then
			begin
				sysoplog('error accessing message text.');
				Allowabort := TRUE;
				exit;
			end;

		if (not abort) then begin
			reading_a_msg:=TRUE;
			mciallowed:=(allowmci in status);
			totload:=0;
			abort:=FALSE;
			next:=FALSE;
			UserColor(memboard.text_color);
			if textsize>0 then
			if (pointer-1+textsize<=filesize(msgtxtf)) and
				 (pointer>0) then begin
					seek(msgtxtf,mheader.pointer-1);
					repeat
						blockread(msgtxtf,s[0],1);
						blockread(msgtxtf,s[1],ord(s[0]));
						Lasterror := IOResult;
						if (Lasterror <> 0) then
							begin
								sysoplog('error loading message text.');
								totload := mheader.textsize;
							end;
						inc(totload,length(s)+1);
						if (' * Origin: ' = copy(s,1,11)) then
							s := '^' + cstr(memboard.origin_color) + s
						else
							if ('---'=copy(s,1,3)) and ((length(s)=3) or (s[4]<>'-')) then
								s:='^'+cstr(memboard.tear_color)+s
							else
								if (pos('> ',copy(s,1,5)) > 0) then
									s:='^'+cstr(memboard.quote_color)+s+'^'+cstr(memboard.text_color)
								else
									if pos(#254,copy(s,1,5))>0 then
										s:='^'+cstr(memboard.tear_color)+s;
						 printacr(s);
					until (totload>=textsize) or (abort);
			end;
			mciallowed:=TRUE;
			reading_a_msg:=FALSE;
			if (dosansion) then redrawforansi;
		end;
		close(msgtxtf);
	end;

	Lasterror := IOResult;

  if (mheader.fileattached > 0) and exist(mheader.subject) then
		begin
      begin
        print(^M^J'^4The following has been attached:');
        findfirst(Mheader.Subject, AnyFile - Directory - VolumeID, DirInfo);
        if (Doserror = 0) then
          begin
            printacr(^M^J'^4Filename.Ext Bytes   hh:mm:ss');
            printacr('------------ ------- --------');
            i := 0;
            while (Doserror = 0) do
              begin
                printacr('^5' + align(Dirinfo.Name) + ' ^4' + mrn(cstr(DirInfo.Size), 7) +
                         ' ^7' + ctim(DirInfo.Size div Rate));
                findnext(DirInfo);
                inc(i, DirInfo.Size div Rate);
            end;
            nl;
            if (incom) and (i <= nsl) and pynq('Download now? ') then
              begin
                i := fileboard;
                fileboard := -1;
                send(Mheader.Subject, FALSE, FALSE, dok, kabort, false, tooktime);
                if dok and not kabort then
                  ssm(Mheader.From.UserNum, caps(thisuser.name) +
                      ' downloaded ' + stripname(Mheader.Subject));
                fileboard := i;
              end
            else
              if (not incom) and (CoSysOp) and (pynq('Move file(s)? ')) then
                begin
                  prt(^M^J'Enter path to move file(s) to: ');
                  input(s, 40);
                  if (s <> '') then
                    begin
                      s := s + stripname(Mheader.Subject);
                      if ((s[length(s)]) <> '\') then
                        s := s + '\';
                      movefile(dok, kabort, FALSE, Mheader.Subject, s);
                    end;
                end
              else
                if (incom) and (i > nsl) then
                  print('Insufficient time for download.'^M^J);
          end
        else
          print('Nothing.'^M^J);
      end;
		end;
	allowabort := TRUE;
  TempPause := (pause in thisuser.flags);
end;

end.
