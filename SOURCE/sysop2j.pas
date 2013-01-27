{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration Editor - Strings }

unit sysop2j;

interface

uses crt, dos, overlay, common;

procedure postring;

implementation

procedure instring(const p:astr; var v:astr; len:integer);
var changed:boolean;
begin
  print('Enter new "'+p+'" string:');
  inputmain(v, len, 'CI');
end;

procedure postring;
var fstringf:file of fstringrec;
    s,s2:string[80];
    onpage:integer;
    c:char;
    done:boolean;

  procedure showstrings;
  var
    i:integer;
  begin
    abort:=FALSE; next:=FALSE;
    mciallowed:=FALSE;
    with fstring do
      case onpage of
        1:begin
            printacr('^1A. Anonymous    :'+anonymous);
            printacr('^1B. Logon note #1:'+note[1]);
            printacr('^1   Logon note #2:'+note[2]);
            printacr('^1C. Logon prompt :'+lprompt);
            printacr('^1D. Echo chr     :'+echoc);
            printacr('^1E. Your password:'+yourpassword);
            printacr('^1F. Your phone # :'+yourphonenumber);
            printacr('^1G. Engage chat  :'+engage);
            printacr('^1H. Exit chat    :'+endchat);
            printacr('^1I. Sysop working:'+wait);
            printacr('^1J. Pause screen :'+pause);

            prt(^M^J'Enter selection (A-J,[,]),(Q)uit : ');
            onek(c,'QABCDEFGHIJ[]'^M);
          end;
        2:begin
            printacr('^1A. Message entry L#1:'+entermsg1);
            printacr('^1B. Message entry L#2:'+entermsg2);
            printacr('^1C. NewScan start    :'+newscan1);
            printacr('^1D. NewScan done     :'+newscan2);
            printacr('^1E. New User Password:'+newuserpassword);
            printacr('^1F. Automessage by   :'+automsgt);
            printacr('^1G. Auto border char.:'+autom);
            printacr('^1H. Quote header L#1 :'+quote_line[1]);
            printacr('^1I. Quote header L#2 :'+quote_line[2]);
            printacr('^1J. Continue prompt  :'+continue);

            prt(^M^J'Enter selection (A-J,[,]),(Q)uit : ');
            onek(c,'QABCDEFGHIJ[]'^M);
          end;
        3:begin
            printacr('^1A. Shell to DOS L#1:'+shelldos1);
            printacr('^1B. Reading email   :'+readingemail);
            printacr('^1C. Chat call L#1   :'+chatcall1);
            printacr('^1D. Chat call L#2   :'+chatcall2);
            printacr('^1E. Shuttle prompt  :'+shuttleprompt);
            printacr('^1F. Name not found  :'+namenotfound);
            printacr('^1G. Bulletin line   :'+bulletinline);
            printacr('^1H. Protocol prompt :'+protocolp);
            printacr('^1I. Chat call reason:'+chatreason);

            prt(^M^J'Enter selection (A-I,[,]),(Q)uit : ');
            onek(c,'QABCDEFGHI[]'^M);
          end;
        4:begin
            printacr('^1A. List line        :'+listline);
            printacr('^1B. File NewScan line:'+newline);
            printacr('^1C. Search line      :'+searchline);
            printacr('^1D. Find Descrip. L#1:'+findline1);
            printacr('^1E. Find Descrip. L#2:'+findline2);
            printacr('^1F. Download line    :'+downloadline);
            printacr('^1G. Upload line      :'+uploadline);
            printacr('^1H. View content line:'+viewline);
            printacr('^1I. Insuff. credits  :'+nofilecredits);
            printacr('^1J. Bad UL/DL ratio  :'+unbalance);

            prt(^M^J'Enter selection (A-J,[,]),(Q)uit : ');
            onek(c,'QABCDEFGHIJ[]'^M);
          end;
        5:begin
            printacr('^1A. Logon incorrect :'+ilogon);
            printacr('^1B. Get filespec L#1:'+gfnline1);
            printacr('^1C. Get filespec L#2:'+gfnline2);
            printacr('^1D. Add to batch    :'+batchadd);
            printacr('^1E. Adding batches  :'+addbatch);
            printacr('^1F. Reading prompt  :'+readq);
            printacr('^1G. Sysop PW prompt :'+sysopprompt);
            printacr('^1H. Use defaults    :'+default);
            printacr('^1I. Newscan begins  :'+newscanall);
            printacr('^1J. Newscan done    :'+newscandone);

            prt(^M^J'Enter selection (A-J,[,]),(Q)uit : ');
            onek(c,'QABCDEFGHIJ[]'^M);
          end;
        6:begin
            for i := 1 to 3 do
              printacr('^1'+chr(i+64)+'. User question #'+cstr(i)+' :'+userdefques[i]);
            for i := 1 to 3 do
              printacr('^1'+chr(i+67)+'. user editor display #'+cstr(i)+' :'+userdefed[i]);

            prt(^M^J'Enter selection (A-F,[,]),(Q)uit : ');
            onek(c,'QABCDEF[]'^M);
          end;
      end;
      mciallowed:=TRUE;
  end;

  procedure dostringstuff;
  begin
    case c of
      'Q':done:=TRUE;
      '[':begin
            dec(onpage);
            if (onpage<1) then onpage:=6;
          end;
      ']':begin
            inc(onpage);
            if (onpage>6) then onpage:=1;
          end;
    end;
    with fstring do
      case onpage of
        1:case c of
            'A':instring('Anonymous string',anonymous,80);
            'B':begin
                  instring('Logon note [1/2]', note[1], 80);
                  nl;
                  instring('Logon note [2/2]', note[2], 80);
                end;
            'C':instring('Logon prompt',lprompt,40);
            'D':begin
                  prt('Enter new echo character: ');
                  mpl(1); inputl(s,1);
                  if (s<>'') then echoc:=s[1];
                end;
            'E':instring('Your password',yourpassword,80);
            'F':instring('Your phone number',yourphonenumber,80);
            'G':instring('Engage chat',engage,80);
            'H':instring('End chat',endchat,80);
            'I':instring('SysOp working',wait,80);
            'J':instring('Pause',pause,80);
            'Q':done:=TRUE;
          end;
        2:case c of
            'A':instring('Message entry line 1',entermsg1,80);
            'B':instring('Message entry line 2',entermsg2,80);
            'C':instring('NewScan line 1',newscan1,80);
            'D':instring('NewScan line 2',newscan2,80);
            'E':instring('Newuser password prompt',newuserpassword,80);
            'F':instring('Auto message title',automsgt,80);
            'G':begin
                  print('^1Enter new auto message border character:');
                  inputl(s,1);
                  if (s<>'') then autom:=s[1];
                end;
            'H':instring('Quote header line 1',quote_line[1],80);
            'I':instring('Quote header line 2',quote_line[2],80);
            'J':instring('Continue display prompt',continue,80);
          end;
        3:case c of
            'A':instring('Shell to DOS line 1',shelldos1,80);
            'B':instring('Reading email prompt',readingemail,80);
            'C':instring('Chat call line 1',chatcall1,80);
            'D':instring('Chat call line 2',chatcall2,80);
            'E':instring('Shuttle name prompt',shuttleprompt,80);
            'F':instring('Name not found line during logon',namenotfound,80);
            'G':instring('Bulletins prompt line',bulletinline,80);
            'H':instring('Protocol prompt',protocolp,80);
            'I':instring('Chat reason prompt',chatreason,80);
          end;
        4:case c of
            'A':instring('List line',listline,80);
            'B':instring('File NewScan line',newline,80);
            'C':instring('Search line',searchline,80);
            'D':instring('Find description line 1',findline1,80);
            'E':instring('Find description line 2',findline2,80);
            'F':instring('Download line',downloadline,80);
            'G':instring('Upload line',uploadline,80);
            'H':instring('View interior contents line',viewline,80);
            'I':instring('Insufficient file points',nofilecredits,80);
            'J':instring('Upload/Download ratio unbalanced',unbalance,80);
          end;
        5:case c of
            'A':instring('Logon incorrect',ilogon,80);
            'B':instring('Get filespec line 1',gfnline1,80);
            'C':instring('Get filespec line 2',gfnline2,80);
            'D':instring('Add to batch queue',batchadd,80);
            'E':instring('Adding to batch line',addbatch,80);
            'F':instring('Reading messages prompt',readq,80);
            'G':instring('Sysop password prompt',sysopprompt,80);
            'H':instring('Defaults on message entry',default,80);
            'I':instring('Newscan beginning ',newscanall,80);
            'J':instring('Newscan completed ',newscandone,80);
          end;
        6:begin
            if c in ['A'..'C'] then
              instring('SysOp defined user question #'+cstr(ord(c)-64),userdefques[ord(c)-64],80)
            else
              if c in ['D'..'F'] then
                instring('user editor string for question #'+cstr(ord(c)-67),userdefed[ord(c)-67],10)
          end;
      end;
  end;

begin
  onpage:=1; done:=FALSE;
  repeat
    cls;
    print('^5String configuration - page '+cstr(onpage)+' of 6'^M^J);
    showstrings;
    nl;
    dostringstuff;
  until ((done) or (hangup));
  assign(fstringf,general.datapath+'string.dat');
  reset(fstringf); seek(fstringf,0); write(fstringf,fstring); close(fstringf);
  Lasterror := IOResult;
end;

end.
