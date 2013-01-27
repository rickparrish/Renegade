{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Voting editor, conference editor}

unit sysop10;

interface

uses crt, dos, overlay, common;

procedure editvotes;
procedure confeditor;

implementation

uses vote;

procedure editvotes;
var vfile:file of votingr;
    ii,i,j:integer;
    topic:votingr;
    u1:userrec;
    c:char;
    s:astr;

  procedure removevote(var u2:userrec);
  var j:integer;
  begin
      move(u2.vote[ii + 1], u2.vote[ii], 25 - ii);
      u2.vote[25]:=0;
  end;

  procedure editchoices;
  var j:integer;
  begin
    sl1('Editing topic '+cstr(i)+' choice: '+topic.choices[i].description);
    repeat
      if c<>'?' then begin
        cls;
        abort:=FALSE;
        print('^1Topic choice #'+cstr(i)+' of '+cstr(topic.choicenumber) + ^M^J);

        printacr('^11. Line 1: ^5'+topic.choices[i].description);
        printacr('^12. Line 2: ^5'+topic.choices[i].description2);
        printacr('^13. Voters: ^5'+cstr(topic.choices[i].numvoted));
        printacr('^14. Delete choice');
        printacr('^1Q. Quit');
      end;
      prt(^M^J'Edit menu (?=Help) : '); onek(c,'Q1234?[]JFL'^M);
      nl;
      case c of
        '?':begin
              print('^1<CR>Redisplay screen');
              print('1-4:Modify item');
              lcmds(15,3,'[Back entry',']Forward entry');
              lcmds(15,3,'Jump to entry','First entry in list');
              lcmds(15,3,'Quit and save','Last entry in list');
              nl;
            end;
        '1':begin
              prt('Line 1: '); mpl(65);
              inputwc(topic.choices[i].description,65);
            end;
        '2':begin
              prt('Line 2: '); mpl(65);
              inputwc(topic.choices[i].description2,65);
              if topic.choices[i].description2=' ' then
                 topic.choices[i].description2:='';
            end;
        '3':begin
              prt('New number of voters: ');
              input(s,3);
              if s<>'' then topic.choices[i].numvoted:=value(s);
            end;
        '4':if pynq('Are you sure? ') then begin
               dec(topic.choicenumber);
               sl1('Deleted topic '+cstr(i)+' choice: '+topic.choices[i].description);
               topic.numvoted:=topic.numvoted-topic.choices[i].numvoted;
               if i<25 then begin
                 for j:=i to topic.choicenumber do begin
                     topic.choices[j].description:=topic.choices[j+1].description;
                     topic.choices[j].description2:=topic.choices[j+1].description2;
                     topic.choices[j].numvoted:=topic.choices[j+1].numvoted;
                 end;
               end;
               reset(uf);
               j:=filesize(uf);
               for j:=1 to j-1 do begin
                  seek(uf, j);
                  read(uf, u1);
                  if u1.vote[ii]=i then u1.vote[ii]:=0
                     else if u1.vote[ii]>i then dec(u1.vote[ii]);
                  seek(uf, j);
                  write(uf, u1);
               end;
               close(uf);
               if thisuser.vote[ii]=i then thisuser.vote[ii]:=0;
               c:='Q';
            end;
        '[':if i>1 then dec(i) else c:=' ';
        ']':if i<topic.choicenumber then inc(i) else c:=' ';
        'F':if i<>1 then i:=1 else c:=' ';
        'J':begin
              prt('Jump to entry: ');
              input(s,3);
              if (value(s)>=0) and (value(s)<=topic.choicenumber) then i:=value(s) else c:=' ';
            end;
        'L':if i<>topic.choicenumber then i:=topic.choicenumber else c:=' ';
      end;
    until (c='Q') or (hangup);
    c:=' ';
    Lasterror := IOResult;
  end;

  procedure edittopics;
  var changed:boolean;
      xloaded:integer;
      j:integer;

  begin
    xloaded:=0;
    prt('Begin editing at which? (1-'+cstr(filesize(vfile))+') : '); inu(ii);
    if (ii>0) and (ii<=filesize(vfile)) then begin
      c:=' ';
      while (c<>'Q') and (not hangup) do begin
        if (xloaded<>ii) then begin
           seek(vfile,ii-1); read(vfile,topic);
           xloaded:=ii;
           sl1('Edited topic '+cstr(ii));
        end;
        repeat
          if c<>'?' then begin
            cls;
            abort:=FALSE;next:=FALSE;
            printacr('^1Voting topic #'+cstr(ii)+' of '+cstr(filesize(vfile)) + ^M^J);

            printacr('^11. Topic        : ^5'+topic.description);
            printacr('^12. Creator      : ^5'+topic.madeby);
            printacr('^13. ACS to vote  : ^5"'+topic.acs+'"');
            printacr('^14. ACS to add   : ^5"'+topic.addchoicesacs+'"');
            printacr('^15. # of votes   : ^5'+cstr(topic.numvoted));
            printacr('^1   # of choices : ^5'+cstr(topic.choicenumber));
            printacr('^16. Reset voting');
            printacr('^17. Edit choices');
            printacr('^18. Add a choice');
            printacr('^1Q. Quit');
          end;
          prt(^M^J'Edit menu (?=Help) : '); onek(c,'Q12345678?[]JFL'^M);
          nl;
          case c of
            '?':begin
                  print('^1<CR>Redisplay screen');
                  print('1-7:Modify item');
                  lcmds(15,3,'[Back entry',']Forward entry');
                  lcmds(15,3,'Jump to entry','First entry in list');
                  lcmds(15,3,'Quit and save','Last entry in list');
                  nl;
                end;
            '1':begin
                  prt('New topic: ');
                  inputwnwc(topic.description,65,changed);
                end;
            '2':begin
                  prt('New creator: ');
                  inputwnwc(topic.madeby,35,changed);
                end;
            '3':begin
                  prt('New voting ACS: '); mpl(20);
                  inputwn(topic.acs,20,changed);
                end;
            '4':begin
                  prt('New add choices ACS: '); mpl(20);
                  inputwn(topic.addchoicesacs,20,changed);
                 end;
            '5':begin
                  prt('New number of voters: ');
                  input(s,3);
                  if s<>'' then topic.numvoted:=value(s);
                end;
            '6':if pynq('Reset voting? ') then begin
                   topic.numvoted:=0;
                   for j:=1 to topic.choicenumber do topic.choices[j].numvoted:=0;
                   reset(uf);
                   j:=filesize(uf);
                   for j:=1 to j-1 do begin
                      loadurec(u1,j);
                      u1.vote[ii]:=0;
                      saveurec(u1,j);
                   end;
                   close(uf);
                   thisuser.vote[ii]:=0;
                end;
            '7':if topic.choicenumber>0 then begin
                  cls;
                  print('^1Choice editor'^M^J);
                  abort:=FALSE; next:=FALSE;
                  for j:=1 to topic.choicenumber do begin
                      printacr('^1'+mrn(cstr(j),2)+'. ^5'+topic.choices[j].description);
                      if topic.choices[j].description2<>'' then
                         printacr('^1    ^5'+topic.choices[j].description2);
                  end;
                  prt(^M^J'Begin editing at which? (1-'+cstr(topic.choicenumber)+') : ');
                  inu(i);
                  if (i>0) and (i<=topic.choicenumber) then begin
                     editchoices;
                  end;
                end;
            '8':if pynq('Add choice '+cstr(topic.choicenumber+1)+'? ') then begin
                   prt(^M^J'Line 1: ');
                   inputwc(topic.choices[topic.choicenumber+1].description,65);
                   if topic.choices[topic.choicenumber+1].description<>'' then begin
                      inc(topic.choicenumber);
                      topic.choices[topic.choicenumber].numvoted:=0;
                      prt('Line 2: ');
                      inputwc(topic.choices[topic.choicenumber].description2,65);
                   end else prt('Aborted.');
                end;
            '[':if ii>1 then dec(ii) else c:=' ';
            ']':if ii<filesize(vfile) then inc(ii) else c:=' ';
            'F':if ii<>1 then ii:=1 else c:=' ';
            'J':begin
                  prt('Jump to entry: ');
                  input(s,3);
                  if (value(s)>=0) and (value(s)<=filesize(vfile)) then ii:=value(s) else c:=' ';
                end;
            'L':if ii<>filesize(vfile) then ii:=filesize(vfile) else c:=' ';
          end;
        until (pos(c,'Q[]FJL')<>0) or (hangup);
        seek(vfile,xloaded-1); write(vfile,topic);
      end;
    end;
    c:=' ';
    Lasterror := IOResult;
  end;

begin
  assign(vfile,general.datapath+'voting.dat');
  reset(vfile);
  if (ioresult = 2) then
    rewrite(vfile);
  repeat
    if (c<>'?') then
      listtopics(TRUE);
    prt('Voting topic editor (?=help) : ');
    onek(c,'QDAM?'^M);
    case c of
      '?':begin
            print(^M^J'^1<^3CR^1>Redisplay screen');
            lcmds(16,3,'Delete topic','Add topic');
            lcmds(16,3,'Modify topic','Quit');
          end;
      'D':if filesize(vfile)>0 then begin
            prt('Voting topic to delete? (1-'+cstr(filesize(vfile))+') : '); inu(ii);
            if (ii>0) and (ii<=filesize(vfile))  then begin
              seek(vfile,ii-1); read(vfile,topic);
              print(^M^J'Voting topic: ^5'+topic.description);
              if pynq('Delete this? ') then begin
                sysoplog('* Deleted voting topic: '+topic.description);
                if ii<filesize(vfile) then
                  for i:=ii to filesize(vfile)-1 do begin
                    seek(vfile,i); read(vfile,topic);
                    seek(vfile,i-1); write(vfile,topic);
                end;
                seek(vfile,filesize(vfile)-1);
                truncate(vfile);
                close(vfile);
                reset(vfile);
                reset(uf);
                j:=filesize(uf);
                for i := 1 to j - 1 do
                  begin
                    seek(uf, i);
                    read(uf, u1);
                    removevote(u1);
                    seek(uf, i);
                    write(uf, u1);
                  end;
                close(uf);
                removevote(thisuser);
              end;
            end;
          end;
      'A':if (filesize(vfile) < 25) then
            begin
              nl;
              if pynq('Add a new voting topic? ') then
                addtopic;
            end;
      'M':if (filesize(vfile) > 0) then
            edittopics;
    end;
  Lasterror := IOResult;
  until (c='Q') or (hangup);
  close(vfile);
end;

procedure confeditor;
var i:integer;
    c:char;
begin
  reset(conf);
  read(conf,confr);
  repeat
    if c<>'?' then begin
       cls;
       abort:=FALSE; next:=FALSE;
       printacr('^0N'+seperator+mln('Title',40)+seperator+'ACS');
       printacr('^4=:========================================:====================');
       abort:=FALSE; next:=FALSE;
       i:=1;
       while (i<=27) and (not abort) and (not hangup) do begin
           c:=chr(i+63);
           if confr.conference[c].name<>'' then printacr('^0'+c+' ^3'+
              mln(confr.conference[c].name,41)+
              confr.conference[c].acs);
           inc(i);
       end;
       abort:=FALSE; next:=FALSE;
    end;
    prt(^M^J'Conference editor (?=help) : ');
    onek(c,'QDIM?'^M);
    case c of
      'D':begin
            prt('Delete which conference (A-Z)? ');
            c:=upcase(char(getkey));
            print(c + ^M^J);
            if (c>='A') and (c<='Z') and (confr.conference[c].name<>'') then begin
               confr.conference[c].name:='';
            end;
            c := #0;
          end;
      'I':begin
            prt('Insert which conference (A-Z)? ');
            c:=upcase(char(getkey));
            print(c + ^M^J);
            if (c>='@') and (c<='Z') and (confr.conference[c].name='') then begin
               confr.conference[c].name:='<< Not Defined >>';
               confr.conference[c].acs:='';
            end;
            c := #0;
          end;
      '?':begin
            print(^M^J'^1<^3CR^1>Redisplay screen');
            lcmds(20,3,'Insert conference','Modify conference');
            lcmds(20,3,'Delete conference','Quit');
          end;
      'M':begin
            prt('Modify which conference (@,A-Z)? ');
            c:=upcase(char(getkey));
            print(c + ^M^J);
            if (c>='@') and (c<='Z') and (confr.conference[c].name<>'') then begin
               prt('Conference name: ');
               inputdefault(confr.conference[c].name,confr.conference[c].name,40,'lc',TRUE);
               prt('Conference ACS : ');
               inputdefault(confr.conference[c].acs,confr.conference[c].acs,20,'l',TRUE);
            end;
            c := #0;
          end;
    end;
  until (c='Q') or hangup;
  seek(conf,0); write(conf,confr);
  close(conf);
  Lasterror := IOResult;
end;

end.
