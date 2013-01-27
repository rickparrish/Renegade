{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit mail6;

interface

uses crt, dos, overlay, common;

procedure editmessage(var i:longint);
procedure movemsg(x:word);
procedure doshowpackbases;
procedure packmessagebases;
procedure chbds;

implementation

uses mail0, mail1, mail7, msgpack, sysop3;

procedure editmessage(var i:longint);
var t:text;
		f:file;
		mheader:mheaderrec;
		s:string;
		fname:string[12];
		dfdt1,dfdt2,totload:longint;
		oldfileattach:byte;
begin

	loadheader(i,mheader);

	fname:='TEMPQ'+cstr(node)+'.MSG';
	reset(msgtxtf,1);

	assign(t,fname); rewrite(t);
  if (IOResult <> 0) then
		begin
			sysoplog('error editing message.');
			exit;
		end;
	totload:=0;
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
		writeln(t,s);
	until (totload>=mheader.textsize);
	close(t);

	getftime(t,dfdt1);
	close(msgtxtf);

	oldfileattach := mheader.fileattached;	{ yet another kludge }

	if not (InputMessage((ReadBoard <> -1), FALSE, '',mheader, fname)) then
    begin
      kill(fname);
      exit;
    end;

	mheader.fileattached := oldfileattach;

	assign(f,fname);
	getftime(f,dfdt2);

	if (dfdt1<>dfdt2) then begin
		assign(t,fname);
		reset(t);
		mheader.textsize:=0;
		reset(msgtxtf,1);
		mheader.pointer:=filesize(msgtxtf)+1;
		seek(msgtxtf,mheader.pointer-1);
		repeat
			readln(t,s);
      if (IOResult <> 0) then
				print('error reading edited text.');
			inc(mheader.textsize,length(s)+1);
			blockwrite(msgtxtf,s,length(s)+1);
		until (eof(t));
		close(msgtxtf);
		close(t);
		saveheader(i,mheader);
	end;
	Lasterror := IOResult;
	kill(fname);
end;

procedure movemsg(x:word);
var f:file;
		f2:file of mheaderrec;
		mheader:mheaderrec;
		s:astr;
		totload:longint;
		i,oldboard:integer;
		done,oconf:boolean;
begin
	nl;
	oconf := confsystem;
	confsystem := FALSE;
	oldboard := readboard;
	if oconf then newcomptables;
	if ((x>=0) and (x<=himsg)) then begin
		i:=0; done:=FALSE;
		repeat
			prt('Enter board #, (?)List, or (Q)uit : ');
			scaninput(s,'?Q'^M);
			if (s='Q') or (s=^M) or (s='') then
				done:=TRUE
			else
				if (s='?') then
					begin
						mbaselist(FALSE);
					end
			else
				begin
					i:=ambase(value(s));
					if ((i>=1) and (i<>readboard) and (i<=MaxMBases)) then
						done:=TRUE
					else
						print('Can''t move it there.');
				end;
		until ((done) or (hangup));
		if ((i>=1) and (i<=MaxMBases)) then begin
			if (mbaseac(i)) then begin
				initboard(oldboard);
				loadheader(x,mheader);

				loadboard(i);
				assign(f2,general.msgpath+memboard.filename+'.HDR');
				reset(f2);
        if (ioresult = 2) then rewrite(f2);

				assign(f,general.msgpath+memboard.filename+'.DAT');
				reset(f,1);
        if (ioresult = 2) then rewrite(f,1);

				seek(f2,filesize(f2));
				reset(msgtxtf,1);

				seek(msgtxtf,mheader.pointer-1);
				mheader.pointer:=filesize(f)+1;
				seek(f,filesize(f));
				mheader.status := mheader.status - [mdeleted];
				write(f2,mheader);
				close(f2);

				totload:=0;
				repeat
					blockread(msgtxtf,s[0],1);
					blockread(msgtxtf,s[1],ord(s[0]));
					Lasterror := IOResult;
					blockwrite(f,s,length(s)+1);
					inc(totload,length(s)+1);
				until (totload>=mheader.textsize);
				close(f);
				close(msgtxtf);

				initboard(oldboard);
				loadheader(x,mheader);
        mheader.status:=mheader.status+[mdeleted];
        saveheader(x, mheader);

        print(^M^J'Move successful.');
			end;
		end;
	end;
	Lasterror := IOResult;
	nl;
	confsystem := oconf;
	initboard(oldboard);
	if oconf then newcomptables;
end;

procedure doshowpackbases;
var tempboard:boardrec;
		i:integer;
begin
	TempPause := FALSE;

	sysoplog('Packed all message bases');
	nl;
	star('Packing all message bases'^M^J);

	print('^1Packing ^5Private Mail'); packbase('email',0);
	reset(MBasesFile);
  if (IOResult <> 0) then exit;
  Abort := FALSE;
  for i:=0 to filesize(MBasesFile)-1 do
    begin
      seek(MBasesFile,i); read(MBasesFile,tempboard);
      print('^1Packing ^5'+tempboard.name+'^5 #'+cstr(i+1));
      packbase(tempboard.filename,tempboard.maxmsgs);
      wkey;
      if (abort) then break;
    end;
	close(MBasesFile);
	lil:=0;
end;

procedure packmessagebases;
begin
	nl;
	if pynq('Pack all message bases? ') then doshowpackbases else begin
		with memboard do begin
			initboard(board);
			sysoplog('Packed message base ^5'+memboard.name);
			print(^M^J'^1Packing ^5'+name+'^5 #'+cstr(cmbase(board)));
			packbase(filename,maxmsgs);
		end;
	end;
end;

procedure chbds;
var
	s:string[15];
	First,
	Last,
	Temp:word;
	oldconf:boolean;
begin
	oldconf := confsystem;
	confsystem := FALSE;
	if (oldconf) then
		newcomptables;
	if (novice in thisuser.flags) then
    mbaselist(TRUE)
  else
    nl;
	repeat
    prt('Range to toggle (^5x^4-^5y^4), [F]lag or [U]nflag all, [Q]uit (^5?^4=^5List^4): ');
		scaninput(s,'FUQ-?'^M);
    if (s = '?') then
      mbaselist(TRUE)
		else
			if (s = 'F') then
        begin
          print(^M^J'You are now reading all message bases.'^M^J);
          for Temp := 1 to MaxMBases do
            begin
              initboard(Temp);
              if not NewScanMBase then
                NewScanMBase := ToggleNewScan;
            end
        end
			else
				if (s = 'U') then
          begin
            print(^M^J'You are now not reading any message bases.'^M^J);
            for Temp := 1 to MaxMBases do
              begin
                initboard(Temp);
                if NewScanMBase and not (mbforceread in memboard.mbstat) then
                  NewScanMBase := ToggleNewScan;
              end
          end
				else
					if (value(s) > 0) then
						begin
							First := ambase(value(s));
							if (pos('-', s) > 0) then
								begin
									Last := ambase(value(copy(s, pos('-', s) + 1, 255)));
									if (First > Last) then
										begin
											Temp := First;
											First := Last;
											Last := Temp;
										end;
								end
							else
								Last := First;
							if (First >= 1) and (Last <= MaxMBases) then
								begin
									for Temp := First to Last do
										begin
											initboard(Temp);
											if not (mbforceread in memboard.mbstat) then
                        begin
                          NewScanMBase := ToggleNewScan;
                          if (First = Last) then
                            print(^M^J'^5' + memboard.name + '^3 will ' + aonoff(NewScanMBase, 'not ','') + 'be scanned.'^M^J);
                        end
											else
                        print(^M^J'^5' + memboard.name + '^3 cannot be removed from your newscan.'^M^J)
										end;
								end
							else
								print(^M^J'Invalid range.'^M^J);
						end;
	until (s = 'Q') or (hangup);
	confsystem := oldconf;
	if (oldconf) then
		newcomptables;
	lastcommandovr := TRUE;
end;

end.
