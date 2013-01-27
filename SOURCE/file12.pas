{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit file12;

interface

uses crt, dos, overlay, common, timefunc, dfFix;

procedure delubatch(n:integer);
procedure listubatchfiles;
procedure removeubatchfiles;
procedure clearubatch;
procedure batchul(bicleanup:boolean; TransferTime:longint);
procedure batchinfo;

implementation

uses file0, file1, file2, file6, file9, execbat, archive1;

procedure delubatch(n:integer);
var
	c:integer;
begin
	if (n >= 1) and (n <= numubatchfiles) then
		begin
			if (n <> numubatchfiles) then
				for c := n to numubatchfiles - 1 do
					BatchULQueue[c]^ := BatchULQueue[c + 1]^;
			dispose (BatchUlQueue[numubatchfiles]);
			dec(numubatchfiles);
		end;
end;

procedure listubatchfiles;
var s,s1:astr;
		i,j:integer;
		vfo:boolean;
begin
	if (numubatchfiles=0) then
		print(^M^J'Upload batch queue empty.')
	else begin
		abort:=FALSE; next:=FALSE;
		printacr(^M^J'^4##:Filename.Ext Area Description');
		printacr('--------------- ---- -------------------------------------------------------');

		i:=1;
		while (not abort) and (i <= numubatchfiles) and (not hangup) do
			begin
				with BatchULQueue[i]^ do
					begin
						if (section=general.tosysopdir) then
							s1:='^7Sysp'
						else
							s1:=mrn(cstr(section),4);
						s := '^3' + mn(i,2) + '^4:^5' + align(FileName) + ' '+s1+' ^3'+
								 mln(description,55);
						printacr(s);
						if (VPointer <> 0) then
							if (ubatchv[VPointer]^.descr[1]<>'') then
								begin
									vfo := (filerec(verbf).mode<>fmclosed);
									if (not vfo) then
										reset(verbf);
									if (ioresult=0) then
                    for j:=1 to MAXEXTDESC do
											if ubatchv[VPointer]^.descr[j]='' then
                        break
											else
												printacr('                     ^4' +
																 + ubatchv[VPointer]^.descr[j]);
									if (not vfo) then close(verbf);
								end;
					end;
					inc(i);
			end;

		printacr('^4--------------- ---- -------------------------------------------------------');
	end;
end;

procedure removeubatchfiles;
var s:astr;
		i:integer;
begin
	if (numubatchfiles=0) then
		print(^M^J'Upload batch queue empty.')
	else
		repeat
			prt(^M^J'File # to remove (1-'+cstr(numubatchfiles)+') (?=list) : ');
			input(s,2);
			i:=value(s);
			if (s='?') then listubatchfiles;
			if ((i>0) and (i<=numubatchfiles)) then
				begin
					print('"'+stripname(BatchULQueue[i]^.FileName)+'" deleted out of upload queue.');
					delubatch(i);
				end;
			if (numubatchfiles=0) then print('Upload queue now empty.');
		until (s<>'?');
end;

procedure clearubatch;
begin
	nl;
	if pynq('Clear upload queue? ') then
		begin
			while NumuBatchFiles > 0 do
				begin
					dispose (BatchULQueue[NumuBatchFiles]);
					dec (NumUBatchFiles);
				end;
      print('^1Upload queue now empty.');
		end;
end;

procedure batchul(bicleanup:boolean; TransferTime:longint);
var fi:file of byte;
		dirinfo:searchrec;
		f:ulfrec;
		v:verbrec;
		RefundTime,TakeAwayRefundTime:longint;
		ConversionTime,TotalConversionTime:longint;
		fn,s:astr;
		totb,totb1,totfils1:longint;
		totpts,p,oldboard,gotpts,dbn,cps:integer;
    blks,totfils:word;
		OldActivity, i:byte;
		c:char;
		autologoff,swap,ahangup,next,done,dok,wenttosysop,ok,convt,
			fok,nospace:boolean;

	procedure UpFile(ubn:integer);
	begin
		 close(DirFile);
		 initfileboard;
		 arcstuff(ok,convt,blks,ConversionTime,TRUE,tempdir + 'UP\',fn,f.description);
		 inc(TotalConversionTime,ConversionTime);

		 f.blocks := blks;
		 doffstuff(f, fn, gotpts);

		 fok:=TRUE;
		 loadfileboard(fileboard);
		 if (ok) then
			 begin
				 star('Moving file to ^5' + memuboard.name);
				 movefile(fok, nospace, FALSE, tempdir + 'UP\' + fn, memuboard.ulpath + fn);
				 if (fok) then
					 begin
						if (v.descr[1] <> '') then
							f.vpointer := NewVPointer
						else
							f.vpointer := -1;
						 writefv(filesize(DirFile),f,v);
						 star(fn+' successfully uploaded.'^M^J);
						 sysoplog('^3Batch uploaded "'+sqoutsp(fn)+'" to ' + memuboard.name);
						 inc(totfils);
						 inc(totb, longint(blks) * 128);
						 inc(totpts,gotpts);
					 end
				 else
					 begin
						 star('Upload voided: error in processing.');
						 sysoplog('^3error moving '+sqoutsp(fn)+' to directory');
					 end;
			 end
		 else
			 begin
				 star('Upload not received.');
				 if (f.blocks div 8>general.minresume) then
					 begin
						 nl;
						 dyny:=TRUE;
						 if pynq('Save file for a later resume? ') then
							 begin
								 prompt('^5Progress: ');
								 movefile(fok,nospace,TRUE,tempdir + 'UP\' + fn,memuboard.ulpath+fn);
								 if (fok) then
									 begin
										 nl;
										 doffstuff(f,fn,gotpts);
										 f.filestat:=f.filestat+[resumelater];
										if (v.descr[1] <> '') then
											f.vpointer := NewVPointer
										else
											f.vpointer := -1;
										 writefv(filesize(DirFile),f,v);
										 s:='file saved for resume';
									 end
								 else
									 begin
										 star('Upload voided: error in processing.');
										 sysoplog('^3error moving '+sqoutsp(fn)+' to directory');
									 end;
							 end;
					 end;
				 if (not (resumelater in f.filestat)) then
					 begin
						 s:='file deleted';
						 kill(tempdir + 'UP\' + fn);
					 end;
				 sysoplog('^3errors batch uploading '+sqoutsp(fn)+' - '+s);
			 end;

		 if (not ok) and (not bicleanup) then
			 begin
				 inc(TakeAwayRefundTime, longint(f.blocks) * 128 div rate);
				 star('Time refund of ' + FormattedTime(longint(f.blocks) * 128 div rate) + ' will be taken away.');
			 end
		 else
			 if (ubn <> 0) then
				 delubatch(ubn);
	end;

begin
	autologoff := FALSE;

	oldboard:=fileboard;

(*  if ((diskfree(ExtractDriveNumber(memuboard.ulpath)) div 1024) <= general.minspaceforupload) then*)
  if ((diskKBfree(ExtractDriveNumber(memuboard.ulpath))) <= general.minspaceforupload) then
    begin
      nl;
      star('Insufficient disk space.');
      c:=chr(ExtractDriveNumber(memuboard.ulpath)+64);
      if c='@' then
        sysoplog('^8--->^3 Upload failure: Main BBS drive full.')
      else
        sysoplog('^8--->^3 Upload failure: '+c+' Drive full.');
      exit;
    end;

	if not bicleanup then
		begin
			done:=FALSE;
			nl;
			if (numubatchfiles=0) then begin
				printf('batchul0');
				if (nofile) then begin
					print('Warning!  No upload batch files specified yet.');
					print('If you continue, and batch upload files, you will have to');
					print('enter file descriptions for each file after the batch upload');
					print('is complete.');
				end;
			end else begin
				printf('batchul');
				if (nofile) then begin
					print('^1If you batch upload files IN ADDITION to the files already');
					print('specified in your upload batch queue, you must enter file');
					print('descriptions for them after the batch upload is complete.');
				end;
			end;
			reset(xf);
			done:=FALSE;
			repeat
        showprots(TRUE, FALSE, TRUE, FALSE);
        s := GetProts(TRUE, FALSE, TRUE, FALSE);
        prompt(fstring.protocolp); onek(c, s);
        p:=findprot(c, TRUE, FALSE, TRUE, FALSE);
        if (p=-99) then
          print('Invalid entry.')
         else if (p=-5) then
           begin
             repeat
               prt(^M^J'Batch queue [^5L^4]ist batch, [^5R^4]emove a file, [^5C^4]lear, [^5Q^4]uit : ');
               onek(c,'QRCL');
                case c of
                 'R':removeubatchfiles;
                 'C':clearubatch;
                 'L':listubatchfiles;
               end;
             until (hangup) or (C='Q');
             if (numubatchfiles = 0) then
               exit;
           end
        else
          done:=TRUE;
			until (done) or (hangup);
			if p=-2 then exit;
			seek(xf,p); read(xf,protocol); close(xf);
			Lasterror := IOResult;
			nl;
			autologoff := pynq('Autologoff after file transfer ? ');
			dok:=TRUE;

			lil:=0;
			purgedir(tempdir + 'UP\' , FALSE);
			nl; nl;
			if (useron) then print('Ready to receive batch queue!');
			lil:=0;

			OldActivity := update_node(1);

			swap:=general.swapshell;
			general.swapshell:=FALSE;

			TransferTime := getpackdatetime;

			TimeLock := TRUE;

			execwindow(dok,tempdir + 'UP\',FunctionalMCI(protocol.envcmd,'','')+#13#10+
								 general.protpath + FunctionalMCI(protocol.ulcmd,'',''),-1,i);

			TransferTime := getpackdatetime - TransferTime;

			general.swapshell:=swap;

			update_node(OldActivity);

			RefundTime := TransferTime * (General.ULRefund div 100);

			freetime := freetime + RefundTime;

			TimeLock := FALSE;

			lil:=0;
			nl;
			star('Batch upload transfer complete.'^M^J);
			lil:=0;
		end
	else
		begin
			RefundTime := 0;
			nl;
		end;

	TotalConversionTime := 0;
	TakeAwayRefundTime := 0;
	totb := 0; totfils := 0;
	totb1 := 0; totfils1 := 0;
	totpts := 0;

  findfirst(tempdir + 'UP\*.*',anyfile-directory-volumeid,dirinfo);
	while (doserror=0) do
		begin
			inc(totfils1);
			inc(totb1,dirinfo.size);
			findnext(dirinfo);
		end;

	abort:=FALSE; next:=FALSE;

	if (totfils1 = 0) then
		begin
			star('No uploads detected!');
			exit;
		end;

	if (TransferTime > 0) then
		cps := totb1 div TransferTime
	else
		cps := 0;

	ahangup:=FALSE;

	if hangup then
		begin
			if (Speed > 0) then
				begin
					Status_screen(100,'Hanging up and taking phone off hook...',FALSE,s);
					dophonehangup(FALSE);
					dophoneoffhook(FALSE);
					Speed := 0;
				end;
			hangup:=FALSE; ahangup:=TRUE;
		end;

	if (not ahangup) then
		begin
			star('Files uploaded   : ^5' + cstr(totfils1)+' files.');
			star('Amount uploaded  : ^5' + cstr(totb1)+' bytes.');
			star('Batch upload time: ^5' + FormattedTime(TransferTime));
			star('Transfer rate    : ^5' + cstr(cps)+' cps');
			star('Time refund      : ^5' + FormattedTime(RefundTime));
			nl;
			if AutoLogoff then
				CountDown
			else
				pausescr(FALSE);
		end;

	InitFileBoard;

	for i := NumUBatchFiles downto 1 do  { avoids deallocation error }
		if exist(tempdir + 'UP\' + sqoutsp(BatchULQueue[i]^.FileName)) then
			begin
				fn := BatchULQueue[i]^.FileName;
				star('Found ' + fn + '.');
        if (General.FileDiz) and (DizExists(TempDir + 'UP\' + fn)) then
					GetDiz(f, v)
				else
					begin
						f.description := BatchULQueue[i]^.description;
						fileboard := BatchULQueue[i]^.Section;
						v.descr[1] := '';
						if (BatchULQueue[i]^.VPointer <> 0) then
							v := ubatchv[BatchULQueue[i]^.VPointer]^;
					end;
				UpFile(i);
			end;

  findfirst(tempdir + 'UP\*.*', AnyFile - Directory - volumeid, DirInfo);
	while (Doserror = 0) do
		begin
			fn := DirInfo.name;
			star('Found ' + fn + '.');
			if (general.searchdup) and (SearchForDups(fn)) then
				begin
					star('Deleting duplicate file.');
					kill(TempDir + 'UP\' + fn);
				end
			else
				begin
					WentToSysOp := FALSE;
          if (General.FileDiz) and (DizExists(TempDir + 'UP\' + fn)) then
						GetDiz(f, v)
					else
						begin
              dodescrs(f, v, WentToSysOp);

							if (ahangup) then
								begin
									f.description:='Not in upload batch queue - hungup after transfer';
									f.vpointer:=-1; v.descr[1]:='';
								end;
						end;
					if (not wenttosysop) then
						begin
							nl;
							done := FALSE;
							if (ahangup) then
								dbn := oldboard
							else
								repeat
									prt('File base (?=List) ['+cstr(cfbase(oldboard))+'] : ');
									input(s, 3);
									dbn := afbase(value(s));
									if (s = '?') then
										begin
											fbaselist(FALSE);
											nl;
										end
									else
										begin
											if (s = '') then
												dbn := oldboard;

											if (not fbaseac(dbn)) or (not aacs(memuboard.ulacs)) or
												 (exist(memuboard.ulpath + fn)) or
												 (exist(memuboard.dlpath + fn)) then
												begin
													print('You cannot put it there.');
													dbn := -1;
												end;
											end;

									if (dbn <> -1) and (s <> '?') then
										done := TRUE;
								until ((done) or (hangup));
							fileboard := dbn;
							nl;
						end
					else
						fileboard := general.tosysopdir;
					UpFile(0);
				end;
			findnext(DirInfo);
		end;

	close(DirFile);
	fileboard := oldboard;
	initfileboard;
	close(DirFile);

	lil := 0;

	dec(RefundTime, TakeAwayRefundTime);
	dec(Freetime, TakeAwayRefundTime);

	(*
	nl;
	star('Files uploaded  :   ' + cstr(totfils1)+' files.');
	if (totfils<>totfils1) then
	star('Files successful:   ' + cstr(totfils)+' files.');
	star('File size uploaded: ' + cstr(totb1)+' bytes.');
	star('Batch upload time:  ' + FormattedTime(TransferTime));
	if (TotalConversionTime > 0) then
	star('Total convert time: ' + FormattedTime(TotalConversionTime));
	star('Transfer rate:      ' + cstr(cps) + ' cps'^M^J);
	star('Time refund:        ' + FormattedTime(RefundTime));
	*)

	sysoplog('Transfer: '+cstr(totfils1)+' files, '+cstr(totb1)+
		 ' bytes, '+cstr(cps)+ 'cps.');

  inc(utoday, totfils);
  inc(uktoday, totb div 1024);

	if (aacs(general.ulvalreq)) or (general.ValidateAllFiles) then
		begin
			if (totpts<>0) then
				star('File credits:        ' + cstr(totpts) + ' pts.');
			star('Upload credits:     ' + cstr(totfils) + ' files, '+cstr(totb div 1024)+'k.'^M^J);
			star('Thanks for the file' + plural(totfils) + ', '+thisuser.name+'!');
			inc(thisuser.uploads, totfils);
			AdjustBalance(-totpts);
			inc(thisuser.uk, totb div 1024);
		end
	else
		begin
			print('^5Thanks for the file' + plural(totfils) + ', '+caps(thisuser.name)+'.');
			prompt('^5You will receive ');
			if (general.uldlratio) then
				prompt('file credit')
			else
				prompt('credits');
			print(' as soon as the SysOp validates the file' + plural(totfils) + '!');
		end;
	nl;

	if (choptime <> 0) then begin
		choptime := choptime + RefundTime - TakeAwayRefundTime;
		freetime := freetime - RefundTime + TakeAwayRefundTime;
		star('Sorry, no upload time refund may be given at this time.');
		star('You will get your refund after the event.'^M^J);
	end;

	if (ahangup) then begin
		status_screen(100,'Hanging up phone again...',false,s);
		dophonehangup(FALSE);
		hangup:=TRUE;
	end;
	saveurec(thisuser, usernum);
end;

procedure batchinfo;
begin
	if (numbatchfiles<>0) then
		print(^M^J'^9>> ^3You have ^5'+cstr(numbatchfiles)+
					'^3 file'+aonoff(numbatchfiles<>1,'s','')+
							 ' left in your download batch queue.');
	if (numubatchfiles<>0) then
		print(^M^J'^9>> ^3You have ^5'+cstr(numubatchfiles)+
					'^3 file'+aonoff(numubatchfiles<>1,'s','')+
							 ' left in your upload batch queue.');
end;

end.

