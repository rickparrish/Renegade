{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit file5;

interface

uses crt, dos, overlay, common;

procedure minidos;
procedure uploadall;

implementation

uses archive1, sysop4, arcview, file0, file1, file2, file8,
     file9, file11, execbat, multnode;

var xword:array[1..9] of astr;

function bslash(b:boolean; s:astr):astr;
begin
  if (b) then
    begin
    while (copy(s,length(s)-1,2)='\\') do s:=copy(s,1,length(s)-2);
    if (copy(s,length(s),1)<>'\') then s:=s+'\';
    end
  else
    while s[length(s)] = '\' do
      dec(s[0]);
  bslash := s;
end;

procedure parse(const s:astr);
var i,j,k:integer;
begin
	for i:=1 to 9 do xword[i]:='';
	i:=1; j:=1; k:=1;
	if (length(s)=1) then xword[1]:=s;
	while (i<length(s)) do begin
		inc(i);
		if ((s[i]=' ') or (length(s)=i)) then begin
			if (length(s)=i) then inc(i);
			xword[k]:=copy(s,j,(i-j));
			j:=i+1;
			inc(k);
		end;
	end;
end;

procedure minidos;
var curdir,s,s1:astr;
		done,nocmd,nospace,junk,junk2,junk3:boolean;
		r:longint;

	procedure versioninfo;
	begin
		print(^M^J'Renegade''s internal DOS emulator.  Supported command are limited.'^M^J^M^J);
	end;

  procedure docmd(const cmd:astr);
	var fi:file of byte;
			f:file;
			ps,ns,es,op,np:astr;
			s1,s2,s3:astr;
			numfiles,tsiz:longint;
			retlevel,i,j:byte;
			b,ok:boolean;

	begin
		abort:=FALSE; next:=FALSE; nocmd:=FALSE;
		for i:=1 to 9 do xword[i]:=allcaps(xword[i]);
		s:=xword[1];

		if (s='?') or (s='HELP') then printf('doshelp')
		else
		if (s='EDIT') then begin
			if ((exist(xword[2])) and (xword[2]<>'')) then tedit(xword[2])
			else
				if (xword[2]='') then tedit1 else tedit(xword[2]);
		end
		else
		if (s='EXIT') then done:=TRUE
		else
		if (s='DEL') then begin
			if ((not exist(xword[2])) and (not iswildcard(xword[2]))) or
				 (xword[2]='') then
				print('File not found.')
			else begin
				xword[2]:=fexpand(xword[2]);
        findfirst(xword[2], anyfile - VolumeID - Directory, dirinfo);
				if (not iswildcard(xword[2])) or (pynq('Are you sure? ')) then
          repeat
            kill(dirinfo.name);
            findnext(dirinfo);
          until (Doserror <> 0) or (hangup);
			end;
		end
		else
		if (s='TYPE') then begin
			printf(fexpand(xword[2]));
			if (nofile) then print('File not found.');
		end
		else
		if (copy(s,1,3)='REN') then begin
			if ((not exist(xword[2])) and (xword[2]<>'')) then
				print('File not found.')
			else begin
				xword[2]:=fexpand(xword[2]);
				assign(f,xword[2]);
				rename(f,xword[3]);
				if (ioresult <> 0) then print('File not found.');
			end
		end
		else
		if (s='DIR') then begin
			b:=TRUE;
			for i:=2 to 9 do if (xword[i]='/W') then begin
				b:=FALSE;
				xword[i]:='';
			end;
			if (xword[2]='') then xword[2]:='*.*';
			s1:=curdir;
			xword[2]:=fexpand(xword[2]);
			fsplit(xword[2],ps,ns,es);
			s1:=ps; s2:=ns+es;
			if s2[1]='.' then s2:='*'+s2;
			if (s2='') then s2:='*.*';
			if (pos('.', s2) = 0) then s2 := s2 + '.*';
      if (not iswildcard(xword[2])) then
        begin
          findfirst(xword[2], anyfile, dirinfo);
          if ((Doserror = 0) and (dirinfo.attr=directory)) or
             ((length(s1)=3) and (s1[3]='\')) then
            begin   {* root directory *}
              s1:=bslash(TRUE,xword[2]);
              s2:='*.*';
            end;
        end;
			nl; dir(s1,s2,b); nl;
		end
		else
		if ((s='CD') or (s='CHDIR')) and (xword[2]<>'') or (copy(s,1,3)='CD\') then begin
			if copy(s,1,3)='CD\' then xword[2]:=copy(s,3,length(s)-2);
			xword[2]:=fexpand(xword[2]);
			chdir(xword[2]);
			if (ioresult<>0) then print('Invalid pathname.');
		end
		else
		if ((s='MD') or (s='MKDIR')) and (xword[2]<>'') then begin
			mkdir(xword[2]);
			if (ioresult<>0) then print('Unable to create directory.');
		end
		else
		if ((s='RD') or (s='RMDIR')) and (xword[2]<>'') then begin
			rmdir(xword[2]);
			if (ioresult<>0) then print('Unable to remove directory.');
		end
		else
		if (s='COPY') then begin
			if (xword[2]<>'') then begin
				if (iswildcard(xword[3])) then
					print('Wildcards not allowed in destination parameter!')
				else begin
					if (xword[3]='') then xword[3]:=curdir;
					xword[2]:=bslash(FALSE,fexpand(xword[2]));
					xword[3]:=fexpand(xword[3]);
          findfirst(xword[3], anyfile, dirinfo);
          b:=((Doserror = 0) and (dirinfo.attr and directory=directory));
					if ((not b) and (copy(xword[3],2,2)=':\') and
							(length(xword[3])=3)) then b:=TRUE;

					fsplit(xword[2],op,ns,es);
					op:=bslash(TRUE,op);

					if (b) then
						np:=bslash(TRUE,xword[3])
					else begin
						fsplit(xword[3],np,ns,es);
						np:=bslash(TRUE,np);
					end;

					j:=0;
					abort:=FALSE; next:=FALSE;
          findfirst(xword[2], anyfile - directory - volumeid, dirinfo);
          while (Doserror = 0) and (not abort) and (not hangup) do
            begin
							s1:=op+dirinfo.name;
							if (b) then s2:=np+dirinfo.name else s2:=np+ns+es;
							prompt(s1+' -> '+s2+' :');
							copyfile(ok,nospace,TRUE,s1,s2);
							if (ok) then begin
								inc(j);
								nl;
							end else
								if (nospace) then prompt('^7 - *Insufficient space*')
								else prompt('^7 - *Copy failed*');
							nl;
              if (not empty) then wkey;
              findnext(dirinfo);
            end;
					if (j<>0) then begin
						prompt('  '+cstr(j)+' file');
						if (j<>1) then prompt('s');
						print(' copied.');
					end;
				end;
			end;
		end
		else
		if (s='MOVE') then begin
			if (xword[2]<>'') then begin
				if (iswildcard(xword[3])) then
					print('Wildcards not allowed in destination parameter!')
				else begin
					if (xword[3]='') then xword[3]:=curdir;
					xword[2]:=bslash(FALSE,fexpand(xword[2]));
					xword[3]:=fexpand(xword[3]);
          findfirst(xword[3], anyfile, dirinfo);
          b:=((Doserror = 0) and (dirinfo.attr and directory=directory));
					if ((not b) and (copy(xword[3],2,2)=':\') and
							(length(xword[3])=3)) then b:=TRUE;

					fsplit(xword[2],op,ns,es);
					op:=bslash(TRUE,op);

					if (b) then
						np:=bslash(TRUE,xword[3])
					else begin
						fsplit(xword[3],np,ns,es);
						np:=bslash(TRUE,np);
					end;

					j:=0;
					abort:=FALSE; next:=FALSE;
          findfirst(xword[2], anyfile - directory - volumeid, dirinfo);
          while (Doserror = 0) and (not abort) and (not hangup) do
            begin
              s1:=op+dirinfo.name;
              if (b) then s2:=np+dirinfo.name else s2:=np+ns+es;
              prompt(s1+' -> '+s2+' :');
              movefile(ok,nospace,TRUE,s1,s2);
              if (ok) then begin
                inc(j);
                nl;
              end else
                if (nospace) then prompt('^7 - *Insufficient space*')
                else prompt('^7 - *Move Failed*');
              nl;
              if (not empty) then wkey;
              findnext(dirinfo);
            end;
					if (j<>0) then begin
						prompt('  '+cstr(j)+' file');
						if (j<>1) then prompt('s');
						print(' moved.');
					end;
				end;
			end;
		end
		else
		if (s='CLS') then cls
		else
		if (length(s)=2) and (s[1]>='A') and (s[1]<='Z') and
			 (s[2]=':') then begin
			getdir(ord(s[1])-64,s1);
			if (ioresult<>0) then print('Invalid drive.')
			else begin
				chdir(s1);
				if (ioresult<>0) then begin
					print('Invalid drive.');
					chdir(curdir);
				end;
			end;
		end
		else
		if (s='VIEW') then begin
			if (xword[2]='') then
				 print('Syntax is: "VIEW filename"')
			else begin
				s1:=xword[2];
				if (pos('.',s1)=0) then s1:=s1+'*.*';
				lfi(s1);
			end;
		end
		else
		if (s='SEND') and (xword[2]<>'') then begin
			if exist(xword[2]) then unlisted_download(fexpand(xword[2]))
				else print('File not found.');
		end
		else
		if (s='RECEIVE') then begin
			 prt('File name: ');
			 mpl(12);
			 input(s, 12);
			 s := stripname(s);
			 receive(s, '', false, junk,junk2,junk3, r);
			 if junk then
				 sysoplog('DOS emulator upload of: '+s);
		end
		else
		if (s='VER') then versioninfo
		else
		if (s='DIRSIZE') then begin
			nl;
			if (xword[2]='') then print('Needs a parameter.')
			else begin
				numfiles:=0; tsiz:=0;
        findfirst(xword[2], anyfile, dirinfo);
        while (Doserror = 0) do
          begin
            inc(tsiz,dirinfo.size);
            inc(numfiles);
            findnext(dirinfo);
          end;
				if (numfiles=0) then print('No files found!')
					else print('"'+allcaps(xword[2])+'": '+cstr(numfiles)+' files, '+
										 cstr(tsiz)+' bytes.');
			end;
			nl;
		end
		else
		if (s='diskfree') then begin
      if (xword[2]='') then
        j := ExtractDriveNumber(curdir)
      else
        j := ExtractDriveNumber(xword[2]);
      if (diskfree(j) = -1) then
        print('Invalid drive specification'^M^J)
      else
        print(^M^J + cstr(diskfree(j))+' bytes free on '+chr(j+64)+':'^M^J);
		end
		else
    if (s='EXT') then
      begin
        s1 := cmd;
        j := pos('EXT',allcaps(s1)) + 3;
        s1 := copy(s1, j, length(s1) - (j - 1));
        while (s1[1] = ' ') and (length(s1) > 0) do
          delete(s1, 1, 1);
        if (s1 <> '') then
          begin
            shel('Running "' + s1 + '"');
            shelldos(FALSE, s1, retlevel);
            shel2(FALSE);
          end;
      end
		else
		if (s='CONVERT') or (s='CVT')  then begin
			if (xword[2]='') then begin
				print(^M^J + s+' - Renegade archive conversion command.'^M^J);

				print('Syntax is:   "'+s+' <Old Archive-name> <New Archive-extension>"'^M^J);

				print('Renegade will convert from the one archive format to the other.');
				print('You only need to specify the 3-letter extension of the new format.'^M^J);
			end else begin
				if (not exist(xword[2])) or (xword[2]='') then print('File not found.')
				else begin
					i:=arctype(xword[2]);
					if (i=0) then invarc
					else begin
						s3:=xword[3]; s3:=copy(s3,length(s3)-2,3);
						j:=arctype('FILENAME.'+s3);
						fsplit(xword[2],ps,ns,es);
						if (length(xword[3])<=3) and (j<>0) then
							s3:=ps+ns+'.'+general.filearcinfo[j].ext
						else
							s3:=xword[3];
						if (j=0) then invarc
						else begin
							ok:=TRUE;
							conva(ok,i,j,sqoutsp(fexpand(xword[2])),
										sqoutsp(fexpand(s3)));
							if (ok) then
								kill(sqoutsp(fexpand(xword[2])))
							else
								star('Conversion unsuccessful.');
						end;
					end;
				end;
			end;
		end else
		if (s='UNARC') or (s='UNZIP') then begin
			if (xword[2]='') then begin
				print(^M^J + s+' - Renegade archive de-compression command.'^M^J);

				print('Syntax: '+s+' <ARCHIVE> [FILESPECS]'^M^J);

				print('The archive type can be any archive format which has been');
				print('configured into Renegade via System Configuration.'^M^J);
			end else begin
				i:=arctype(xword[2]);
				if (not exist(xword[2])) then print('File not found.') else
					if (i=0) then invarc
					else begin
						s3:='';
						if (xword[3]='') then s3:=' *.*'
						else
							for j:=3 to 9 do
								if (xword[j]<>'') then s3:=s3+' '+xword[j];
						s3:=copy(s3,2,length(s3)-1);
						execbatch(junk,bslash(TRUE,curdir),general.arcspath+
											 FunctionalMCI(general.filearcinfo[i].unarcline,xword[2],s3),0,
											 retlevel,FALSE);
					end;
			end;
		end
		else
		if ((s='ARC') or (s='ZIP') or
			 (s='PKARC') or (s='PKPAK') or (s='PKZIP')) then begin
			if (xword[2]='') then begin
				print(^M^J + s+' - Renegade archive compression command.'^M^J);

				print('Syntax is:   "'+s+' <Archive-name> Archive filespecs..."'^M^J);

				print('The archive type can be ANY archive format which has been');
				print('configured into Renegade via System Configuration.'^M^J);
			end else begin
				i:=arctype(xword[2]);
				if (i=0) then invarc
				else begin
					s3:='';
					if (xword[3]='') then s3:=' *.*'
					else
						for j:=3 to 9 do
							if (xword[j]<>'') then s3:=s3+' '+fexpand(xword[j]);
					s3:=copy(s3,2,length(s3)-1);
					execbatch(junk,bslash(TRUE,curdir),general.arcspath+
										 FunctionalMCI(general.filearcinfo[i].arcline,fexpand(xword[2]),s3),0,
										 retlevel,FALSE);
				end;
			end;
		end else begin
			nocmd:=TRUE;
			if (s<>'') then print('Bad command or file name.')
		end;
	end;

begin
	done:=FALSE;
	print(^M^J'Type "EXIT" to return to Renegade'^M^J);
	versioninfo;
	repeat
		getdir(0, curdir);
		prompt('^1'+curdir+'>'); inputl(s1, 128); parse(s1);
		check_status;
		docmd(s1);
		if (not nocmd) then sysoplog('> '+s1);
	until (done) or (hangup);
	chdir(start_dir);
end;

procedure uploadall;
var
  bn:integer;
  filemask:string;
  sall:boolean;

  procedure uploadfiles(b:integer);
  var
    fi:file of byte;
    f:ulfrec;
    v:verbrec;
    fn:astr;
    oldboard,rn,gotpts,i:integer;
    c:char;
    flagall,ok,firstone, gotdesc:boolean;
  begin
    oldboard := fileboard;
    firstone := TRUE;
    flagall := FALSE;
    if (fileboard <> b) then
      changefileboard(b);
    if (fileboard=b) then
      begin
      loadfileboard(fileboard);
      print(^M^J'Scanning ^5'+memuboard.name+'^1 ('+memuboard.dlpath+')');
      findfirst(memuboard.dlpath+filemask, anyfile - volumeid - directory - dos.hidden, dirinfo);
      abort := false;
      while (Doserror = 0) and (not abort) do
        begin
        wkey;
        fn:=align(dirinfo.name);
        recno(fn,rn); { loads memuboard again .. }
        if (rn=-1) then
          begin
          assign(fi,memuboard.dlpath+fn);
          reset(fi);
          if (ioresult=0) then
            begin
            f.blocks:=filesize(fi) div 128;
            f.sizemod:=filesize(fi) mod 128;
            close(fi);
            if (firstone) then display_board_name;
            firstone:=FALSE;
            gotdesc := FALSE;
            if (General.FileDiz) and (DizExists(memuboard.dlpath+fn)) then
              begin
              GetDiz(f, v);
              star('Complete.');
              dyny := TRUE;
              prompt(' ^3'+fn+' ^4'+mrn(cstr(f.blocks div 8),4)+'k :');
              if (flagall) then
                ok := TRUE
              else
                begin
                prt('Upload (Yes, No, All, Quit)? ');
                onek(c, 'YNQA');
                Ok := (C = 'Y') or (C = 'A');
                flagall := (C = 'A');
                abort := (C = 'Q');
                end;
              gotdesc := TRUE;
              end
            else
              begin
              prompt(' ^3'+fn+' ^4'+mrn(cstr(f.blocks div 8),4)+'k :');
              mpl(50); inputl(f.description,50);
              ok:=TRUE;
              if (f.description <> '') and (f.description[1] = '.') then
                begin
                if (length(f.description)=1) then
                  begin
                  abort:=TRUE;
                  exit;
                  end;
                c:=upcase(f.description[2]);
                case c of
                  'D':begin
                      erase(fi);
                      i:=ioresult;
                      ok:=FALSE;
                      end;
                  'N':begin
                      next:=TRUE;
                      exit;
                      end;
                  'S':ok:=FALSE;
                end; { case }
                end; { if }
              end; { else }
            if (ok) then
              begin
              if (not gotdesc) then
                begin
                v.descr[1]:='';
                i:=1;
                repeat
                  prt(mln('',20) + ':');
                  mpl(50);
                  inputl(v.descr[i],50);
                  if (v.descr[i]='') then i := MAXEXTDESC;
                  inc(i);
                until ((i = MAXEXTDESC + 1) or (hangup));
                nl;
                end;
              doffstuff(f, fn, gotpts);
              if (v.descr[1]<>'') then
                f.vpointer := NewVPointer
              else
                f.vpointer := -1;
              writefv(filesize(DirFile), f, v);
              sysoplog('^3Upload '+sqoutsp(fn)+' to '+memuboard.name);
              end; { end if ok }
            end; { end if ioresult = 0 }
          end; { end if rn = -1 }
        findnext(dirinfo);
        end; { while }
      end; { if fileboard = b }
    fileboard:=oldboard;
  end; { end procedure uploadfiles(b:integer); }

begin
  print(^M^J'Upload files into directories -');
  
  abort := FALSE; next := FALSE; filemask := '';
  sall := pynq('Search all directories? ');

  if pynq('Search by file spec? ') then
    begin
    prompt('Filemask [ENTER]=''*.*'': ');
    input(filemask,12);
    if (filemask = '') then
      filemask := '*.*';
    end
  else
    filemask := '*.*';

  print(^M^J'Enter . to end processing, .S to skip the file, .N to skip to');
  print('the next directory, and .D to delete the file.'^M^J);
  pausescr(FALSE);
  if (sall) then
    begin
      bn:=0;
      while (not abort) and (bn <= MaxFBases) and (not hangup) do
        begin
          if (fbaseac(bn)) then
            uploadfiles(bn);
          inc(bn);
          wkey;
        end;
    end
  else
    uploadfiles(fileboard);
end;

end.

