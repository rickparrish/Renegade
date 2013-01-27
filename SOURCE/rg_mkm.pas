{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}
Unit Rg_Msg;
INTERFACE
uses
  dos, overlay, CommDec, common, rg_scan, rg_mbase,
  MkMsgJam;
{
Code: 3358
Data: 12

컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
Message Read Object 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
Functions that require a message base to be active in order to run
컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
}

TYPE
  MsgObj=Object(MsgBaseObj)
    ScanList:pMsgScanListObj;
    { The scan pointers }
    JamBase:JamMsgObj;
    BaseOpen:Boolean;
    { TRUE if base is open }
    MessageFound:Boolean;
    { May or may not be used }

    Constructor Init;
    Destructor  Done; virtual;

    Procedure SelectBase(Which:Word);
              { Picks em out of thousands }
    Procedure OpenBase;
              { Opens the base selected }
    Procedure DelBase;
              { Deletes the base selected }
    Procedure CloseBase;
              { Closes the base }
    Procedure CreateBase;
              { Makes the data files from current data }
    Procedure OpenMakeBase;
              { If there, opens, if not it creates base }
    Function  BaseExists(Which:Word):Boolean;
              { TRUE if base files exist }
    Function  ReturnMCI(Which:Str2):Str255;
              { Returns the info from the specified MCI code as a string }
    Procedure ShowOutboundMail;
              { Searches current base for mail from user, and allows user
                to edit/kill the message }
    Procedure MassMail;
              { Sends copies to multiple recpts in current base, only in
                PrivateOnly bases (email, Netmail)}
    Procedure NewscanBase(Idx:Word);
              { Newscans Idx }
    Procedure Newscan(Opt:Str1);
              { Opt: C, G }
    Procedure LoadMessage;
              { Loads message header and body }
    Procedure LoadMessageHeader;
              { Loads ONLY message header }
    Procedure LoadMessageBody;
              { Loads ONLY message body - Used when LoadMessageHeader is used }
    Procedure PostMessage;
              { Starts posting process }
    Procedure ReadMessages;
              { Reads messages starting from first avail }
    Procedure ScanMessages;
              { Scans for text by user selected options }
    Procedure ListUsers(Opt:Str1);
              { Lists users who meet ACS for Opt.  Opt:R=Read, P=Post, M=Mci }
    Procedure ToggleNewscan(Idx:Word);
              { Toggles newscan of specified base for online read }
    Procedure SetScanAreas;
              { Sets scan areas for online reading }
    Procedure ChangeBase(Idx:Word);
              { Change to base Idx }
    Procedure SetPointers;
              { Calls SetPointerDate based on user input }
    Procedure SetPointerDate(Dte:LongInt);
              { Set date/time of message pointers (UNIX Date) }
    Procedure DisplayMessage;
              { Displays the current message, calls DisplayMessageHdr and DisplayMessageBody }
    Procedure DisplayMessageHdr;
              { Displays the current message header }
    Procedure DisplayMessageBody;
              { Displays the current message body }
    Procedure PreviousMessage;
              { Moves to previous message with SeekPrior - Checks SeekFound }
    Procedure NextMessage;
              { Moves to next message with SeekNext - checks SeekFound }
    Procedure GotoMessage(Which:LongInt);
              { Goes to message specified, not ABS message number }
    Procedure MoveMessage;
              { Moves message to another base }
    Procedure ExtractMessage;
              { Extracts message to a text file }
    Procedure EditMessage;
              { Reposts message to END of base }
    Procedure DeleteMessage;
              { Deletes the message }
    Procedure ReplyToMessage;
              { Replies to current message }
    Procedure IgnoreRemaining;
              { Ignores remaining messages in base }
    Procedure ThreadBack;
              { Search by thread backwards }
    Procedure ThreadForward;
              { Search by thread forward }
    Procedure SetContinuousRead;
              { Turns on continuous read of bases }

{*** Do we keep this function? }
    Procedure ToggleDelete;
              { Toggle Delete? - May delete function }

    Procedure ToggleFlag(Flag:LongInt);
              { Toggles specified flag in message }
    Procedure SetHighMessage;
              { Sets LastRead to this message }
    Procedure AdvanceBase;
              { Advances to next base without reading remaining messages }
    Procedure QuitReading;
              { Stops reading entirely }
    Procedure ListTitles;
              { List titles of messages from current to finish }
    Procedure ZapMessage;
              { Makes no receipt for user when in private only base }
    Procedure ForwardMessage;
              { Forwards message, leaves original undeleted, works in private
                only bases}
    Procedure Extract(Which:LongInt);
              { Extracts message to file }
  end;
  pMsgObj=^MsgObj;

{
컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
Message Read Object 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
}
IMPLEMENTATION

Uses Rg_OFile;

CONST
  JamWorkBufSize=512;

Procedure NotDone(Const S:Astr);
begin
  Prt('* '+S+' is not implemented yet');
  SysopLog('* '+S+' is not implemented yet');
end;


Constructor MsgObj.Init;
begin
  Inherited init;
  New (ScanList, Init);
  if (ScanList=NIL) then
    Fail;

  JamBase.Init;
  BaseOpen := FALSE;
  MessageFound := FALSE;

end;

Destructor  MsgObj.Done;
begin
  JamBase.Done;
  Dispose(ScanList, Done);
end;

Procedure MsgObj.SelectBase(Which:Word);
begin
  GoToBase(Which);
  JamBase.SetMsgPath(General.DataPath+Data.FileName);
end;

Procedure MsgObj.OpenBase;
begin
  if (JamBase.OpenMsgBase <> 0) then
    begin
      SysopLog('* Unable to open base: '+data.filename);
      SetOk(FALSE);
    end;
  if Ok then BaseOpen := TRUE;
end;

Procedure MsgObj.DelBase;
begin
  JamBase.CloseMsgBase;
  DeleteBase(Currentbase);
end;

Procedure MsgObj.CloseBase;
begin
  JamBase.CloseMsgBase;
  BaseOpen := FALSE;
end;

Procedure MsgObj.CreateBase;
begin
  NotDone('CreateBase');
end;

Procedure MsgObj.OpenMakeBase;
begin
  if BaseExists(CurrentBase) then
    OpenBase
  else
    CreateBase;
end;

Function  MsgObj.BaseExists(Which:Word):Boolean;
begin
  BaseExists := JamBase.MsgBaseExists;
end;

Function  MsgObj.ReturnMCI(Which:Str2):Str255;
              { Returns the info from the specified MCI code as a string }
VAR
  CloseIt:Boolean;
begin
  CloseIt := Not(BaseOpen);
  if CloseIt then
    OpenMakeBase;

  Which := AllCaps(Which);
  Case Which[1] of
      'M' : begin
              Case Which[2] of
                '#' : ReturnMCI := cStr(CmBase(CurrentBase));
                { Message Base number }
                'B' : ReturnMCI := Data.Name;
                { Message Base name }
                'R' : ReturnMCI := cStr(JamBase.NumberOfMsgs-JamBase.GetLastRead(UserNum));
                { Messages remaining to read }
              end;
            end;
      'H' : begin
              Case Which[2] of
                'M' : ReturnMCI := cStr(JamBase.NumberOfMsgs);
                { Highest message available }
              end;
            end;
      'C' : begin
              Case Which[2] of
                'M' : ReturnMCI := cStr(JamBase.GetHighMsgNum);
                { Current Message number }
              end;
            end;
  end;
  if CloseIt then
    CloseBase;
end;

Procedure MsgObj.ShowOutboundMail;
              { Searches current base for mail from user and presents one by
                one to kill }
VAR
  I, J : LongInt;
  C:Char;
  Finished:Boolean;
  U:UserRec;
  AnyFound:Boolean;
  SavedBase:Word;
  CurMessage:LongInt;
  iFile:rgfileobj;
begin

  CurMessage := JamBase.GetLastRead(UserNum);
  readingmail:=TRUE; Finished:=FALSE; abort := FALSE;
  nl;
  i:=1; c:=#0;
  anyfound := FALSE;
  while ((i <= JamBase.NumberOfMsgs) and (not Finished) and (not hangup)) do
  begin
    Jambase.YoursFirst(ThisUser.RealName, ThisUser.Name);

    if JamBase.YoursFound then
    begin
      LoadMessage;
      DisplayMessage;
    end
    else
    begin
      if (c<>'?') then
        begin
          LoadMessage;
          cls;
          nl;
        end;
      prt('Outgoing mail (?=help) : '); onek(c,'QDENPRX?'^M^N);
      case c of
        '?':begin { What commands are available }
              print(^M^J'<^3CR^1>Next message');
              lcmds(20,3,'Re-read message','Edit message');
              lcmds(20,3,'Delete message','Previous message');
              if CoSysOp then
                lcmds(20,3,'Xtract to file','Quit')
              else
                print('<^3Q^1>uit');
              nl;
            end;
        'R':begin { Re-Read the message }
              DisplayMessage;
            end;

        'P':begin { Seek your previous message }
              NotDone('Seek Previous Message');
            end;
        'Q':finished:=TRUE;
        'X':if (MsgSysOp) then extract(i);
        'E':editmessage;
        'D':begin
              DeleteMessage;
            end;

      else
        begin
          JamBase.YoursNext;
        end;
      end;
    end;
  end;

  if (not AnyFound) then
    print('^3No outgoing messages.');
  readingmail:=FALSE;

  CurrentBase := SavedBase;
end;

Procedure MsgObj.MassMail;
              { Sends copies to multiple recpts in current base, only in
                PrivateOnly bases (email, Netmail)}
begin
end;

Procedure MsgObj.NewscanBase(Idx:Word);
              { Newscans Idx }
VAR
  MsgAt:LongInt;
begin
  GotoBase(Idx);
  MsgAt := JamBase.GetLastRead(UserNum-1);
  JamBase.SeekFirst(MsgAt);
  if JamBase.SeekFound then
    ReadMessages;
end;

Procedure MsgObj.Newscan(Opt:Str1);
              { Opt: C, G }
begin
  if caps(opt[1]) = 'C' then
  begin { Current Base }
    NewScanBase(CurrentBase);
  end
  else
  begin { Global }
  end;
end;

Procedure MsgObj.LoadMessage;
              { Loads message header and body }
begin
  NotDone('LoadMessage');
end;

Procedure MsgObj.LoadMessageHeader;
              { Loads ONLY message header }
begin
  NotDone('LoadMessageHeader');
end;

Procedure MsgObj.LoadMessageBody;
              { Loads ONLY message body - Used when LoadMessageHeader is used }
begin
  NotDone('LoadMessageBody');
end;


Procedure MsgObj.PostMessage;
              { Starts posting process }
begin
end;

Procedure MsgObj.ReadMessages;
              { Reads messages starting from first avail }
begin
end;

Procedure MsgObj.ScanMessages;
          { Scans for text by user selected options }
begin
end;

Procedure MsgObj.ListUsers(Opt:Str1);
          { Lists users who meet ACS for Opt.  Opt:R=Read, P=Post, M=Mci }
begin
{  if aacs(acsstring) = true, then user has access }
  Case Opt[1] of
    'R': ;
    'P': ;
    'M': ;
  end;
end;

Procedure MsgObj.ToggleNewscan(Idx:Word);
              { Toggles newscan of specified base for online read }
begin
  ScanList^.SelectUser(UserNum);
  ScanList^.SelectBase(General.MsgPath+Data.FileName);
  ScanList^.ToggleBase;
end;

Procedure MsgObj.SetScanAreas;
              { Sets scan areas for online reading }
begin
end;

Procedure MsgObj.ChangeBase(Idx:Word);
              { Change to base Idx }
begin
  GotoBase(Idx);
end;

Procedure MsgObj.SetPointers;
              { Calls SetPointerDate based on user input }
begin
end;

Procedure MsgObj.SetPointerDate(Dte:LongInt);
              { Set date/time of message pointers (UNIX Date) }
begin
end;

Procedure MsgObj.DisplayMessage;
begin
  DisplayMessageHdr;
  DisplayMessageBody;
end;

Procedure MsgObj.DisplayMessageHdr;
begin

end;

Procedure MsgObj.DisplayMessageBody;
begin
end;


Procedure MsgObj.PreviousMessage;
begin
end;

Procedure MsgObj.NextMessage;
begin
end;

Procedure MsgObj.GotoMessage(Which:LongInt);
              { Goes to message specified, not ABS message number }
begin
end;

Procedure MsgObj.MoveMessage;
begin
end;

Procedure MsgObj.ExtractMessage;
begin
end;

Procedure MsgObj.EditMessage;
              { Reposts message to END of base }
begin
end;

Procedure MsgObj.DeleteMessage;
  Var
    UserNumber : Word;
    U          : UserRec;
begin
  if not(JamBase.IsDeleted) then
  begin
    if (Data.mbtype=4) then { Is it Email? }
    begin
      UserNumber := SearchUser(JamBase.GetTO, TRUE);
      LoadURec(u, UserNum);
      if (U.Waiting > 0) then
        Dec(U.Waiting); { Remove the message from the count }
      SaveURec(U, userNum);
    end;
    JamBase.DeleteMsg;
    JamBase.RewriteHdr;
    SysopLog('* Deleted mail to ' + Jambase.GetTo);
    print('Mail deleted');
  end
  else
  begin
    (*
    if (Data.basetype=4) then { Is it Email? }
    begin
      UserNumber := SearchUser(JamBase.GetTO, TRUE);
      LoadURec(u, UserNumber);
      if (U.Waiting > 0) then
        inc(U.Waiting); { Remove the message from the count }
      SaveURec(U, userNumber);
    end;
    JamBase.NoUndeletFunction;
    JamBase.Rewritehdr;
    SysopLog('Mail undeleted.');
    *)
    NotDone('Message Undelete Function');
  end;
end;


Procedure MsgObj.ReplyToMessage;
              { Replies to current message }
begin
end;

Procedure MsgObj.IgnoreRemaining;
              { Ignores remaining messages in base }
begin
end;

Procedure MsgObj.ThreadBack;
begin
end;

Procedure MsgObj.ThreadForward;
begin
end;

Procedure MsgObj.SetContinuousRead;
begin
end;

Procedure MsgObj.ToggleDelete;
begin
end;

Procedure MsgObj.ToggleFlag(Flag:LongInt);
              { Toggles specified flag in message }
begin
end;

Procedure MsgObj.SetHighMessage;
              { Sets LastRead to this message }
begin
  JamBase.SetLastRead(UserNum, JamBase.GetMsgNum);
end;

Procedure MsgObj.AdvanceBase;
              { Advances to next base without reading remaining messages }
begin
end;

Procedure MsgObj.QuitReading;
              { Stops reading entirely }
begin
end;

Procedure MsgObj.ListTitles;
              { List titles of messages from current to finish }
begin
end;

Procedure MsgObj.ZapMessage;
              { Makes no receipt for user when in private only base }
begin
end;

Procedure MsgObj.ForwardMessage;
              { Forwards message, leaves original undeleted, works in private
                only bases}
begin
end;

procedure MsgObj.extract;
var t:text;
		totload:word;
		s:string;
		b:boolean;
		mheader:mheaderrec;

begin
(*
		 prt(^M^J'Extract filename: ');
		 inputdefault(s,'MSG.TXT',40,'UL',TRUE);
		 if pynq('Are you sure? ') then begin
			 b:=pynq('Strip color codes from output? ');

			 loadheader(x,mheader);

			 assign(t,s);
			 append(t);

			 if (ioresult <> 0) then
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
*)
end;


begin
end.


{ Use this to display a message! }
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

