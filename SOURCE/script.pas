{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Script system. }

unit Script;

interface

uses crt, dos, overlay, common;

procedure readq(const filen:astr);
procedure readasw(usern:integer; fn:astr);
procedure readasw1(fn:astr);

implementation

uses doors, user;

procedure readq(const filen:astr);
var infile,outfile,outfile1:text;
    outp,lin,s,mult,got,lastinp,ps,ns,es,infilename,outfilename:astr;
    i,x:integer;
    c:char;

  procedure gotolabel(got:astr);
  var s:astr;
    x:byte;
  begin
    got:=':'+allcaps(got);
    reset(infile);
    repeat
      readln(infile,s);
    until (eof(infile)) or (allcaps(s)=got);
  end;

  procedure dumptofile;
  var
    WriteOut:boolean; { goes to false when passing OLD infoform }
    NewOutFile:text;
  begin
      { output answers to *.ASW file, and delete temporary file }
    assign(NewOutFile, General.MiscPath + 'INF' + cstr(Node) + '.TMP');

    rewrite(NewOutFile);
    reset(outfile);

    WriteOut := TRUE;

    while (not eof(outfile)) do
      begin
        readln(outfile, s);
        if (pos('User: '+Caps(ThisUser.Name), s) > 0) then
          WriteOut := FALSE
        else
          if (not WriteOut) then
            if (pos('User: ', s) > 0) then
              WriteOut := TRUE;
        if (WriteOut) then
          writeln(NewOutFile, s);
      end;

    reset(outfile1);
    while (not eof(outfile1)) do
      begin
        readln(outfile1, s);
        writeln(NewOutFile, s);
      end;

    close(outfile1);
    close(outfile);
    close(NewOutFile);
    kill(General.MiscPath + ns + '.ASW');
    erase(outfile1);
    rename(NewOutFile, General.MiscPath + ns + '.ASW');

    Lasterror := IOResult;
  end;

begin
  infilename:=filen;
  fsplit(infilename,ps,ns,es);
  infilename:=ps+ns+'.INF';
  if (not exist(infilename)) then
    begin
      infilename:=general.miscpath+ns+'.INF';
      if (not exist(infilename)) then begin
        s:='* Infoform not found: '+filen;
        sysoplog(s);
        exit;
      end;
      if (OkAvatar) and exist(general.miscpath+ns+'.INV') then
        infilename := general.miscpath+ns+'.INV'
      else
        if (OkAnsi) and exist(general.miscpath+ns+'.INA') then
          infilename := general.miscpath+ns+'.INA';
    end
  else
    if (OkAvatar) and exist(ps+ns+'.INV') then
      infilename := ps+ns+'.INV'
    else
      if (OkAnsi) and exist(ps+ns+'.INA') then
        infilename := ps+ns+'.INA';

  assign(infile,infilename);
  reset(infile);
  if (ioresult <> 0) then
    begin
      sysoplog('* Infoform not found: '+filen);
      sysoplog(s);
      exit;
    end;

  fsplit(infilename,ps,ns,es);
  outfilename:=general.miscpath + ns + '.ASW';

  assign(outfile1, general.miscpath + 'TMP' + cstr(node) + '.ASW');
  rewrite(outfile1);
  sysoplog('* Answered InfoForm "'+filen+'"');

  assign(outfile, outfilename);
  writeln(outfile1,'User: '+caps(thisuser.name));
  writeln(outfile1,'Date: '+dat);
  writeln(outfile1);

  nl;
  printingfile:=TRUE;
  repeat
    abort:=FALSE;
    {readln(infile,outp);}
        x:=0;
        repeat
          inc(x);
          read(infile,outp[x]);
          if eof(infile) then                {check again incase avatar parameter}
            begin
              inc(x);
              read(infile,outp[x]);
              if eof(infile) then dec(x);
            end;
        until ((outp[x] = ^M) and not (outp[x - 1] in [^V,^Y])) or (x = 159) or eof(infile) or hangup;

        outp[0] := chr(x);

        if (pos(^[,outp) > 0) or (pos(^V,outp) > 0) then
          begin
            croff:=TRUE;
            ctrljoff:=TRUE;
          end
        else
          begin
            if outp[x] = ^M then dec(outp[0]);
            if outp[1] = ^J then delete(outp,1,1);
          end;

    if (pos('*',outp)<>0) and (outp[1] <> ';') then outp:=';A'+outp;
    if (length(outp)=0) then nl else
      case outp[1] of
        ';':begin
              if (pos('*',outp)<>0) then
                if (outp[2]<>'D') then outp:=copy(outp,1,pos('*',outp)-1);
              lin:=copy(outp, 3, 255);
              i:=80 - length(lin);
              s:=copy(outp,1,2);
              if (s[1]=';') then
                case s[2] of
                  'R','F','V','C','D','G','I','K','L','Q','S','T',';':i:=1; { do nothing }
                else
                  if (lin[1] = ';') then
                    prompt(copy(lin,2,255))
                  else
                    prompt(lin);
                end;
              s:=#1#1#1;
              case outp[2] of
                'A':inputl(s,i);
                'B':input(s,i);
                'C':begin
                      mult:=''; i:=1;
                      s:=copy(outp,pos('"',outp),length(outp)-pos('"',outp));
                      repeat
                        mult:=mult+s[i];
                        inc(i);
                      until (s[i]='"') or (i>length(s));
                      lin:=copy(outp,i+3,length(s)-(i-1));
                      prompt(lin);
                      onek(c,mult);
                      s:=c;
                    end;
                'D':begin
                      dodoorfunc(outp[3],copy(outp,4,length(outp)-3));
                      s:=#0#0#0;
                    end;
                'F':begin
                      changearflags(copy(outp,3,255));
                      outp := #0#0#0
                    end;
                'G':begin
                      got:=copy(outp,3,length(outp)-2);
                      gotolabel(got);
                      s:=#0#0#0;
                    end;
                'S':begin
                      delete(outp, 1, 3);
                      if aacs(copy(outp, 1, pos('"', outp) - 1)) then
                        begin
                          got := copy(outp, pos(',', outp) + 1, 255);
                          gotolabel(got);
                        end;
                      s:=#0#0#0;
                    end;
                'H':hangup:=TRUE;
                'I':begin
                      mult:=copy(outp,3,length(outp)-2);
                      i:=pos(',',mult);
                      if i<>0 then begin
                        got:=copy(mult,i+1,length(mult)-i);
                        mult:=copy(mult,1,i-1);
                        if allcaps(lastinp)=allcaps(mult) then
                          begin
                            gotolabel(got);
                          end;
                      end;
                      s:=#1#1#1;
                      outp:=#0#0#0;
                    end;
                'K':begin
                      close(infile);
                      close(outfile1); erase(outfile1);
                      sysoplog('* InfoForm aborted.');
                      printingfile:=FALSE;
                      exit;
                    end;
                'L':begin
                      s :=copy(outp,3,length(outp)-2);
                      writeln(outfile1,MCI(s));
                      s:=#0#0#0;
                    end;
                'Q':begin
                      while not eof(infile) do
                        readln(infile, s);
                      s:=#0#0#0;
                    end;
                'R':begin
                      changeacflags(copy(outp,3,255));
                      outp := #0#0#0;
                    end;
                'T':begin
                      s:=copy(outp,3,length(outp)-2);
                      printf(s);
                      s:=#0#0#0;
                    end;
                'Y':begin
                      dyny := TRUE;
                      if yn then s:='YES' else s:='NO';
                      if (lin[1] = ';') then outp := #0#0#0;
                    end;
                'N':begin
                      if yn then s:='YES' else s:='NO';
                      if (lin[1] = ';') then outp := #0#0#0
                    end;
                'V':if upcase(outp[3]) in ['A'..'Z'] then
                      autovalidate(thisuser,usernum, upcase(outp[3]));
                ';':s:=#0#0#0;
              end;
              if (s<>#1#1#1) then begin
                if (outp <> #0#0#0) then
                  outp:=lin+s;
                lastinp:=s;
              end;
              if (s=#0#0#0) then outp:=#0#0#0;
            end;
        ':':outp:=#0#0#0;
      else
         printacr(outp);
      end;
    if (outp<>#0#0#0) then begin
      if (pos('%CL',outp)<>0) then delete(outp,pos('%CL',outp),3);
      writeln(outfile1,MCI(outp));
    end;
  until ((eof(infile)) or (hangup));

  close(outfile1);
  close(infile);

  if (hangup) then
    begin
      writeln(outfile1);
      writeln(outfile1,'** HUNG UP **');
    end
  else
    dumptofile;

  printingfile:=FALSE;
  Lasterror := IOResult;
end;

procedure readasw(usern:integer; fn:astr);
var qf:text;
    user:userrec;
    qs,ps,ns,es:astr;
    i:integer;
    userfound:boolean;

  procedure exactmatch;
  begin
    reset(qf);
    repeat
      readln(qf,qs);
      if (pos('User: '+Caps(User.Name), qs) > 0) then
        UserFound := TRUE;
      if (not empty) then wkey;
    until (eof(qf)) or (userfound) or (abort);
  end;

begin
  if ((usern >= 1) and (usern < maxusers)) then begin
    loadurec(user,usern);
  end else begin
    print('Invalid user number.');
    exit;
  end;

  abort:=FALSE; next:=FALSE;
  fsplit(fn,ps,ns,es);
  fn:=general.miscpath+ns+'.ASW';
  if (not exist(fn)) then begin
    fn:=general.datapath+ns+'.ASW';
    if (not exist(fn)) then begin
      print('Answers file not found.');
      exit;
    end;
  end;
  assign(qf,fn);
  reset(qf);
  if (ioresult<>0) then
    print('"'+fn+'": unable to open.')
  else
    begin
      userfound:=FALSE;
      exactmatch;

      if (not userfound) and (not abort) then
        print('That user has not completed the questionnaire.')
      else
        begin
          if CoSysOp then
            print(qs);
          repeat
            wkey;
            readln(qf,qs);
            if (copy(qs, 1, 6) <> 'Date: ') or CoSysOp then
              if (copy(qs, 1, 6)<>'User: ') then
                printacr(qs)
              else
                userfound:=FALSE;
          until eof(qf) or (not userfound) or (abort) or (hangup);
        end;
        close(qf);
    end;
  Lasterror := IOResult;
end;

procedure readasw1(fn:astr);
var ps,ns,es:astr;
    usern:integer;
begin
  if (fn='') then begin
    prt('Enter filename: '); mpl(8); input(fn,8);
    nl;
    if (fn='') then exit;
  end;
  fsplit(fn,ps,ns,es);
  fn:=allcaps(general.datapath+ns+'.ASW');
  if (not exist(fn)) then begin
    fn:=allcaps(general.miscpath+ns+'.ASW');
    if (not exist(fn)) then begin
      print('InfoForm answer file not found: "'+fn+'"');
      exit;
    end;
  end;
  nl;
  print('Enter the name of the user to view: ');
  prt(':'); finduserws(usern);
  if (usern<>0) then
    readasw(usern,fn)
  else
    if (CoSysOp) then
      begin
        nl;
        if pynq('List entire answer file? ') then
          begin
            nl;
            printf(ns+'.ASW');
          end;
      end;
end;

end.
