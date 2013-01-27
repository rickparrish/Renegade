{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration - Network }

unit sysop2h;

interface

uses crt, dos, overlay, common;

procedure pofido;

implementation

uses mail0, nodelist;

procedure incolor(const msg:astr; var i:byte);
var c:char;
begin
	prt('Enter new '+msg+' color (0-9) : ');
	onek(c,^M'0123456789');
	if (c<>^M) then i:=ord(c)-48;
end;


procedure pofido;
var
  c:char;
  cc:integer;
  done,changed:boolean;
begin
	done:=FALSE;
	repeat
    with General do begin
			cls;
			print('^5Network configuration'^M^J);

			abort:=FALSE; next:=FALSE;
			printacr('^1A. Net addresses');
			printacr('^1B. Origin line     : ^5'+origin + ^M^J);

			printacr('^1C. Strip IFNA kludge lines : ^5'+syn(skludge)+
				'^1     1. Color of standard text : ^5'+cstr(ord(text_color)));
			printacr('^1D. Strip SEEN-BY lines     : ^5'+syn(sseenby)+
				'^1     2. Color of quoted text   : ^5'+cstr(ord(quote_color)));
			printacr('^1E. Strip origin lines      : ^5'+syn(sorigin)+
				'^1     3. Color of tear line     : ^5'+cstr(ord(tear_color)));
			printacr('^1F. Add tear/origin line    : ^5'+syn(addtear)+
				'^1     4. Color of origin line   : ^5'+cstr(ord(origin_color)) + ^M^J);

			printacr('^1G. Default Echomail path   : ^5'+defechopath);
      printacr('^1H. Netmail path            : ^5'+general.netmailpath);
      printacr('^1I. Netmail attributes      : ^5'+netmail_attr(netattribute));
      printacr('^1J. UUCP gate address       : ^5'+mln('^5'+cstr(Aka[20].zone)+':'+cstr(Aka[20].net)+
        '/'+cstr(Aka[20].node)+'.'+cstr(Aka[20].point), 20));

			prt(^M^J'Enter selection (A-J,1-4) [Q]uit : ');
      onek(c,'QABCDEFGHIJ1234'^M);
			nl;
			case c of
				'Q':done:=TRUE;
				'A':begin
							repeat
								cls;
								print('^5Network addresses'^M^J);
								abort:=FALSE; next:=FALSE;
                for cc := 0 to 19 do
									begin
                    prompt('^1'+chr(cc + 65)+'. Address #'+mn(cc, 2)+' : '+
                      mln('^5'+cstr(Aka[cc].zone)+':'+cstr(Aka[cc].net)+
                      '/'+cstr(Aka[cc].node)+'.'+cstr(Aka[cc].point), 20));
                    if (odd(cc)) then
                      nl;
									end;
                prt(^M^J'Enter selection (A-T) : ');
                onek(c,'ABCDEFGHIJKLMNOPQRST'^M);
								nl;
                if c in ['A'..'T'] then
                   next:=getnewaddr('New address',Aka[ord(c)-65].zone,
                              Aka[ord(c)-65].net,
                              Aka[ord(c)-65].node,
                              Aka[ord(c)-65].point);
              until (c = ^M);
						end;
				'B':begin
							print('Enter new origin line');
							prt(':'); mpl(50); inputwn(origin,50,changed);
						end;
				'C':skludge:=not skludge;
				'D':sseenby:=not sseenby;
				'E':sorigin:=not sorigin;
				'F':addtear:=not addtear;
				'G':inputpath('Enter new default echomail path',defechopath);
        'H':inputpath('Enter new netmail path',general.netmailpath);
        'I':repeat
							print('^1Netmail attributes: '+netmail_attr(netattribute));
							prt('Attributes [PCKIHL] [?]Help [Q]uit :');
							onek(c,'PCKHIL?Q'^M);
							case c of
								'?':begin
											nl;
											lcmds(22,3,'Local','Private');
											lcmds(22,3,'Crash mail','Kill-Sent');
											lcmds(22,3,'Hold','In-Transit');
											nl;
										end;
								'L':if (local in netattribute) then netattribute:=netattribute-[local]
											 else netattribute:=netattribute+[local];
								'I':if (intransit in netattribute) then netattribute:=netattribute-[intransit]
											 else netattribute:=netattribute+[intransit];
								'P':if (private in netattribute) then netattribute:=netattribute-[private]
											 else netattribute:=netattribute+[private];
								'C':if (crash in netattribute) then netattribute:=netattribute-[crash]
											 else netattribute:=netattribute+[crash];
								'K':if (killsent in netattribute) then netattribute:=netattribute-[killsent]
											 else netattribute:=netattribute+[killsent];
								'H':if (hold in netattribute) then netattribute:=netattribute-[hold]
											 else netattribute:=netattribute+[hold];
							end;
						until (c in ['Q',^M]) or (hangup);
        'J':next:=getnewaddr('New UUCP gate address',Aka[20].zone,
              Aka[20].net,
              Aka[20].node,
              Aka[20].point);
				'1':incolor('standard text',text_color);
				'2':incolor('quoted text',quote_color);
				'3':incolor('tear line',tear_color);
				'4':incolor('origin line',origin_color);
			end;
		end;
	until ((done) or (hangup));
	Lasterror := IOResult;
end;

end.
