{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ The voting section. }

unit vote;

interface

uses crt, dos, overlay, common;

function unvotedtopics:byte;
procedure listtopics(InEditor:boolean);
procedure voteall;
procedure voteone(WhichOne:integer);
procedure topicresults(TopicNumber:integer; u1:userrec; listvoters:boolean);
procedure results(listvoters:boolean);
procedure govote(TopicNumber:integer);
procedure trackuser;
procedure addtopic;

var
  MaxTopics:byte;
  AvailableTopics:array[1..25] of byte;
  topic:votingr;


implementation

uses user;

procedure gettopics(InEditor:boolean);
var
  RealTopicNumber:integer;
begin
  MaxTopics := 0;
  reset(VotingFile);
  for RealTopicNumber := 1 to filesize(VotingFile) do
    begin
      read(VotingFile,topic);
      if aacs(topic.acs) or CoSysOp or InEditor then
        begin
          inc(MaxTopics);
          AvailableTopics[MaxTopics] := RealTopicNumber;
       end;
    end;
  close(VotingFile);
  Lasterror := IOResult;
end;

function unvotedtopics:byte;
var
  TopicNumber:byte;
  HowMany:byte;
begin
  HowMany := 0;
  reset(VotingFile);
  seek(VotingFile,0);
  for TopicNumber := 1 to filesize(VotingFile) do
    begin
      read(VotingFile,topic);
      if aacs(topic.acs) and (thisuser.vote[TopicNumber] = 0) then
        inc(HowMany);
    end;
  close(VotingFile);
  Lasterror := IOResult;
  unvotedtopics := HowMany;
end;

procedure listtopics(InEditor:boolean);
var
  TopicNumber:byte;
begin
  GetTopics(InEditor);
  reset(VotingFile);
  cls;
  abort := FALSE;
  next := FALSE;
  printacr('|03ÚÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
  printacr('³|11|17 Num |03|16³|11|17Votes|03|16³|11|17 Choice                                   '+
           '                       |03|16³');
  printacr('ÀÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');

  seek(VotingFile,0);
  TopicNumber := 1;
  while (TopicNumber <= MaxTopics) and (not abort) and (not hangup) do
    begin
      seek(VotingFile, AvailableTopics[TopicNumber] - 1);
      read(VotingFile,topic);
      printacr('|07' + mrn(cstr(TopicNumber),5) + '|10' + mrn(cstr(topic.numvoted),7) +
             + '|14  ' + topic.description);
      inc(TopicNumber);
    end;
  nl;
  close(VotingFile);
  if (novice in thisuser.flags) then
    pausescr(FALSE);
end;

procedure voteall;
var
  TopicNumber:byte;
begin
  if (rvoting in thisuser.flags) then begin
     print('You are restricted from voting.'^M^J);
     pausescr(FALSE);
     exit;
  end;
  gettopics(FALSE);
  TopicNumber := 1;
  abort := FALSE;
  while (TopicNumber <= MaxTopics) and not (abort) do
    begin
      if (thisuser.vote[AvailableTopics[TopicNumber]] = 0) then
        govote(AvailableTopics[TopicNumber]);
      inc(TopicNumber);
    end;
end;

procedure voteone(WhichOne:integer);
begin
  gettopics(FALSE);
  if (WhichOne > 0) and (WhichOne <= MaxTopics) then
    begin
      if (thisuser.vote[AvailableTopics[WhichOne]] > 0) and not
         aacs(general.changevote) then
        begin
          print(^M^J'You can only vote once!'^M^J);
          pausescr(FALSE);
        end
      else
        govote(AvailableTopics[WhichOne]);
    end;
end;

procedure topicresults(TopicNumber:integer; u1:userrec; listvoters:boolean);
var
  x,j,k,i:integer;
  s:string[80];
begin
  gettopics(FALSE);
  cls;
  reset(VotingFile);
  abort:=FALSE;
  next:=FALSE;
  seek(VotingFile, TopicNumber - 1);
  read(VotingFile, topic);
  printacr('^5' + topic.description);
  printacr('     -'+topic.madeby + ^M^J);
  printacr('|03ÚÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
  printacr('³|11|17 N |03|16³|11|17  %  |03|16'+
           '³|11|17 Choice                                                            |03|16³');
  printacr('ÀÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');

  for x:=1 to topic.choicenumber do begin
      s:='^3'+mrn(cstr(topic.choices[x].numvoted),4)+ctp(topic.choices[x].numvoted,topic.numvoted);
      if u1.vote[TopicNumber] = x then
        s:=s + ' |12'
      else
        s:=s + ' |10';
      printacr(s+mrn(cstr(x),2)+'.'+topic.choices[x].description);
      if topic.choices[x].description2<>'' then
         printacr(mln('',13)+topic.choices[x].description2);
      if listvoters and (topic.choices[x].numvoted > 0) then
        begin
          i:=0;
          k:=topic.choices[x].numvoted;
          reset(uf);
          j:=filesize(uf) - 1;
          while (i < j) and (k > 0) and (not abort) and (not hangup) do
            begin
              inc(i);
              loadurec(u1,i);
              if u1.vote[TopicNumber] = x then
                begin
                  printacr(mln('^1',14)+caps(u1.name)+' #'+cstr(i));
                  dec(k);
                end;
            end;
          close(uf);
        end;
  end;
  nl;
  close(VotingFile);
  Lasterror := IOResult;
  pausescr(FALSE);
end;

procedure results(listvoters:boolean);
var
  s:astr;
  i:byte;
begin
  gettopics(FALSE);
  nl;
  repeat
    prt('Results of which topic (1-'+cstr(MaxTopics)+',?=List) : ');
    scaninput(s,'?Q'^M);
    if (s = '?') then
      listtopics(FALSE);
  until (s<>'?');
  i:=value(s);
  if (i > 0) and (i <= MaxTopics) then
    topicresults(AvailableTopics[i], thisuser, listvoters);
end;

procedure govote(TopicNumber:integer);
var
  x:integer;
  s,s1:astr;
begin
  if (rvoting in thisuser.flags) then begin
     print('You are restricted from voting.'^M^J);
     pausescr(FALSE);
     exit;
  end;
  gettopics(FALSE);
  cls;
  reset(VotingFile);
  seek(VotingFile,TopicNumber-1);
  read(VotingFile,topic);

  abort:=FALSE; next:=FALSE;
  printacr('^3Renegade voting'^M^J);

  printacr('^5' + topic.description);
  printacr('     -'+topic.madeby + ^M^J);
  x:=0;
  for x:=1 to topic.choicenumber do begin
      printacr('^3' + mrn(cstr(x),3) + '^9.'+topic.choices[x].description);
      if topic.choices[x].description2<>'' then
        printacr('    ^9' + topic.choices[x].description2);
  end;
  if aacs(topic.addchoicesacs) and (x<25) then begin
     inc(x);
     print('^3' + mrn(cstr(x),3) + '^9.<Pick this one to add your own choice>');
  end;
  nl;
  if (thisuser.vote[TopicNumber] > 0) and (thisuser.vote[TopicNumber] <= topic.choicenumber) then
    if pynq('Change your vote? ') then
      begin
        dec(topic.choices[thisuser.vote[TopicNumber]].numvoted);
        dec(topic.numvoted);
        thisuser.vote[TopicNumber] := 0;
        seek(VotingFile,TopicNumber-1);
        write(VotingFile,topic);
      end
    else
      begin
        close(VotingFile);
        exit;
      end;

  prt('Your choice : ');
  scaninput(s,'Q'^M);
  x:=value(s);
  if (x=topic.choicenumber+1) and aacs(topic.addchoicesacs)
    and (x<=25) then begin
     prt(^M^J'Choice '+cstr(x)+': ');
     mpl(65);
     inputwc(s,65);
     if s<>'' then begin
        prt(mln('',7+length(cstr(x)))+': ');
        mpl(65);
        inputwc(s1,65);
        nl;
        if pynq('Add this choice? ') then begin
          topic.choices[x].description:=s;
          topic.choices[x].description2:=s1;
          inc(topic.choicenumber);
          topic.choices[x].numvoted:=1;
          inc(topic.numvoted);
          thisuser.vote[TopicNumber]:=x;
          sl1('Added choice to '+topic.description+':');
          sysoplog(topic.choices[x].description);
          if topic.choices[x].description2<>'' then
             sysoplog(topic.choices[x].description2);
        end;
     end;
  end else if (x>0) and (x<=topic.choicenumber) then begin
      inc(topic.choices[x].numvoted);
      inc(topic.numvoted);
      thisuser.vote[TopicNumber]:=x;
  end;
  nl;
  seek(VotingFile,TopicNumber-1); write(VotingFile,topic);
  close(VotingFile);
  saveurec(thisuser, usernum);
  dyny:=TRUE;
  if pynq('See results? ') then
    topicresults(TopicNumber,thisuser,FALSE);
  if s='Q' then abort := TRUE;
  Lasterror := IOResult;
end;

procedure trackuser;
var
   i:integer;
   u1:userrec;
begin
  prt(^M^J'Track which user? ');
  finduserws(i);
  if (i>0) then
    begin
      gettopics(FALSE);
      loadurec(u1,i);
      i:=0;
      abort:=FALSE;
      while (i<MaxTopics) and (not hangup) and (not abort) do
        begin
          inc(i);
          if u1.vote[i]>0 then
            topicresults(i,u1,FALSE);
        end;
    end;
end;

procedure addtopic;
var
  s:string[65];
  i,j:integer;
begin
  cls;
  reset(VotingFile);
  print('^3Renegade voting addition'^M^J);
  if filesize(VotingFile)<25 then
    begin
      prt('Topic: '); mpl(65);
      inputwc(s,65);
      nl;
      if (s<>'') and pynq('Are you sure? ') then
        begin
          topic.description:=s;
          topic.madeby:=caps(thisuser.name);
          topic.numvoted:=0;
          topic.acs:='VV';
          if pynq('Allow other users to add choices? ') then
            topic.addchoicesacs:=topic.acs
          else
            topic.addchoicesacs:=general.addchoice;

          i:=0;
          s:=' ';

          print(^M^J'^9Now enter the choices.  You have up to two lines for each');
          print('choice. Press [Enter] on a blank first choice line to end.'^M^J);

          topic.choicenumber:=0;
          abort:=FALSE;
          while (i<=25) and (not abort) do
            begin
              inc(i);
              prt('Choice '+mln(cstr(i),2)+': '); mpl(65);
              inputwc(s,65);
              if s<>'' then
                begin
                  topic.choices[i].description:=s;
                  inc(topic.choicenumber);
                  prt(mln('',9)+': '); mpl(65);
                  inputwc(s,65);
                  topic.choices[i].description2:=s;
                  topic.choices[i].numvoted:=0;
                end
              else
                abort:=TRUE;
            end;
          nl;
          if ((i>1) or (topic.choicenumber>0)) and pynq('Add this topic? ') then
            begin
              seek(VotingFile,filesize(VotingFile));
              write(VotingFile,topic);
              sysoplog('Added voting topic:'+topic.description);
            end;
        end
    end
  else
    prt('No room for additional topics!');
  nl;
  close(VotingFile);
  pausescr(FALSE);
  Lasterror := IOResult;
end;

end.
