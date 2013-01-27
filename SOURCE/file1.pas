{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit file1;

interface

uses crt, dos, overlay, myio, common, timefunc, multnode, dfFix;

function searchfordups(const completefn:astr):boolean;
function DizExists(const fn:astr):boolean;
procedure getdiz(var f:ulfrec; var v:verbrec);
procedure dodl(fpneed:integer);
procedure doul(pts:integer);
function okdl(const f:ulfrec):boolean;
procedure dlx(f1:ulfrec; rn:integer; addbatch:boolean);
procedure dl(const fn:astr; addbatch:boolean);
procedure dodescrs(var f:ulfrec; var v:verbrec; var tosysop:boolean);
procedure writefv(rn:integer; f:ulfrec; v:verbrec);
procedure doffstuff(var f:ulfrec; const fn:astr; var gotpts:integer);
procedure arcstuff(var ok,convt:boolean; var blks:word; var convtime:longint;
                   itest:boolean; const fpath:astr; var fn,descr:astr);
procedure idl(addbatch:boolean; s:astr);
procedure iul;

procedure fbaselist(ShowScan:boolean);
procedure unlisted_download(s:astr);
procedure do_unlisted_download;
function NewVPointer:longint;

implementation

uses file0, file2, file6, file8, file11, file12, file14, Email, archive1, ShortMsg;

var
	locbatup:boolean;

procedure dodl(fpneed:integer);
begin
	nl;
	nl;
	if (not aacs(general.nofilecredits)) and
		 (not (fnocredits in thisuser.flags))
		 and (general.filecreditratio) then
		begin
			if (fpneed > 0) then
				AdjustBalance(fpneed);
			print ('^5Enjoy the file, '+thisuser.name+'!');
			if (fpneed <> 0) then
				print ('^5Your credits have been deducted to '+cstr(AccountBalance)+'.');
		end;
end;

procedure doul(pts:integer);
begin
	if (not aacs(general.ulvalreq)) and (not general.ValidateAllFiles) then
		begin
			print('^5Thanks for the upload, '+thisuser.name+'!');
			if (general.uldlratio) then
				print('^5You will receive file credit as soon as the SysOp validates the file!')
			else
				print('^5You will receive credits as soon as the SysOp validates the file!');
		end
	else
		if ((not general.uldlratio) and (not general.filecreditratio) and (pts=0)) then begin
			print('^5Thanks for the upload, '+thisuser.name+'!');
			print('^5You will receive credits as soon as the Sysop validates the file!');
		end else
			 AdjustBalance(-pts);
end;


function okdl(const f:ulfrec):boolean;
var s:astr;
		b:boolean;
		mheader:mheaderrec;

  procedure nope(const s:astr);
	begin
		if (b) then print(s);
		b:=FALSE;
	end;

begin
	b:=TRUE;
	if (isrequest in f.filestat) then begin
		printf('reqfile');
		if (nofile) then begin
			print(^M^J'^5You must Request this file -- Ask '+
						 general.sysopname+' for it.'^M^J);
		end;
		dyny:=TRUE;
		if (pynq('Request this file now? [Y] : ')) then begin
			s:=sqoutsp(f.filename);
      irt:=#1'Requesting "'+s+'" from area #'+cstr(cfbase(fileboard));
			mheader.status:=[];
			semail(1,mheader);
		end;
		b:=FALSE;
	end;
	if ((resumelater in f.filestat) and (not FileSysOp)) then
		nope('You can''t do anything with RESUME-LATER files.');

	if ((notval in f.filestat) and (not aacs(general.dlunval))) then
		nope('You can''t do anything with UNVALIDATED files.');

	if ((AccountBalance < f.credits) and (f.credits > 0)) and
		 (not aacs(general.nofilecredits)) and
		 (not (fnocredits in thisuser.flags)) and
		 (not (fbnoratio in memuboard.fbstat)) and
		 (general.filecreditratio) then
		nope(fstring.nofilecredits);
	if (nsl < longint(f.blocks) * 128 div rate) then
		nope('Insufficient time for transfer.');
	if (not exist(memuboard.dlpath+f.filename)) and
		 (not exist(memuboard.ulpath+f.filename)) then
		begin
			nope('File does not actually exist.');
			sysoplog('File missing: '+sqoutsp(memuboard.dlpath+f.filename));
		end;
	okdl:=b;
end;

procedure dlx(f1:ulfrec; rn:integer; addbatch:boolean);
var u:userrec;
    s,s2:astr;
		tooktime:longint;
		cps:longint;
		i:integer;
		c:char;
		ps,ok,cdrom:boolean;
begin
	abort:=FALSE; next:=FALSE;
	fileinfo(f1,FALSE);

	ps:=TRUE;
	cdrom := FALSE;
  abort := FALSE;
	if (not okdl(f1)) then ps:=TRUE
	else begin
		if (exist(memuboard.dlpath + f1.filename)) then
			begin
				s := memuboard.dlpath;
				if (fbcdrom in memuboard.fbstat) then
					cdrom := TRUE;
			end
		else
			s := memuboard.ulpath;

		ps := FALSE;

    if (outcom) then
      send(s + f1.filename, CDROM, TRUE, ok, abort, addbatch, tooktime)
    else
      begin
        s2 := '';
        inputpath(^M^J'Enter the destination path', s2);
        if (s2 <> '') then
          begin
            prompt('^1Copying ... ');
            copyfile(ok, abort, TRUE, s + f1.filename, s2 + f1.filename);
          end;
        tooktime := 0;
        nl;
      end;

		if (not (-lastprot in [2,3,4])) then
			if (not abort) then
				if (not ok) then begin
					star('Download unsuccessful.');
					sysoplog('^3Download failed: '+sqoutsp(f1.filename)+
									 ' from '+memuboard.name);
					ps:=TRUE;
				end else begin
          check_status;
					if (not (fbnoratio in memuboard.fbstat)) then begin
						inc(thisuser.downloads);
						inc(thisuser.dltoday);
						inc(thisuser.dlktoday,(f1.blocks div 8));
						thisuser.dk:=thisuser.dk+(f1.blocks div 8);
					end;
          inc(dtoday);
          inc(dktoday, (f1.blocks div 8));

					star('1 file successfully sent in ' + FormattedTime(TookTime));
					s:=  'Total: '+cstr(longint(f1.blocks) * 128 + f1.sizemod)+' bytes';
					if (fbnoratio in memuboard.fbstat) then s:=s+'^5 <No-Ratio>';
					star(s);

					s:='^3Download "'+sqoutsp(f1.filename)+'" from '+memuboard.name;

					if (tooktime > 0) then
						cps:=(longint(f1.blocks) * 128 + f1.sizemod) div tooktime
					else
						cps:=0;

					s:=s+'^3 ('+cstr(f1.blocks div 8)+'k, '+ctim(tooktime)+
							 ', '+cstr(cps)+' cps)';
					sysoplog(s);
					if not (fbnoratio in memuboard.fbstat) and
						 (f1.credits > 0) then dodl(f1.credits);
					if general.rewardsystem then
             if (f1.owner>0) and (f1.owner<=maxusers) and (f1.owner <> usernum) then begin
								nl;
								loadurec(u,f1.owner);
								i := trunc(f1.credits * general.rewardratio / 100);
								if (u.name = f1.stowner) and (i > 0) then begin
									sysoplog('Awarding ' + cstr(i) + ' credit' + Plural(i) + ' to '+caps(u.name));
									if (i > 0) then
										inc(u.credit, i)
									else
										inc(u.debit, i);
									saveurec(u,f1.owner);
									ssm(f1.owner,'You received ' + cstr(i) +
											' credit' + Plural(i) + ' for the download of ' + sqoutsp(f1.filename));
								end;
						 end;
					initfileboard;

					if (rn<>-1) then begin
						inc(f1.downloaded);
						seek(DirFile,rn); write(DirFile,f1);
						Lasterror := IOResult;
					end;
				end;
	end;
	if (ps) then begin
		prompt(^M^J'^5Press [Enter] to continue or [Q]uit : ');
		onek(c,'Q '^M);
		abort:=(c='Q');
	end;
	saveurec(thisuser, usernum);
end;

procedure dl(const fn:astr;addbatch:boolean);
var rn,oldboard,b:integer;
		f:ulfrec;
		gotany,junk:boolean;

	function scanbase : boolean;
	var
		b:byte;
	begin
		scanbase := FALSE;
		recno(fn,rn);
		if not baddlpath then
			while (rn <> -1) and (not abort) and (not hangup) do
				begin
					gotany:=TRUE;
					reset(DirFile);
					seek(DirFile,rn);
					read(DirFile,f);
					BackErase(13);
					nl;
					if (not (notval in f.filestat)) or (aacs(general.dlunval)) then
						if aacs(memuboard.dlacs) then
							begin
								dlx(f,rn,addbatch);
								scanbase := TRUE;
                if not (iswildcard(fn)) then
                  Abort := TRUE;
							end
						else
							print('You do not have access to download that file.');

					nrecno(fn,rn);
					close(DirFile);
				end;
		Lasterror := IOResult;
	end;

begin
	gotany:=FALSE;
	abort:=FALSE;
	prompt('Searching ...');
	if not scanbase then
		begin
			oldboard:=fileboard;
			b:=0;
      while (b<=MaxFBases) and (not abort) and (not hangup) do
        begin
          inc(b);
          if (b = oldboard) then continue;
          loadfileboard(b);
          wkey;
          if memuboard.password='' then
            changefileboard(b);
          if (fileboard=b) then
            junk := scanbase;
        end;
		end;
	if not gotany then
		begin
			BackErase(13);
			print(^M^J'File not found.');
		end;
	changefileboard(oldboard);
end;

procedure idl(addbatch:boolean; s:astr);
var
	allowed:boolean;
begin
	allowed:=TRUE;
	if (not intime(timer,general.dllowtime,general.dlhitime)) then allowed:=FALSE;
	if (Speed  < general.minimumdlbaud) then
		if (not intime(timer,general.minbauddllowtime,general.minbauddlhitime)) then
			allowed:=FALSE;
	if (not allowed) then begin
		 printf('dlhours');
		 if (nofile) then
			 print(^M^J'File downloading is not allowed at this time.');
	end else begin
		nl;
		if (not addbatch) and (numbatchfiles > 0) then
			if pynq('Download queued files? ') then
				begin
					batchdl;
					exit;
				end
			else
				nl;

		if (s = '') then
			begin
				printf('dload');
				if not addbatch then
					print(fstring.downloadline)
				else
					print(fstring.addbatch);
				prt(^M^J'Filename: '); mpl(12); input(s,12);
			end;

		if (s <> '') then
			begin
				if (pos('.',s)=0) then s:=s+'.*';
				dl(s,addbatch);
			end
	end;
end;

procedure dodescrs(var f:ulfrec; var v:verbrec; var tosysop:boolean);
var i,maxlen:integer;
		isgif:boolean;
begin
	if ((tosysop) and (general.tosysopdir >= 0) and (general.tosysopdir <= MaxFBases)) then
		print(^M^J'Begin description with (/) to make upload ''Private''.')
	else
		begin
			tosysop := FALSE;
			nl;
		end;

	loadfileboard(fileboard);
	isgif:=isgifext(f.filename);
	if ((fbusegifspecs in memuboard.fbstat) and (isgif)) then
    maxlen := 35
	else
		maxlen := 50;

  print('Enter your text. (Enter) alone to end. (50 chars/line, 10 lines maximum)');
	repeat
		prt(':');
		mpl(maxlen); inputwc(f.description,maxlen);
		if ((f.description[1]='/') or (rvalidate in thisuser.flags)) and (tosysop) then
			begin
				if (general.tosysopdir > 0) then
					fileboard := general.tosysopdir;
				close(DirFile);
				initfileboard;
				tosysop:=TRUE;
			end
		else
			tosysop:=FALSE;
		if (f.description[1]='/') then
			delete(f.description,1,1);
	until ((f.description <> '') or (FileSysOp) or (hangup));
	v.descr[1]:='';
	dyny:=FALSE;
	i:=1;
	repeat
		prt(':');
		mpl(maxlen);
		inputl(v.descr[i],50);
    if (v.descr[i]='') then i := MAXEXTDESC;
		inc(i);
  until (i >= MAXEXTDESC) or (hangup);
end;

function DizExists(const fn:astr):boolean;
var
	ok:boolean;
begin
	DizExists := FALSE;
  if (arctype(fn) > 0) then
		begin
      star('Checking for description...'#29);
			arcdecomp(ok, arctype(fn), fn, 'file_id.diz desc.sdi');
			if (ok) and (exist(tempdir + 'ARC\file_id.diz') or
				 (exist(tempdir + 'ARC\desc.sdi'))) then
				DizExists := TRUE;
      nl;
		end;
end;

procedure getdiz(var f:ulfrec; var v:verbrec);
var
	T:Text;
	S:string[50];
	Index:byte;
begin
	if (exist(TempDir + 'ARC\file_id.diz')) then
		assign(T, TempDir + 'ARC\file_id.diz')
	else
		assign(T, TempDir + 'ARC\desc.sdi');
	reset(T);
	if (IOResult <> 0) then exit;
	star('Importing description.');
	Index := 1;
  fillchar(v, sizeof(v), 0);
  while not eof(T) and (Index <= MAXEXTDESC + 1) do
		begin
      readln(T, s);
      if (s = '') then s := ' ';
			if (Index = 1) then
				f.description := s
			else
				v.descr[Index - 1] := s;
			inc(Index);
		end;
  Index := 9;
  while (Index >= 1) and ((v.descr[Index] = ' ') or (v.descr[Index] = '')) do
    begin
      v.descr[Index] := '';
      dec(Index);
    end;
	close(T);
  erase(T);
  Lasterror := ioresult;
end;

procedure writefv(rn:integer; f:ulfrec; v:verbrec);
var vfo:boolean;
begin
	seek(DirFile,rn);
	write(DirFile,f);

  if (v.descr[1] <> '') and (f.vpointer <> -1) then
		begin
			vfo:=(filerec(verbf).mode<>fmclosed);
			if (not vfo) then reset(verbf);
			seek(verbf,f.vpointer); write(verbf,v);
			if (not vfo) then close(verbf);
		end;
	Lasterror := IOResult;
end;

procedure doffstuff(var f:ulfrec; const fn:astr; var gotpts:integer);
begin
	f.filename:=align(fn);
	f.owner:=usernum;
	f.stowner:=allcaps(thisuser.name);
	f.date:=date;
	f.daten:=daynum(date);
	f.downloaded:=0;

	if (not general.filecreditratio) then begin
		f.credits:=0;
		gotpts:=0;
	end else begin
		if (general.filecreditcompbasesize > 0) then
			f.credits:=(f.blocks div 8) div general.filecreditcompbasesize
		else
			f.credits := 0;
		gotpts:=f.credits*general.filecreditcomp;
		if (gotpts < 1) then gotpts:=1;
	end;

	f.filestat:=[];
	if (not general.validateallfiles) and not (CoSysOp) then
		f.filestat:=f.filestat+[notval];
end;

procedure arcstuff(var ok,convt:boolean;		{ if ok - if converted }
									 var blks:word; 					{ # blocks		 }
									 var convtime:longint;		{ convert time }
									 itest:boolean; 					{ whether to test integrity }
                   const fpath:astr;        { filepath     }
									 var fn:astr; 						{ filename		 }
									 var descr:astr); 				{ description  }
var fi:file of byte;
		oldnam,newnam,s:astr;
		x,y,c:word;
		oldarc,newarc:integer;
begin
	{*	oldarc: current archive format, 0 if none
	 *	newarc: desired archive format, 0 if none
	 *	oldnam: current filename
	 *	newnam: desired archive format filename
	 *}

	convtime := 0;
	ok:=TRUE;

	assign(fi,fpath+fn);
	reset(fi);
	if (ioresult<>0) then blks:=0
	else begin
		blks:=filesize(fi) div 128;
		close(fi);
	end;

	if not general.testuploads then exit;

	newarc:=memuboard.arctype;
	oldarc:=1;
	oldnam:=sqoutsp(fpath+fn);
	while (general.filearcinfo[oldarc].ext<>'') and
				(general.filearcinfo[oldarc].ext<>copy(fn,length(fn)-2,3)) and
				(oldarc<maxarcs+1) do
		inc(oldarc);
	if (oldarc=maxarcs+1) or
		 (general.filearcinfo[oldarc].ext='') then oldarc:=0;
	if (not general.filearcinfo[oldarc].active) then oldarc:=0;
	if (not general.filearcinfo[newarc].active) then newarc:=0;
	if (newarc=0) then newarc:=oldarc;

	if ((oldarc<>0) and (newarc<>0)) then begin
		newnam:=fn;
		if (pos('.',newnam)<>0) then newnam:=copy(newnam,1,pos('.',newnam)-1);
		newnam:=sqoutsp(fpath+newnam+'.'+general.filearcinfo[newarc].ext);
		{* if integrity tests supported ... *}
		if ((itest) and (general.filearcinfo[oldarc].testline<>'')) then begin
			star('Testing file integrity ... '#29);
			arcintegritytest(ok,oldarc,oldnam);
			if (not ok) then
				begin
					sysoplog('^5 '+oldnam+' on #'+cstr(fileboard)+': errors in integrity test');
					print('^3failed.');
				end
			else
				print('^3passed.');
		end;

		if (ok) and ((oldarc <> newarc) or general.recompress) and (newarc<>0) then begin
			convt:=incom; 	{* don't convert if local and non-file-SysOp *}
			s:=general.filearcinfo[newarc].ext;
			if (FileSysOp) then begin
				dyny:=TRUE;
				if (oldarc = newarc) then
					convt := pynq('Recompress this file? ')
				else
					convt:=pynq('Convert archive to .'+s+' format? ');
			end;
			if (convt) then begin
				nl;
				convtime := getpackdatetime;
				conva(ok, oldarc, newarc, oldnam, newnam);
				convtime := getpackdatetime - convtime;

				if (ok) then
					begin
						if (oldarc <> newarc) then
							kill(fpath+fn);
						assign(fi,newnam);
						reset(fi);
						if (ioresult<>0) then
							ok:=FALSE
						else
							begin
								blks:=(filesize(fi) div 128);
								close(fi);
								if (blks=0) then ok:=FALSE;
							end;
						fn:=align(stripname(newnam));
						star('No errors in conversion, file passed.');
					end
				else
					begin
						if (oldarc <> newarc) then
							kill(newnam);
						sysoplog('^5 '+oldnam+' on #'+
										 cstr(fileboard)+': Conversion unsuccessful');
						star('errors in conversion!  Original format retained.');
						newarc:=oldarc;
					end;
				ok:=TRUE;
			end
				else
					newarc:=oldarc;
		end;

		{* if comment fields supported/desired ... *}
		if (ok) and (general.filearcinfo[newarc].cmtline<>'') then begin
			s:=sqoutsp(fpath+fn);
			arccomment(ok,newarc,memuboard.cmttype,s);
			ok:=TRUE;
		end;
	end;
	fn:=sqoutsp(fn);

	if ((isgifext(fn)) and (fbusegifspecs in memuboard.fbstat)) then begin
    getgifspecs(fpath+fn,s,x,y,c);
		s:='('+cstr(x)+'x'+cstr(y)+','+cstr(c)+'c) ';
		descr:=s+descr;
		if (length(descr)>60) then descr:=copy(descr,1,60);
	end;
end;

function searchfordups(const completefn:astr):boolean;
var WildFN,nearfn,s:astr;
		oldboard,i:integer;
    AnyFound, hadacc, Thisboard, CompleteMatch, NearMatch:boolean;

  procedure searchb(b:integer; const fn:astr; var hadacc:boolean);
	var f:ulfrec;
			rn:integer;
	begin
		hadacc:=fbaseac(b); 				{ loads in memuboard }
    if (not hadacc) or ((fbnodupecheck in memuboard.fbstat) and not (fileboard = b)) then exit;
		fileboard:=b;
		recno(fn,rn);
		if (badfpath) then exit;
		while (rn < filesize(DirFile)) and (rn <> -1) do
			begin
        if (not AnyFound) then
          begin
            nl; nl;
            AnyFound := TRUE;
          end;
				seek(DirFile,rn); read(DirFile,f);
        if (cansee(f)) then
          display_file('', f, TRUE);
				if (align(f.filename) = align(completefn)) then
          begin
            CompleteMatch := TRUE;
            ThisBoard := TRUE;
          end
				else
					begin
            nearfn := align(f.filename);
						NearMatch := TRUE;
            ThisBoard := TRUE;
					end;
				nrecno(fn,rn);
			end;
		close(DirFile);
		fileboard:=oldboard;
		initfileboard;
		Lasterror := IOResult;
	end;

begin
	oldboard:=fileboard;
  AnyFound := FALSE;
  prompt('^5Searching for possible duplicates ... ');

	searchfordups:=TRUE;

  if (pos('.', CompleteFn) > 0) then
    WildFN := copy(CompleteFn, 1, pos('.',CompleteFn) - 1)
  else
    WildFN := CompleteFn;

  WildFn := sqoutsp(WildFN);

  while (WildFN[length(WildFN)] in ['0'..'9']) and (length(WildFN) > 2) do
    dec(WildFN[0]);
  
  while (length(WildFN) < 8) do
    WildFN := WildFN + '?';

  WildFN := WildFN + '.???';

	CompleteMatch := FALSE; NearMatch := FALSE;

	i:=1;
	while (i <= MaxFBases) do begin
    Thisboard := FALSE;
    searchb(i, WildFN, hadacc);
		loadfileboard(i);
		if (CompleteMatch) then
			begin
				s:='User tried to upload '+sqoutsp(completefn)+' to #'+cstr(oldboard)+
					 '; existed in #'+cstr(i);
				if (not hadacc) then
					s := s + ' - no access';
				sysoplog(s);
				nl; nl;
				if (hadacc) then
					print('^5File "'+sqoutsp(completefn)+'" already exists in "'+
								 memuboard.name+'^5 #'+cstr(i)+'".')
				else
					print('^5File "'+sqoutsp(completefn)+
								 '" cannot be accepted by the system at this time.');
				print('^7Illegal filename.');
				exit;
      end
		else
      if (NearMatch) and (Thisboard) then
				begin
					s:='User entered upload filename "'+sqoutsp(completefn)+'" in #'+
						 cstr(fileboard)+'; was warned that "'+sqoutsp(nearfn)+
						 '" existed in #'+cstr(i)+'.';
					if (not hadacc) then s:=s+' - no access to';
					sysoplog(s);
          {nl; nl;
					if (hadacc) then
						print('^5'+sqoutsp(nearfn)+' already exists in "'+
									 memuboard.name+'^5 #'+cstr(i)+'".')
					else
						print('^5'+sqoutsp(nearfn)+' already exists.');

					searchfordups := not pynq('Upload this file anyway? ');
          break;}
				end;
		inc(i);
	end;
	fileboard := oldboard;
	initfileboard;
  if (not AnyFound) then
    print('No duplicates found.');
  nl;
	searchfordups:=FALSE;
end;

procedure ul(fn:astr; var addbatch:boolean);
var
	fi:file of byte;
	f:ulfrec;
	v:verbrec;
	s:astr;
	TransferTime, RefundTime, ConversionTime:longint;
	cps,lng,origblocks:longint;
	x,rn,oldboard,gotpts:integer;
	c:char;
	fok,uls,ok,kabort,convt,aexists,resumefile,wenttosysop,offline:boolean;
begin
	oldboard:=fileboard;
	initfileboard;
	if (badulpath) then exit;

	ok:=TRUE; rn:=0;
	if (fn[1]=' ') or (fn[10]=' ') then ok:=FALSE;

	for x:=1 to length(fn) do
		if (pos(fn[x],'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ.-!#$%^&''~()_') = 0) then
			begin
				ok := FALSE;
				break;
			end;

	fn := align(fn);

	if (not ok) then
		begin
			print('Illegal filename.');
			exit;
		end;

	{* aexists: 	 if file already EXISTS in dir
		 rn:				 rec-num of file if already EXISTS in file listing
		 resumefile: if user is going to RESUME THE UPLOAD
		 uls: 			 whether file is to be actually UPLOADED
		 offline: 	 if uploaded a file to be offline automatically..
	*}

	resumefile:=FALSE; uls:=TRUE; offline:=FALSE; abort:=FALSE;
	aexists:=exist(memuboard.ulpath+fn);

	recno(fn,rn);
	if (badulpath) then exit;
	nl;
	if (rn<>-1) then begin
		seek(DirFile,rn); read(DirFile,f);
		resumefile:=(resumelater in f.filestat);
		if (resumefile) then begin
			print('This is a resume-later file.');
			resumefile:=((f.owner=usernum) or (FileSysOp));
			if (resumefile) then begin
				if (not incom) then begin
					print('Cannot be resumed locally.');
					exit;
				end;
				dyny:=TRUE;
				resumefile:=pynq('Resume upload of "'+sqoutsp(fn)+'" ? ');
				if (not resumefile) then exit;
			end else begin
				print('^7You are not the uploader of this file.');
				exit;
			end;
		end;
  end;
  if ((not aexists) and (FileSysOp) and (not incom)) then begin
		uls:=FALSE;
		offline:=TRUE;
		print('This file does not exist in the files directory.');
		if not pynq('Do you want to create an offline entry? ') then exit;
	end;
	if (not resumefile) then begin
		if (((aexists) or (rn<>-1)) and (not FileSysOp)) then begin
			print('File already exists.');
			exit;
		end;
		if (filesize(DirFile)>=memuboard.maxfiles) then begin
			star('This directory is full.');
			exit;
		end;
		if (not aexists) and (not offline) and
          (DiskKBfree(ExtractDriveNumber(MemuBoard.ULpath)) <= General.MinSpaceForUpload)
(*			 ((diskfree(ExtractDriveNumber(memuboard.ulpath)) div 1024)<=general.minspaceforupload)*)
		then begin
			nl;
			star('Insufficient disk space.');
			c:=chr(ExtractDriveNumber(memuboard.ulpath)+64);
			if c='@' then
				sysoplog('^8--->^3 Upload failure: Main BBS drive full.')
			else
				sysoplog('^8--->^3 Upload failure: '+c+' Drive full.');
			exit;
		end;
		if (aexists) then begin
			uls:=FALSE;
			dyny:=(rn = -1);
			print('File exists in upload path: '+memuboard.ulpath+sqoutsp(fn) + ^M^J);
			if not dyny then print('^5Note: File exists in listing.');
			if (locbatup) then begin
				prompt('^7[Q]uit or Upload this? (Y/N) ['+
								syn(dyny)+'] : ^3');
				onekcr:=FALSE; onekda:=FALSE;
				onek(c,'QYN'^M);
				if (rn<>-1) then ok:=(c='Y') else ok:=(c in ['Y',^M]);
				abort:=(c='Q');
				if (abort) then print('Quit') else
					if (not ok) then print('No') else print('Yes');
			end else
				ok:=pynq('Upload this? (Y/N) ['+syn(dyny)+'] : ');
			rn:=0;
    end;
    if ((general.searchdup) and (ok) and (not abort) and (incom)) then
      if (not FileSysOp) or (pynq('Search for duplicates? ')) then
        if (searchfordups(fn)) then exit;

		if (uls) then begin
			dyny:=TRUE;
			ok:=pynq('Upload "'+sqoutsp(fn)+'" to '+memuboard.name+'? ');
		end;

		if ((ok) and (uls) and (not resumefile)) then begin
			assign(fi,memuboard.ulpath+fn);
			rewrite(fi);
			if (ioresult <> 0) then
				ok:=FALSE
			else
				begin
					close(fi);
					erase(fi);
					if ioresult <> 0 then
						ok := FALSE;
				end;
			if (not ok) then begin
				print('Unable to upload that filename.');
				exit;
			end;
		end;
	end;

	if (not ok) then exit;
	wenttosysop:=TRUE;
	if (not resumefile) then
		begin
			f.filename:=align(fn);
			dodescrs(f,v,wenttosysop);
		end;
	ok:=TRUE;
	if (uls) then begin
		TimeLock := TRUE;

		receive(fn, memuboard.ulpath,resumefile,ok,kabort,addbatch,TransferTime);

		if (addbatch) then
			begin
				inc(numubatchfiles);
				new (BatchULQueue[NumuBatchFiles]);
				BatchULQueue[numubatchfiles]^.FileName:=sqoutsp(fn);
				with BatchULQueue[numubatchfiles]^ do
					begin
						Section := fileboard;
						Description := f.description;
						if (v.descr[1] <> '') then
							begin
								inc(hiubatchv);
								new(ubatchv[hiubatchv]);
								ubatchv[hiubatchv]^ := v;
								VPointer := hiubatchv;
							end
						else
							VPointer := 0;
					end;
				s:=cstr(numubatchfiles) + ' file' + Plural(NumBatchFiles) + ' now in upload batch queue.';
				star(s);
				star('Hit [Enter] to stop adding to queue.'^M^J);
				fileboard:=oldboard;
				exit;
			end;

		if (kabort) then begin
			fileboard:=oldboard;
			exit;
		end;

		RefundTime := TransferTime * general.ulrefund div 100;

		freetime := freetime + RefundTime;

		TimeLock := FALSE;

		star('Gave time refund of ' + FormattedTime(RefundTime));

		if (not kabort) then star('Transfer complete.');
		nl;
	end;
	nl;

	convt:=FALSE;
	if (not offline) then begin
		assign(fi,memuboard.ulpath+fn);
		reset(fi);
		if (ioresult<>0) then ok:=FALSE
		else begin
			f.blocks:=filesize(fi) div 128;
			f.sizemod:=filesize(fi) mod 128;
			if (filesize(fi)=0) then ok:=FALSE;
			close(fi);
			origblocks:=f.blocks;
		end;
	end;

	if ((ok) and (not offline)) then begin
		arcstuff(ok, convt, f. blocks, ConversionTime, uls, memuboard.ulpath, fn, f.description);
		doffstuff(f,fn,gotpts);
    if (General.FileDiz) and (DizExists(memuboard.ulpath + fn)) then
			getdiz(f,v);

		if (ok) then begin
			if (v.descr[1]<>'') then
				f.vpointer := NewVPointer
			else
				f.vpointer := -1;
			if (not resumefile) or (rn = -1) then
				writefv(filesize(DirFile), f, v)
			else
				writefv(rn, f, v);

			if (uls) then
				begin
					if aacs(general.ulvalreq) or (general.ValidateAllFiles) then
						begin
							inc(thisuser.uploads);
							inc(thisuser.uk,f.blocks div 8);
						end;
          inc(utoday);
          inc(uktoday, f.blocks div 8);
				end;

			s:='^3Upload "'+sqoutsp(fn)+'" on '+memuboard.name;
			if (uls) then begin
				if (TransferTime > 0) then
					cps := (longint(f.blocks) * 128 + f.sizemod) div TransferTime
				else
					cps := 0;
				s:=s+'^3 ('+cstr(f.blocks div 8)+'k, ' + FormattedTime(TransferTime) +
						 ' min, '+cstr(cps)+' cps)';
			end;
			sysoplog(s);
			if ((incom) and (uls)) then begin
				if (convt) then begin
					lng := origblocks * 128 + f.sizemod;
					star('Org file size: ^5'+cstr(lng)+' bytes.');
				end;
				lng := longint(f.blocks) * 128 + f.sizemod;
				if (convt) then
					star('New file size: ^5' + cstr(lng)+' bytes.') else
					star('File size    : ^5' + cstr(lng)+' bytes.');
					star('Upload time  : ^5' + FormattedTime(TransferTime));
				if (convt) then
					star('Convert time : ^5' + FormattedTime(ConversionTime));
					star('Transfer rate: ^5' + cstr(cps)+' cps');
					star('Time refund  : ^5' + FormattedTime(RefundTime));
				if (gotpts <> 0) then
					star('Credits      : ^5'+cstr(gotpts)+' pts');
				nl;
				if (choptime > 0) then
					begin
						choptime := choptime + RefundTime;
						freetime := freetime - RefundTime;
						star('Sorry, no upload time refund may be given at this time.');
						star('You will get your refund after the event.'^M^J);
					end;
				doul(gotpts);
			end
			else star('Entry added.');
		end;
	end;
	if (not ok) and (not offline) then begin
		if (exist(memuboard.ulpath+fn)) then begin
			star('Upload not received.');
			s:='file deleted';
			if (f.blocks div 8>general.minresume) then
				begin
					nl;
					dyny:=TRUE;
					if pynq('Save file for a later resume? ') then
						begin
							doffstuff(f,fn,gotpts);
							f.filestat:=f.filestat+[resumelater];
							if (v.descr[1]<>'') then
								f.vpointer := NewVPointer
							else
								f.vpointer := -1;
							if (not aexists) or (rn = -1) then
								writefv(filesize(DirFile), f, v)
							else
								writefv(rn, f, v);
							s:='file saved for later resume';
						end;
				end;
			if (not (resumelater in f.filestat)) and (exist(memuboard.ulpath+fn)) then
				kill(memuboard.ulpath+fn);
			sysoplog('^3error uploading '+sqoutsp(fn)+' - '+s);
		end;
		star('Taking away time refund of ' + FormattedTime(RefundTime));
		freetime := freetime - RefundTime;
	end;
	if (offline) then begin
		if (v.descr[1]<>'') then
			f.vpointer := NewVPointer
		else
			f.vpointer := -1;
		f.blocks:=10;
		f.sizemod:=0;
		doffstuff(f, fn, gotpts);
		f.filestat:=f.filestat+[isrequest];
		writefv(filesize(DirFile), f, v);
	end;
	close(DirFile);
	fileboard:=oldboard;
	initfileboard; close(DirFile);
	saveurec(thisuser, usernum);
end;

procedure iul;
var s:astr;
		done,addbatch:boolean;
begin
	initfileboard;
	if (badulpath) then exit;
	if (not aacs(memuboard.ulacs)) then begin
		nl;
		star('You cannot upload to this section.');
		exit;
	end;
	locbatup:=FALSE;
	printf('upload');
	nl;
	if (numubatchfiles > 0) and pynq('Upload queued files? ') then
		begin
			batchul(FALSE,0);
			exit;
		end;

	repeat
		print(fstring.uploadline);
		done:=TRUE; addbatch:=FALSE;
		prt(^M^J'Filename: '); mpl(12); input(s,12); s:=sqoutsp(s);
		if (s<>'') then begin
			if (not FileSysOp) then ul(s,addbatch)
			else begin
				if (not iswildcard(s)) then ul(s,addbatch)
				else begin
					locbatup:=TRUE;
          findfirst(memuboard.ulpath+s, anyfile, dirinfo);
          if (Doserror <> 0) then
            print('No files found.')
          else
						repeat
							if not ((dirinfo.attr and VolumeID=VolumeID) or
											(dirinfo.attr and Directory=Directory)) then
								ul(dirinfo.name,addbatch);
              findnext(dirinfo);
            until (Doserror <> 0) or (abort);
				end;
			end;
		end;
		done:=(not addbatch);
	until (done) or (hangup);
end;

procedure fbaselist(ShowScan:boolean);
var s:astr;
		oldboard,onlin,nd:integer;

begin
	cls;
	abort:=FALSE;
	oldboard := fileboard;
	onlin:=0; s:=''; fileboard:=1; nd:=0;
  AllowContinue := TRUE;  AllowAbort := TRUE;
	printacr('-ÚÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
	printacr('-³. Num -³/ Name                           -³. Num -³/ Name                          -³');
	printacr('-ÀÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
	reset(FBasesFile);
	while (fileboard <= MaxFBases) and (not abort) do begin
		if ShowScan then
			initfileboard
		else
			loadfileboard(fileboard);

		if aacs(memuboard.acs) or (fbunhidden in memuboard.fbstat) then begin
			s:='1'+cstr(cfbase(fileboard));
			s:=mrn(s,5);
			if (NewScanFBase and ShowScan) then
				s := s + '0 þ '
			else
				s := s + '   ';
			s:=s+'2'+memuboard.name;
			inc(onlin);
			inc(nd);
			if (onlin = 1) then
				prompt(mln(s,39))
			else
				begin
					if (lennmci(s) > 39) then
						print(mln(s,39))
					else
						print(s);
					onlin:=0;
				end;
			wkey;
		end;
		inc(fileboard);
	end;
	close(FBasesFile);
	AllowContinue := FALSE;
	if (onlin=1) then nl;
	nl;
	if (nd=0) and (not abort) then prompt(^M^J'^7No file bases.');
	fileboard := oldboard;
	initfileboard;
end;

procedure unlisted_download(s:astr);
var dok,kabort:boolean;
		oldfileboard:integer;
		tooktime:longint;
		dirinfo:searchrec;
		path:pathstr;
		name:namestr;
		ext:extstr;
begin
	if (s<>'') then begin
		fsplit(s,path,name,ext);
		if not exist(s) then print('File not found.')
			else begin
				oldfileboard:=fileboard;
				fileboard:=-1;
				findfirst(s,anyfile-Directory-VolumeID,dirinfo);
				while (doserror = 0) do
					begin
						s := path + dirinfo.name;
            print(^M^J'^1File: ' + stripname(s));
						send(s,FALSE,FALSE,dok,kabort,false,tooktime);
            if (dok) then
              sysoplog('Downloaded unlisted file: ' + s);
						findnext(dirinfo);
					end;
				fileboard:=oldfileboard;
			end;
	end;
end;

procedure do_unlisted_download;
var s:astr;
begin
	print(^M^J'Enter file name to download (d:path\filename.ext)');
	prt(':'); mpl(78); input(s,78);
	unlisted_download(s);
end;

function NewVPointer:longint;
var i,x:word;
		v:verbrec;
		vfo:boolean;
begin
	vfo := (filerec(verbf).mode<>fmclosed);
	if (not vfo) then
		reset(verbf);
	x := filesize(verbf);
	if (not vfo) then
		close(verbf);
	NewVPointer := x;
	Lasterror := IOResult;
end;

end.
