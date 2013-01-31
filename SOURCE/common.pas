{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}

{$A+,B-,D-,E-,F+,I-,L-,N-,O-,R-,S-,V-}
unit common;

interface

uses crt, dos, myio, timefunc, overlay;

{$I records.pas}

const
	strlen=119;
	seperator='^4:^3';

type
  MCIFunctionType = function(const s:astr; Data1, Data2:Pointer):string;
  mnuflags=
   (clrscrbefore,                 { C: clear screen before menu display }
    dontcenter,                   { D: don't center the menu titles! }
    nomenuprompt,                 { N: no menu prompt whatsoever? }
    forcepause,                   { P: force a pause before menu display? }
    autotime,                     { T: is time displayed automatically? }
    forceline,                    { F: Force full line input }
    NoGenericAnsi,                { 1: DO NOT generate generic prompt if ANSI }
    NoGenericAvatar,              { 2: DO NOT generate generic prompt if AVT  }
    NoGenericRIP,                 { 3: DO NOT generate generic prompt if RIP  }
    NoGlobalDisplayed,            { 4: DO NOT display the global commands!    }
    NoGlobalUsed);                { 5: DO NOT use global commands!            }
   {NoVisible                       6: DO NOT display input!                  }

  menurec=                        { *.MNU : Menu records }
  record
    menuname:array[1..3] of string[100]; { menu name }
    directive,                           { help file displayed }
    longmenu:string[12];                 { displayed in place of long menu }
    menuprompt:string[120];              { menu prompt }
    ACS:ACString;                        { access requirements }
    password:string[15];                 { password required }
    fallback:string[8];                  { fallback menu }
    forcehelplevel:byte;                 { forced help level for menu }
    gencols:byte;                        { generic menus: # of columns }
    gcol:array[1..3] of byte;            { generic menus: colors }
    menuflags:set of mnuflags;           { menu status variables }
  end;

  cmdflags=
   (hidden,                       { H: is command ALWAYS hidden? }
    unhidden);                    { U: is command ALWAYS visible? }

  commandrec=                       { *.MNU : Command records }
  record
    ldesc:string[70];               { long command description }
    sdesc:string[35];               { short command description }
    ckeys:string[14];               { command-execution keys }
    ACS:str40;                      { access requirements }
    cmdkeys:string[2];              { command keys: type of command }
    options:string[50];             { MString: command data }
    commandflags:set of cmdflags;   { command status variables }
  end;

  States              = (Waiting, Bracket, Get_Args, Get_Param, Eat_Semi,
                         In_Param, GetAvCmd, GetAvAttr, GetAvRLE1,
                         GetAvRLE2, GetAvX, GetAvY);

  ScreenType = array [0..3999] of Byte;

  StorageType = (Disk, CD, Copied);

  BatchDLQueueRecord = record
    FileName:string[65];
    Storage: StorageType;
    Section,
    Points:SmallInt;
    Uploader:SmallWord;
    Size,
    Time,
    OwnerCRC:longint;
  end;

  BatchULQueueRecord = record
    FileName:string[12];
    Section:SmallInt;
    Description:string[55];
    VPointer:byte;
  end;

  IEMSIRecord = record
    UserName,
    Handle:string[36];
    CityState:string[30];
    ph:string[12];
    pw:string[20];
    bdate:string[10];
  end;

  MenuCommandPointer = ^CommandArray;
  CommandArray = array[1..maxmenucmds] of CommandRec;

  MCIBufferType = array[1..MAXCONFIGURABLE] of char;
  MCIBufferPtr = ^MCIBufferType;

  Multitasker = (None, DesqView, MSWindows, OS2);

const  { predefined variables }
   MCIBuffer: MCIBufferPtr = NIL;
   DIELATER: boolean = FALSE;         { if true, Renegade locks up }
   F_HOME = 18176;      { 256 * Scan Code }
   F_UP   = 18432;
   F_PGUP = 18688;
   F_LEFT = 19200;
   F_RIGHT= 19712;
   F_END  = 20224;
   F_DOWN = 20480;
   F_PGDN = 20736;
   F_INS  = 20992;
   F_DEL  = 21248;
   F_CTRLLEFT  = 29440;
   F_CTRLRIGHT = 29696;
  NoCallInitTime = 30 * 60;     { thirty minutes between modem inits }
	Tasker:Multitasker = None;
	LastScreenSwap:longint = 0;
	ParamArr:Array[1..5] Of Word = (0, 0, 0, 0, 0);
	Params:Word = 0;							{ number of parameters }
	NextState:States = Waiting; 	{ Next state for the parser }
	TempSysOp:boolean = FALSE;		{ is temporary sysop? }
	Reverse:Boolean = False;			{ true if text attributes are reversed }
	TimeLock:boolean = FALSE; 		{ If true, do not Hangup due to time! }
	Savedx:byte=0;								{ for ansi driver}
	Savedy:byte=0;								{ for ansi driver}
  TempPause:boolean=TRUE;       { is pause on or off?  Set at prompts, onek, used everywhere }
	DirFileopen1:boolean=TRUE;		{ whether DirFile has been opened before }
	offlinemail:boolean=FALSE;		{ are we in the offline mail system? }
	multinodechat:boolean=FALSE;	{ are we in multinode chat?}
	ChatChannel:integer=0;				{ What chat channel are we in? }
	displayingmenu:boolean=FALSE; { are we displaying a menu? 						}
  InVisEdit:boolean=FALSE;      { are we in the visual editor? }
	menuAborted:boolean=FALSE;		{ was the menu Aborted? }
	allowAbort:boolean=TRUE;			{ are Aborts allowed? 									}
	mciallowed:boolean=TRUE;			{ is mci allowed? }
	colorallowed:boolean=TRUE;		{ is color allowed? }
	echo:boolean=TRUE;						{ is text being echoed? (FALSE=use echo chr)}
	Hangup:boolean=TRUE;					{ is user offline now?									}
	timedout:boolean=FALSE; 			{ has he timed out? 										}
  nofile:boolean=TRUE;          { did last pfl() file NOT exist?        }
  onekcr:boolean=TRUE;          { does ONEK prints<CR> upon exit?       }
	onekda:boolean=TRUE;					{ does ONEK display the choice? 				}
	slogging:boolean=TRUE;				{ are we outputting to the SysOp log? 	}
	sysopon:boolean=TRUE; 				{ is SysOp logged onto the WFC menu?		}
	wantout:boolean=TRUE; 				{ output text locally?									}
	wcolor:boolean=TRUE;					{ in chat: was last key pressed by SysOp? }
	badfpath:boolean=FALSE; 			{ is the current DL path BAD? 					}
	badufpath:boolean=FALSE;			{ is the current UL path BAD? 					}
	badini:boolean=FALSE; 				{ was last call to ini/inu value()=0, s<>"0"? }
	beepend:boolean=FALSE;				{ whether to beep after caller logs off }
	bnp:boolean=FALSE;						{ was file base name printed yet? 			}
	cfo:boolean=FALSE;						{ is chat file open?										}
	ch:boolean=FALSE; 						{ are we in chat mode?									}
	chatcall:boolean=FALSE; 			{ is the chat call "noise" on?          }
	contlist:boolean=FALSE; 			{ continuous message listing mode on? 	}
	croff:boolean=FALSE;					{ are CRs turned off? 									}
	ctrljoff:boolean=FALSE; 			{ turn color to #1 after ^Js??					}
	doneafterNext:boolean=FALSE;	{ offhook and exit after Next logoff? 	}
  doneday:boolean=FALSE;        { are we done now? ready to drop to DOS?}
	dosansion:boolean=FALSE;			{ output chrs to DOS for ANSI codes?!!? }
	dyny:boolean=FALSE; 					{ does YN return Yes as default?				}
	fastlogon:boolean=FALSE;			{ if a FAST LOGON is requested					}
	hungup:boolean=FALSE; 				{ did user drop carrier?								}
	incom:boolean=FALSE;					{ accepting input from com? 						}
	inwfcmenu:boolean=FALSE;			{ are we in the WFC menu? 							}
	lastcommandgood:boolean=FALSE;{ was last command a REAL command?			}
	lastcommandovr:boolean=FALSE; { override PAUSE? (NO pause?) 					}
	localioonly:boolean=FALSE;		{ local I/O ONLY? 											}
	makeqwkfor:integer=0; 				{ make a qwk packet ONLY? 							}
	upqwkfor:integer=0; 					{ upload a qwk packet ONLY? 						}
  RoomNumber:integer=0;         { Room of teleconference                }
	packbasesonly:boolean=FALSE;	{ pack message bases ONLY?							}
	sortfilesonly:boolean=FALSE;	{ sort file bases ONLY? 								}
	newmenutoload:boolean=FALSE;	{ menu command returns TRUE if new menu to load }
  OverLayLocation:byte=0;       { 0=Normal, 1=EMS, 2=XMS                }
	outcom:boolean=FALSE; 				{ outputting to com?										}
	printingfile:boolean=FALSE; 	{ are we printing a file? 							}
	AllowContinue:boolean=FALSE;	{ Allow Continue prompts? 							}
	quitafterdone:boolean=FALSE;	{ quit after Next user logs off?				}
	reading_a_msg:boolean=FALSE;	{ is user reading a message?						}
	readingmail:boolean=FALSE;		{ reading private mail? 								}
	shutupchatcall:boolean=FALSE; { was chat call "SHUT UP" for this call? }
	smread:boolean=FALSE; 				{ were "small messages" read? (delete them) }
	trapping:boolean=FALSE; 			{ are we trapping users text? 					}
	useron:boolean=FALSE; 				{ is there a user on right now? 				}
	wasnewuser:boolean=FALSE; 		{ did a NEW USER log on?								}
	write_msg:boolean=FALSE;			{ is user writing a message?						}
	newechomail:boolean=FALSE;		{ has new echomail been entered?				}
	timewarn:boolean=FALSE; 			{ has user been warned of time shortage? }
	telluserevent:byte=0; 				{ has user been told about the up-coming event? }
	exiterrors:byte=1;						{ errorLEVEL for Critical error exit		}
	exitnormal:byte=0;						{ errorLEVEL for Normal exit						}
	TodayCallers:integer=0; 			{ new system callers }
	TodaynumUsers:integer=0;			{ new number of users }
	node:word=0;									{ node number }
	answerbaud:longint=0; 				{ baud rate to answer the phone at			}
	exteventtime:word=0;					{ # minutes before external event 			}
	LastWFCX:byte = 1;
	LastWFCY:byte = 1;

var
	
      DatFilePath:string[40];
      GlobalMenuCommands:byte;
	Interrupt14:pointer;					{ far ptr to interrupt 14 }
{$IFDEF MSDOS}
	ticks: longint absolute $0040:$006C;
{$ENDIF}
	IEMSIRec:IEMSIRecord;
	BatchDLQueue:array[1..maxbatchfiles] of ^BatchDLQueueRecord;
	BatchULQueue:array[1..maxbatchfiles] of ^BatchULQueueRecord;
	VotingFile:file of votingr;
	LPT:text; 										{ Printer 															}
	FossilPort:word;
	CallerIDNumber:string[40];		{ Caller ID string obtained from modem }
	ActualSpeed:longint;					{ Actual connect rate }
	Reliable:boolean; 						{ error correcting connection? }
	Speed:longint;								{ com port rate }
{$IFDEF MSDOS}
	regs:registers;
{$ENDIF}
	uf:file of userrec; 					{ USER.LST															}
	MBasesFile:file of boardrec;	{ MBASES.DAT														}
	xf:file of protrec; 					{ PROTOCOL.DAT													}
	FBasesFile:file of ulrec; 		{ FBASES.DAT														}
	SchemeFile:file of SchemeRec; { SCHEME.DAT														}
	DirFile:file of ulfrec; 			{ *.DIR 																}
	ScnFile:file of boolean;			{ *.SCN 																}
	sf:file of useridxrec;				{ USER.IDX															}
	smf:file of smr;							{ SHORTMSG.DAT													}
	verbf:file of verbrec;				{ EXTENDED.DAT													}
	msgtxtf:file; 								{ *.DAT 																}
	msghdrf:file of mheaderrec; 	{ *.HDR 																}
	msgscnf:file of scanrec;			{ *.SCN 																}
	conf:file of confrec; 				{ CONFRENC.DAT													}
	confr:confrec;								{ Conferences 													}
	nodef:file of noderec;				{ multi node file }
	nodechatlastrec:longint;			{ last record in group chat file read }
	newfilesf:text; 							{ for NEWFILES.DAT in the qwk system }
	Scheme:SchemeRec;
	noder:noderec;
	liner:linerec;

	Lasterror:integer;						{ Results from last ioresult, when needed }

	sysopf, 											{ SYSOP.LOG 														}
	sysopf1,											{ SLOGxxxx.LOG													}
	trapfile, 										{ TRAP*.MSG 														}
	cf:text;											{ CHAT*.MSG 														}

	general:generalrec; 					{ configuration information 						}
	fstring:fstringrec; 					{ string configuration									}

	thisuser:userrec; 						{ user's account records                }

	{ BRD files }
  Msg_On:longint;               { current message being read            }

	{ EVENTS }
	events:array[0..maxevents] of ^eventrec;
	numevents:integer;						{ # of events 													}

	{ PROTOCOLS }
  protocol:protrec;              { protocol in memory                    }

	{ FILE BASES }
	memuboard,tempuboard:ulrec; 	{ uboard in memory, temporary uboard		}
	readuboard, 									{ current uboard # in memory						}
	MaxFBases,										{ Max number of file bases							}
	fileboard:integer;						{ file base user is in									}
	NewScanFBase:boolean; 				{ New scan this base? 									}

	{ MESSAGE BASES }
	memboard:boardrec;						{ board in memory 											}
	readboard,										{ current board # in memory 						}
	lastauthor, 									{ Author # of the last message					}
	MaxMBases,										{ Max number of msg bases 							}
	board:integer;								{ message base user is in 							}
	NewScanMBase:boolean; 				{ New scan this base? 									}
	LastMsgRead:longint;					{ Last message read in current base 		}

	{ FILE/MESSAGE BASE COMPRESSION TABLES }

  { only used in newcomptables and af/am/cf/cmbase fns }

  ccboards:array[0..255] of set of 0..7;
 ccuboards:array[0..255] of set of 0..7;

	junkinfo,
	dirinfo:searchrec;						{see if searchrec can be replaced elsewhere}

	confsystem, 									{ is the conference system enabled? }
	blankmenunow, 								{ is the wfcmenu blanked out? }
	Invisible,										{ Run in Invisible mode? }
	Abort,Next:boolean; 					{ global Abort and Next }

(*****************************************************************************)


		buf:string[255];							{ macro buffer }
		mlc:string[255];							{ multiline bullshit for chat }

		tempdir:string[40]; 					{ Temporary directory base name }

		chatr,												{ last chat reason											}
		cmdlist,											{ list of cmds on current menu					}
		irt,													{ reason for reply											}
		ll, 													{ "last-line" string for word-wrapping  }
		start_dir,										{ directory BBS was executed from 			}
		menukeys:astr;								{ keys to Abort menu display with 			}

		CreditsLastUpdated, 					{ Time Credits last updated }
		timeon:longint; 							{ time user logged on 									}

		LastBeep,
		LastKeyHit,
		choptime, 										{ time to chop off for system events		}
		extratime,										{ extra time - given by F7/F8, etc			}
		credittime, 									{ credit time adjustment }
		freetime:longint; 						{ free time 														}


		chatt,												{ number chat attempts made by user 		}
		ptoday, 											{ posts made by user this call					}
		etoday, 											{ E-mail sent by user this call 				}
		ftoday, 											{ feedback sent by user this call 			}
    utoday,                       { uploads sent by user this call        }
    dtoday,                       { download sent to user this call       }
		lastprot, 										{ last protocol # 											}
		lil,													{ lines on screen since last pausescr() }
		mread,												{ # public messages has read this call	}
		usernum:integer;							{ user's user number                    }
    dktoday,                      { download k by user this call          }
    uktoday:longint;              { upload k by user this call            }

		chelplevel, 									{ current help level										}
		curco,												{ current ANSI color										}
		ExiterrorLevel, 											{ errorLEVEL to exit with 							}
		tshuttlelogon:byte; 					{ type of special Shuttle Logon command }
		tfileprompt:byte; 						{ type of special file prompt command 	}
		treadprompt:byte; 						{ type of special read prompt command 	}

		currentconf:char; 						{ Current conference tag								}
		first_time:boolean; 					{ first time loading a menu?						}
		menustack:array[1..8] of string[12]; { menu stack 										}
		menustackptr:integer; 				{ menu stack pointer										}
		curmenu:astr; 								{ current menu loaded 									}
		menur:menurec;								{ menu information											}
		MenuCommand: MenuCommandPointer; { Command information }
		noc:integer;									{ # of commands on menu 								}
		rqarea,fqarea,mqarea,vqarea:boolean;
																	{ read/file/message/vote quick area changes  }

		newdate:string[10];						{ NewScan pointer date									}
		lrn:integer;									{ last record # for recno/nrecno				}
		lfn:string[12]; 							{ last filename for recno/nrecno				}

		batchtime:longint;						{ }
		numbatchfiles:integer;				{ # files in DL batch queue 						}
		numubatchfiles:integer; 			{ # files in UL batch queue }

		rate:word;										{ cps for file transfers }

		ubatchv:array[1..maxbatchfiles] of ^verbrec;
		hiubatchv:integer;

{$IFDEF WIN32}
procedure Sound(hz: Word; duration: Word);
function ticks: longint;
{$ENDIF}
procedure DisplayBuffer(MCIFunction: MCIFunctionType; Data1, Data2:Pointer);
function readbuffer(FileName:astr):boolean;
function chinkey:char;
function FormatNumber(x:longint):string;
procedure WriteWFC(c:char);
function AccountBalance:longint;
procedure AdjustBalance(Adjustment:integer);
procedure BackErase(Len:byte);
function UpdateCRC32(CRC:longInt; var buffer; Len:word):longint;
function CRC32(s:astr):longint;
function FunctionalMCI(const s:astr; FileName, InternalFileName:astr): string;
function MCI(const s:string):string;
function Plural(Number:longint): string;
function FormattedTime(TimeUsed:longint):string;
function searchuser(Uname:astr; RealNameOK:boolean): word;
function ambase(x:integer):integer;
function cmbase(x:integer):integer;
function afbase(x:integer):integer;
function cfbase(x:integer):integer;
procedure pausescr(IsCont:boolean);
procedure outmodemstring(const s:astr);
procedure dophoneHangup(showit:boolean);
function CRC16(const s:astr):word;
procedure dophoneoffhook(showit:boolean);
procedure inputpath(const s:astr; var v:astr);
function stripname(s:astr):string;
procedure dtr(status:boolean);
procedure purgedir(s:astr; SubDirs:boolean);
procedure dosansi(const c:char);
function himsg:integer;
function onnode(x:word):byte;
function maxusers:integer;
function decode(const x:astr; check:byte):string;
procedure kill(const fn:astr);
procedure screendump(const f:astr);
procedure scaninput(var s:astr; const allowed:astr);
procedure com_flush_rx;
procedure com_flush_tx;
procedure com_purge_tx;
function com_carrier:boolean;
function com_rx:char;
function com_rx_empty:boolean;
function com_tx_empty:boolean;
procedure com_tx(c:Char);
procedure com_set_speed(speed:longint);
procedure com_deinstall;
procedure backspace;
function usename(b:byte; s:string):string;
function lennmci(const s:string):integer;
procedure loadfileboard(i:integer);
procedure loadboard(i:integer);
procedure initport;
function MsgSysOp:boolean;
function FileSysOp:boolean;
function CoSysOp:boolean;
function so:boolean;
function timer:longint;
procedure TeleConfCheck;
function fbaseac(Base:integer):boolean;
function mbaseac(Base:integer):boolean;
function substitute(src:string; const old,new:string):string;
procedure newcomptables;
procedure changefileboard(Base:integer);
procedure changeboard(Base:integer);
function okansi:boolean;
function okavatar:boolean;
function okrip:boolean;
function okvt100:boolean;
function nsl:longint;
function ageuser(const birthdate:longint):integer;
function allcaps(s:string):string;
function caps(s:string):string;
procedure update_screen;
function pagelength:word;
procedure status_screen(WhichScreen:byte; Message:astr; OneKey:boolean; var Answer:astr);
procedure CheckHangup;
function cinkey:char;
function intime(tim,tim1,tim2:longint):boolean;
function checkpw:boolean;
function stripcolor(const o:string):string;
procedure sl1(s:astr);
procedure sysoplog(s:astr);
function Zeropad(s:str8):string;
function time:string;
function date:string;
function value(s:astr):longint;
procedure shelldos(MakeBatch:boolean; const Command:astr; var ResultCode:byte);
procedure sysopshell;
procedure redrawforansi;
function days(var mo,yr:integer):integer;
procedure star(s:astr);
function daycount(var mo,yr:integer):integer;
function daynum(dt:str10):integer;
function dat:string;
function getkey:word;
procedure SerialOut(s:string);
procedure setc(c:byte);
procedure UserColor(c:integer);
procedure prompt(const s:string);
function sqoutsp(s:string):string;
function ExtractDriveNumber(s:astr):byte;
function mln(s:string; l:byte):string;
function mrn(s:string; l:byte):string;
function mn(i:longint; l:byte):string;
procedure print(const s:string);
procedure nl;
procedure prt(const s:string);
procedure mpl(c:integer);
function ctp(t,b:longint):string;
procedure tleft;
procedure loadnode(i:integer);
function update_node(x:byte):byte;
function	maxnodes:integer;
function maxchatrec:longint;
procedure savenode(i:integer);
procedure loadurec(var u:userrec; i:integer);
procedure saveurec(u:userrec; i:integer);
procedure loadsfrec(i:integer; var sr:useridxrec);
procedure savesfrec(i:integer; sr:useridxrec);
function maxsf:integer;
function empty:boolean;
function inkey:word;
procedure outkey(c:char);
procedure cls;
procedure wait(b:boolean);
procedure swac(var u:userrec; r:uflags);
function tacch(c:char):uflags;
procedure acch(c:char; var u:userrec);
procedure lcmds(len,c:byte; c1,c2:astr);
procedure lcmds3(len,c:byte; c1,c2,c3:astr);
procedure autovalidate(var u:userrec; var un:integer; level:char);
procedure inittrapfile;
function aonoff(b:boolean; const s1,s2:astr):string;
function onoff(b:boolean):string;
function syn(b:boolean):string;
function yn:boolean;
function pynq(const s:astr):boolean;
procedure inu(var i:integer);
procedure ini(var i:byte);
procedure inputdefault(var s:string; v:string; l:integer; flags:str8; lf:boolean);
procedure inputformatted(var s:string; v:string; Abortable:boolean);
procedure inputwn1(var v:string; l:integer; flags:str8; var changed:boolean);
procedure inputwn(var v:string; l:integer; var changed:boolean);
procedure inputwnwc(var v:string; l:integer; var changed:boolean);
procedure inputmain(var s:string; ml:integer; flags:str8);
procedure inputwc(var s:string; ml:integer);
procedure input(var s:string; ml:integer);
procedure inputl(var s:string; ml:integer);
procedure inputcaps(var s:string; ml:integer);
procedure onek(var c:char; ch:astr);
procedure local_input1(var i:string; ml:integer; tf:boolean);
procedure local_input(var i:string; ml:integer);
procedure local_inputl(var i:string; ml:integer);
procedure local_onek(var c:char; ch:string);
function centre(s:astr):string;
procedure wkey;
function ctim(rl:longint):string;
procedure printmain(const ss:string);
procedure printacr(s:string);
function cstr(l:longint):string;
procedure savegeneral(x:boolean);  (* save general *)
procedure pfl(fn:astr);
procedure printfile(fn:astr);
function exist(fn:astr):boolean;
procedure printf(fn:astr);
procedure skey1(var c:char);
function verline(i:integer):string;
function aacs1(u:userrec; un:integer; s:acstring):boolean;
function aacs(s:acstring):boolean;

implementation

uses common1, common2, common3, multnode, {$IFDEF MSDOS}spawno,{$ENDIF} vote, 
     Event {$IFDEF WIN32}, EleNorm, VPSysLow, VPUtils, Windows{$ENDIF};

{$IFDEF WIN32}
procedure Sound(hz: Word; duration: Word);
begin
  Windows.Beep(hz, duration);
end;

function ticks: longint;
begin
  ticks := GetTimeMSec div 55;
end;
{$ENDIF}

{$IFDEF MSDOS}
Function UpdateCRC32(CRC:longInt; var buffer; Len:word):longint; external;
{$L CRC32.OBJ }
{$ENDIF}
{$IFDEF WIN32}
const
  CRC_32_TAB : array[0..255] of longint = (
      $00000000, $77073096, $ee0e612c, $990951ba, $076dc419,
      $706af48f, $e963a535, $9e6495a3, $0edb8832, $79dcb8a4,
      $e0d5e91e, $97d2d988, $09b64c2b, $7eb17cbd, $e7b82d07,
      $90bf1d91, $1db71064, $6ab020f2, $f3b97148, $84be41de,
      $1adad47d, $6ddde4eb, $f4d4b551, $83d385c7, $136c9856,
      $646ba8c0, $fd62f97a, $8a65c9ec, $14015c4f, $63066cd9,
      $fa0f3d63, $8d080df5, $3b6e20c8, $4c69105e, $d56041e4,
      $a2677172, $3c03e4d1, $4b04d447, $d20d85fd, $a50ab56b,
      $35b5a8fa, $42b2986c, $dbbbc9d6, $acbcf940, $32d86ce3,
      $45df5c75, $dcd60dcf, $abd13d59, $26d930ac, $51de003a,
      $c8d75180, $bfd06116, $21b4f4b5, $56b3c423, $cfba9599,
      $b8bda50f, $2802b89e, $5f058808, $c60cd9b2, $b10be924,
      $2f6f7c87, $58684c11, $c1611dab, $b6662d3d, $76dc4190,
      $01db7106, $98d220bc, $efd5102a, $71b18589, $06b6b51f,
      $9fbfe4a5, $e8b8d433, $7807c9a2, $0f00f934, $9609a88e,
      $e10e9818, $7f6a0dbb, $086d3d2d, $91646c97, $e6635c01,
      $6b6b51f4, $1c6c6162, $856530d8, $f262004e, $6c0695ed,
      $1b01a57b, $8208f4c1, $f50fc457, $65b0d9c6, $12b7e950,
      $8bbeb8ea, $fcb9887c, $62dd1ddf, $15da2d49, $8cd37cf3,
      $fbd44c65, $4db26158, $3ab551ce, $a3bc0074, $d4bb30e2,
      $4adfa541, $3dd895d7, $a4d1c46d, $d3d6f4fb, $4369e96a,
      $346ed9fc, $ad678846, $da60b8d0, $44042d73, $33031de5,
      $aa0a4c5f, $dd0d7cc9, $5005713c, $270241aa, $be0b1010,
      $c90c2086, $5768b525, $206f85b3, $b966d409, $ce61e49f,
      $5edef90e, $29d9c998, $b0d09822, $c7d7a8b4, $59b33d17,
      $2eb40d81, $b7bd5c3b, $c0ba6cad, $edb88320, $9abfb3b6,
      $03b6e20c, $74b1d29a, $ead54739, $9dd277af, $04db2615,
      $73dc1683, $e3630b12, $94643b84, $0d6d6a3e, $7a6a5aa8,
      $e40ecf0b, $9309ff9d, $0a00ae27, $7d079eb1, $f00f9344,
      $8708a3d2, $1e01f268, $6906c2fe, $f762575d, $806567cb,
      $196c3671, $6e6b06e7, $fed41b76, $89d32be0, $10da7a5a,
      $67dd4acc, $f9b9df6f, $8ebeeff9, $17b7be43, $60b08ed5,
      $d6d6a3e8, $a1d1937e, $38d8c2c4, $4fdff252, $d1bb67f1,
      $a6bc5767, $3fb506dd, $48b2364b, $d80d2bda, $af0a1b4c,
      $36034af6, $41047a60, $df60efc3, $a867df55, $316e8eef,
      $4669be79, $cb61b38c, $bc66831a, $256fd2a0, $5268e236,
      $cc0c7795, $bb0b4703, $220216b9, $5505262f, $c5ba3bbe,
      $b2bd0b28, $2bb45a92, $5cb36a04, $c2d7ffa7, $b5d0cf31,
      $2cd99e8b, $5bdeae1d, $9b64c2b0, $ec63f226, $756aa39c,
      $026d930a, $9c0906a9, $eb0e363f, $72076785, $05005713,
      $95bf4a82, $e2b87a14, $7bb12bae, $0cb61b38, $92d28e9b,
      $e5d5be0d, $7cdcefb7, $0bdbdf21, $86d3d2d4, $f1d4e242,
      $68ddb3f8, $1fda836e, $81be16cd, $f6b9265b, $6fb077e1,
      $18b74777, $88085ae6, $ff0f6a70, $66063bca, $11010b5c,
      $8f659eff, $f862ae69, $616bffd3, $166ccf45, $a00ae278,
      $d70dd2ee, $4e048354, $3903b3c2, $a7672661, $d06016f7,
      $4969474d, $3e6e77db, $aed16a4a, $d9d65adc, $40df0b66,
      $37d83bf0, $a9bcae53, $debb9ec5, $47b2cf7f, $30b5ffe9,
      $bdbdf21c, $cabac28a, $53b39330, $24b4a3a6, $bad03605,
      $cdd70693, $54de5729, $23d967bf, $b3667a2e, $c4614ab8,
      $5d681b02, $2a6f2b94, $b40bbe37, $c30c8ea1, $5a05df1b,
      $2d02ef8d);
	  
Function UpdateCRC32(CRC:longInt; var buffer; Len:word):longint;
var
  i: Integer;
  Octet: ^Byte;
begin
  Octet := @buffer;
  for i := 1 to Len do
  begin
    CRC := CRC_32_TAB[Byte(Crc XOR LongInt(Octet^))] XOR ((Crc SHR 8) AND $00FFFFFF);
	Inc(Octet);
  end;
  UpdateCRC32 := CRC;
end;
{$ENDIF}

function checkpw:boolean; begin checkpw:=common1.checkpw; end;
procedure newcomptables; begin common1.newcomptables; end;
procedure wait(b:boolean); begin common1.wait(b); end;
procedure inittrapfile; begin common1.inittrapfile; end;
procedure initport; begin common2.initport; end;
{procedure chatfile(b:boolean); begin syschat.chatfile(b); end;}
procedure local_input1(var i:string; ml:integer; tf:boolean);
					begin common1.local_input1(i,ml,tf); end;
procedure local_input(var i:string; ml:integer);
					begin common1.local_input(i,ml); end;
procedure local_inputl(var i:string; ml:integer);
					begin common1.local_inputl(i,ml); end;
procedure local_onek(var c:char; ch:string);
					begin common1.local_onek(c,ch); end;
{procedure chat; begin common1.chat; end;}
procedure sysopshell; begin common1.sysopshell;end;
procedure redrawforansi; begin common1.redrawforansi; end;

procedure skey1(var c:char); begin common2.skey1(c); end;
procedure savegeneral(x:boolean); begin common2.savegeneral(x); end;
procedure update_screen;
	begin common2.update_screen; end;
procedure status_screen(WhichScreen:byte; Message:astr; OneKey:boolean; var Answer:astr);
	begin common2.status_screen(WhichScreen,Message,OneKey,Answer); end;
procedure tleft; begin common2.tleft; end;

procedure inu(var i:integer); begin common3.inu(i); end;
procedure ini(var i:byte); begin common3.ini(i); end;
procedure inputdefault(var s:string; v:string; l:integer; flags:str8; lf:boolean);
	begin common3.inputdefault(s,v,l,flags,lf); end;
procedure inputformatted(var s:string; v:string; Abortable:boolean); begin common3.inputformatted(s,v,Abortable); end;
procedure inputwn1(var v:string; l:integer; flags:str8; var changed:boolean);
	begin common3.inputwn1(v,l,flags,changed); end;
procedure inputwn(var v:string; l:integer; var changed:boolean);
	begin common3.inputwn(v,l,changed); end;
procedure inputwnwc(var v:string; l:integer; var changed:boolean);
	begin common3.inputwnwc(v,l,changed); end;
procedure inputmain(var s:string; ml:integer; flags:str8);
	begin common3.inputmain(s,ml,flags); end;
procedure inputwc(var s:string; ml:integer); begin common3.inputwc(s,ml); end;
procedure input(var s:string; ml:integer); begin common3.input(s,ml); end;
procedure inputl(var s:string; ml:integer); begin common3.inputl(s,ml); end;
procedure inputcaps(var s:string; ml:integer);
	begin common3.inputcaps(s,ml); end;

(*****************************************************************************)

function readbuffer(FileName:astr):boolean;
var
  f:file;
  i,r:integer;
begin
  if (MCIBuffer = NIL) then
    new(MCIBuffer);

  ReadBuffer := FALSE;

  if ((pos('\', FileName) = 0) and (pos(':', FileName) = 0)) then
    FileName := General.MiscPath + FileName;

  if (pos('.', FileName) = 0) then
    begin
      if (okrip) and exist(FileName + '.rip') then
        FileName := FileName + '.rip'
      else if (okavatar) and exist(FileName + '.avt') then
        FileName := FileName + '.avt'
      else if (okansi) and exist(FileName + '.ans') then
        FileName := FileName + '.ans'
      else if (exist(FileName + '.asc')) then
        FileName := FileName + '.asc';
    end;

  if (not exist(FileName)) then
    exit;

  assign(f, FileName);
  reset(f, 1);

  if (ioresult <> 0) then
    exit;

  if (FileSize(f) < MAXCONFIGURABLE) then
    i := FileSize(f)
  else
    i := MAXCONFIGURABLE;

  fillchar(MCIBuffer^, sizeof(MCIBuffer^), 0);
  blockread(f, MCIBuffer^, i, r);

  if (r <> i) then
    exit;

  close(f);
  ReadBuffer := TRUE;
end;

procedure DisplayBuffer(MCIFunction: MCIFunctionType; Data1, Data2:Pointer);
var
  i,x2:integer;
  s:string;
  cs:astr;
  Justify:byte;  {0=Right, 1=Left, 2=Center}
begin
  i := 1;
  while (i <= MAXCONFIGURABLE) and (MCIBuffer^[i] <> #0) do
    begin
      s := '';
      while (i <= MAXCONFIGURABLE) and (MCIBuffer^[i] <> #13) do
        if (MCIBuffer^[i] = '~') and (i + 2 <= MAXCONFIGURABLE) then
          begin
            cs := MCIFunction(MCIBuffer^[i + 1] + MCIBuffer^[i + 2], Data1, Data2);
            if (cs = MCIBuffer^[i + 1] + MCIBuffer^[i + 2]) then
              begin
                s := s + '~';
                inc(i);
                continue;
              end;
            inc(i, 3);
            if (i + 1 <= MAXCONFIGURABLE) and (MCIBuffer^[i] in ['#','{','}']) then
              begin
                if (MCIBuffer^[i] = '}') then
                  Justify := 0
                else if (MCIBuffer^[i] = '{') then
                  Justify := 1
                else
                  Justify := 2;
                if (MCIBuffer^[i + 1] in ['0'..'9']) then
                  begin
                    x2 := ord(MCIBuffer^[i + 1]) - 48;
                    inc(i, 2);
                    if (MCIBuffer^[i] in ['0'..'9']) then
                      begin
                        x2 := x2 * 10 + ord(MCIBuffer^[i]) - 48;
                        inc(i, 1);
                      end;
                    if (x2 > 0) then
                      case Justify of
                        0:cs := mrn(cs, x2);
                        1:cs := mln(cs, x2);
                        2:while (length(cs) < x2) do
                            begin
                              cs := ' ' + cs;
                              if (length(cs) < x2) then
                                cs := cs + ' ';
                            end;
                      end;
                  end;
              end;
            { s := s + cs; }
            if (length(cs) + length(s) <= 255) then
              begin
                move(cs[1], s[length(s)+1], length(cs));
                inc(s[0], length(cs));
              end
            else
              if (length(s) < 255) then
                begin
                  move(cs[1], s[length(s)+1], 255-length(s));
                  s[0] := #255;
                end;
          end
        else
          begin
            inc(s[0]);
            s[length(s)] := MCIBuffer^[i];
            inc(i);
          end;

      if (i <= MAXCONFIGURABLE) and (MCIBuffer^[i] = #13) then
        inc(i, 2);
      croff := TRUE;
      printacr(s);
    end;
end;

function chinkey:char;
var c:char;
begin
  c:=#0; chinkey:=#0;
  if (keypressed) then begin
    c:=readkey;
    if (not wcolor) then UserColor(general.sysopcolor);
    wcolor:=TRUE;
    if (c=#0) then
      if (keypressed) then begin
        c:=readkey;
        skey1(c);
        if (c=chr(46)) then {ALT-C}
          c:=#1
        else
          if (buf<>'') then
            begin
              c:=buf[1];
              buf:=copy(buf,2,length(buf)-1);
            end
          else
            c := #0
      end;
    chinkey:=c;
  end else
    if ((not com_rx_empty) and (incom)) then begin
      c:=cinkey;
      if (wcolor) then UserColor(general.usercolor);
      wcolor:=FALSE;
      chinkey:=c;
    end;
end;

function FormatNumber(x:longint):string;
var
  s:string;
  i,
  j:byte;
begin
  s := '';
  str(x, s);
  i := length(s);  j := 0;
  while (i > 1) do
    begin
      inc(j);
      if (j = 3) then
        begin
          insert(',', s, i);
          j := 0;
        end;
      dec(i);
    end;
  FormatNumber := s;
end;

procedure WriteWFC(c:char);
var
	LastAttr:byte;
begin
  if (blankmenunow) then exit;
	window(23, 11, 78, 15);
	gotoxy(LastWFCX, LastWFCY);
	LastAttr := textattr;
	textattr := 7;
	write(c);
	textattr := LastAttr;
	LastWFCX := WhereX;
	LastWFCY := WhereY;
	window(1, 1, MaxDisplayCols, MaxDisplayRows);
end;

function AccountBalance:longint;
begin
	AccountBalance := Thisuser.Credit - Thisuser.Debit;
end;

procedure AdjustBalance(Adjustment:integer);
begin
	if (Adjustment > 0) then
		inc(Thisuser.Debit, Adjustment) 	 { Add to debits }
	else
		dec(Thisuser.Credit, Adjustment);  { Add to credits }
end;

function CRC32(s:astr):longint;
begin
	CRC32 := not(UpdateCRC32($FFFFFFFF, s[1], length(s)));
end;

Procedure Kill(const fn:astr);
var
  f:file;
begin
  assign(f,fn);
  erase(f);
  Lasterror := ioresult;
end;

procedure backspace;
begin
	if outcom then
		serialout(^H' '^H);
	if wantout then
		write(^H' '^H);
end;

function substitute(src:string; const old,new:string):string;
var
	p:integer;
	diff:integer;
  LastP:integer;
begin
	if (old <> new) then
		begin
      LastP := 0;
			diff := length(new) - length(old);
			repeat
        p := pos(old, copy(src, LastP, 255));   { guard against reinterping }
				if (p > 0) then
					begin
						if (diff <> 0) then
							begin
								move(src[p + length(old)],src[p + length(new)], length(src) - p);
								inc(src[0],diff);
							end;
						move(new[1],src[p],length(new));
            LastP := p + length(new);
					end;
			until (p = 0);
		end;
	substitute:=src;
end;

procedure dosansi(const c:char);
Var
	i:word;
	label Command;

begin
	if (c=#27) and (NextState in [Waiting..In_Param]) then
		begin
			NextState := Bracket;
			exit;
		end;

	if (c = ^V) and (NextState = Waiting) then
		begin
			NextState := GetAvCmd;
			exit;
		end;

	if (c = ^Y) and (NextState = Waiting) then
		begin
			NextState := GetAvRLE1;
			exit;
		end;

	Case NextState Of
		Waiting : if (c = #9) then
								gotoxy(WhereX + 8, WhereY)
							else
								write(c);
	 GetAvRLE1: begin
								ParamArr[1] := ord(c);
								NextState := GetAvRLE2;
							end;
	 GetAvRLE2: begin
								for i := 1 to ord(c) do
									write(chr(ParamArr[1]));
								NextState := Waiting;
							end;
	 GetAvAttr: begin
								TextAttr := ord(c) and $7f;
								NextState := Waiting;
							end;
			GetAvY: begin
								ParamArr[1] := ord(c);
								NextState := GetAvX;
							end;
			GetAvX: begin
								gotoxy (ord(c),ParamArr[1]);
								NextState := Waiting;
							end;
		GetAvCmd: case c of
								^A : NextState := GetAvAttr;
								^B : begin
											 Textattr := Textattr or $80;
											 NextState := Waiting;
										 end;
								^C : begin
											 gotoxy (WhereX,WhereY-1);
											 NextState := Waiting;
										 end;
								^D : begin
											 gotoxy (WhereX,WhereY+1);
											 NextState := Waiting;
										 end;
								^E : begin
											 gotoxy (WhereX-1,WhereY);
											 NextState := Waiting;
										 end;
								^F : begin
											 gotoxy (WhereX+1,WhereY);
											 NextState := Waiting;
										 end;
								^G : begin
											 clreol;
											 NextState := Waiting;
										 end;
								^H : NextState := GetAvY;
							else
										 NextState := Waiting;
						 end;
		Bracket :
			Begin
				If c <> '[' Then
					Begin
						NextState := Waiting;
						Write(c);
					End
				else
				 begin
					 Params := 1;
					 FillChar (ParamArr, 5, 0);
					 NextState := Get_Args;
				 end;
			End;
		Get_Args, Get_Param, Eat_Semi :
			Begin
				If (NextState = Eat_Semi) And (c = ';') Then
				Begin
					If Params < 5 Then Inc(Params);
					NextState := Get_Param;
					Exit;
				End;
				Case c Of
					'0'..'9' :
						Begin
							ParamArr[Params] := Ord(c) - 48;
							NextState := In_Param;
						End;
					';' :
						Begin
							If Params < 5 Then Inc(Params);
							NextState := Get_Param;
						End;
					Else
						GoTo Command;
				End {Case c} ;
			End;
		In_Param :									{ last char was a digit }
			Begin
				{ looking for more digits, a semicolon, or a command char }
				Case c Of
					'0'..'9' :
						Begin
							ParamArr[Params] := ParamArr[Params] * 10 + Ord(c) - 48;
							NextState := In_Param;
							Exit;
						End;
					';' :
						Begin
							If Params < 5 Then Inc(Params);
							NextState := Eat_Semi;
							Exit;
						End;
				End {Case c} ;
Command:
				NextState := Waiting;
				Case c Of
					{ Note: the order of commands is optimized for execution speed }
					'm' :                 {sgr}
						Begin
							For i := 1 To Params Do
							Begin
								If Reverse Then TextAttr := TextAttr Shr 4 + TextAttr Shl 4;
								Case ParamArr[i] Of
									0 :
										Begin
											Reverse := False;
											TextAttr := 7;
										End;
									1 : TextAttr := TextAttr And $FF Or $08;
									2 : TextAttr := TextAttr And $F7 Or $00;
									4 : TextAttr := TextAttr And $F8 Or $01;
									5 : TextAttr := TextAttr Or $80;
									7 : If Not Reverse Then
											Begin
										{
										TextAttr := TextAttr shr 4 + TextAttr shl 4;
										}
												Reverse := True;
											End;
									22 : TextAttr := TextAttr And $F7 Or $00;
									24 : TextAttr := TextAttr And $F8 Or $04;
									25 : TextAttr := TextAttr And $7F Or $00;
									27 : If Reverse Then
											 Begin
												 Reverse := False;
										{
										TextAttr := TextAttr shr 4 + TextAttr shl 4;
										}
											 End;
									30 : TextAttr := TextAttr And $F8 Or $00;
									31 : TextAttr := TextAttr And $F8 Or $04;
									32 : TextAttr := TextAttr And $F8 Or $02;
									33 : TextAttr := TextAttr And $F8 Or $06;
									34 : TextAttr := TextAttr And $F8 Or $01;
									35 : TextAttr := TextAttr And $F8 Or $05;
									36 : TextAttr := TextAttr And $F8 Or $03;
									37 : TextAttr := TextAttr And $F8 Or $07;
									40 : TextAttr := TextAttr And $8F Or $00;
									41 : TextAttr := TextAttr And $8F Or $40;
									42 : TextAttr := TextAttr And $8F Or $20;
									43 : TextAttr := TextAttr And $8F Or $60;
									44 : TextAttr := TextAttr And $8F Or $10;
									45 : TextAttr := TextAttr And $8F Or $50;
                  46 : TextAttr := TextAttr And $8F Or $30;
									47 : TextAttr := TextAttr And $8F Or $70;
								End {Case} ;
								{ fixup for reverse }
								If Reverse Then TextAttr := TextAttr Shr 4 + TextAttr Shl 4;
							End;
						End;
					'A' :                 {cuu}
						Begin
							If ParamArr[1] = 0 Then ParamArr[1] := 1;
							{If (Wherey - ParamArr[1] >= 1)
							Then} GotoXy(WhereX, Wherey - ParamArr[1])
							{Else GotoXy(WhereX, 1);}
						End;
					'B' :                 {cud}
						Begin
							If ParamArr[1] = 0 Then ParamArr[1] := 1;
							{If (Wherey + ParamArr[1] <= Hi(WindMax) - Hi(WindMin) + 1)
							Then }GotoXy(WhereX, Wherey + ParamArr[1])
							{Else GotoXy(WhereX, Hi(WindMax) - Hi(WindMin) + 1);}
						End;
					'C' :                 {cuf}
						Begin
							If ParamArr[1] = 0 Then ParamArr[1] := 1;
							{If (WhereX + ParamArr[1] <= Lo(WindMax)	- Lo(WindMin) + 1)
							Then} GotoXy(WhereX + ParamArr[1], Wherey)
							{Else GotoXy(Lo(WindMax) - Lo(WindMin) + 1, Wherey);}
						End;
					'D' :                 {cub}
						Begin
							If (ParamArr[1] = 0) Then ParamArr[1] := 1;
							{If (WhereX - ParamArr[1] >= 1)
							Then} GotoXy(WhereX - ParamArr[1], Wherey)
							{Else GotoXy(1, Wherey);}
						End;
					'H', 'f' :            {cup,hvp}
						Begin
							If (ParamArr[1] = 0) Then ParamArr[1] := 1;
							If (ParamArr[2] = 0) Then ParamArr[2] := 1;

							{If (ParamArr[2] > Lo(WindMax) + 1)
								then ParamArr[2] := Lo(WindMax) - Lo(WindMin) + 1;
							If (ParamArr[1] > Hi(WindMax) + 1)
								then ParamArr[1] := Hi(WindMax) - Hi(WindMin) + 1;}
							GotoXy(ParamArr[2], ParamArr[1]) ;
						End;
					'J' : if (ParamArr[1] = 2) then clrscr
								else
									for i := WhereY to 25 do delline; { some terms use others! }
					'K' : clreol;
					'L' : if (ParamArr[1] = 0) then
									InsLine
								else
									For i := 1 To ParamArr[1] Do InsLine; { must not move cursor }
					'M' : if (ParamArr[1] = 0) then
									delline
								else
									For i := 1 To ParamArr[1] Do DelLine; { must not move cursor }
					'P' :                 {dc }
						Begin
						End;
					's' :                 {scp}
						Begin
							SavedX := WhereX;
							SavedY := Wherey;
						End;
					'u' : {rcp} GotoXy(SavedX, SavedY);
					'@':; { Some unknown code appears to do nothing }
					else
							Write(c);
				end {Case c} ;
			end;
	end {Case NextState} ;
end {AnsiWrite} ;

procedure shelldos(MakeBatch:boolean; const Command:astr; var ResultCode:byte);
var
	t:text;
	fname:astr;
	i:byte;
  s:astr;
begin
	if (MakeBatch) then
		begin
			fname := 'TEMP'+cstr(node)+'.BAT';
			assign(t,fname);
			rewrite(t);
			writeln(t,Command);
			close(t);
			Lasterror := ioresult;
		end
	else
		fname := Command;

  if (fname <> '') then
    fname := '/c ' + fname;

	com_flush_tx;

	com_deinstall;

	cursoron(TRUE);

	swapvectors;
	
{$IFDEF MSDOS}
	if general.swapshell then
		begin
      s := getenv('TEMP');
      if (s = '') then
        s := start_dir;
      init_spawno(s,general.swapto,20,10);
      ResultCode := spawn(getenv('COMSPEC'),fname,0);
		end;
{$ENDIF}

	if not general.swapshell or (ResultCode = -1) then
		begin
			exec(getenv('COMSPEC'),fname);
			ResultCode := lo(dosexitcode);
			Lasterror := ioresult;
		end;

	swapvectors;

	if (MakeBatch) then
		kill(fname);

	initport;

	if (not localioonly) and not (lockedport in liner.mflags) then
		com_set_speed(speed);

	update_screen;

	textattr := curco;

	LastKeyHit := timer;
end;

procedure autovalidate(var u:userrec; var un:integer; level:char);
const
	settings:set of uflags=[rlogon,rchat,ruserlist,rvalidate,ramsg,
													rpostan,rpost,remail,rvoting,rmsg,fnodlratio,
													fnopostratio,fnocredits,fnodeletion];
begin
	if not (level in ['A'..'Z']) then
		exit;

	with u,general,validation[level] do
		begin

			userstartmenu := newmenu;
      Subscription := Level;

			tltoday := timeallow[newsl] -
								 (timeallow[sl] - tltoday);

			sl := newsl;
			dsl := newdsl;

			if not softac then
					flags := flags - settings;

			flags := flags + (newac * settings);

			if softar then
				ar := ar + newar
			else
				ar := newar;

			inc(credit, newcredit);

			if (validation[level].expiration > 0) then
				u.expiration := getpackdatetime +
					(validation[level].expiration * 86400)
			else
				u.expiration := 0;

			if (validation[level].expireto in [' ','A'..'Z']) then
				u.expireto := validation[level].expireto;

			if (un = usernum) then
				newcomptables;
		end;
	saveurec(u, un);
end;

function lennmci(const s:string):integer;
var
	i,len:byte;
  junk:string;
begin
	len:=length(s);
	i := 0;
	while i < length(s) do
		begin
			inc(i);
			case s[i] of
				^S:begin
						dec(len,2);
						inc(i);
					 end;
				'^':if (length(s) > i) and (s[i + 1] in ['0'..'9']) then
							begin
								dec(len, 2);
								inc(i);
							end;
				'|':if (length(s) > i + 1) and (s[i + 1] in ['0'..'9']) and
							(s[i + 2] in ['0'..'9']) then
							begin
								dec(len, 3);
								inc(i);
							end;
				'%':if mciallowed and (length(s) > i + 1) then
							begin
                junk := allcaps(MCI('%' + s[i + 1] + s[i + 2]));
                if (copy(junk,1,3) <> '%' + upcase(s[i + 1]) + upcase(s[i + 2])) then
                  inc(len, length(junk) - 3);
							end;
			end;
		end;
	lennmci:=len;
end;

procedure loadfileboard(i:integer);
var
	fo:boolean;
begin
	if (readuboard = i) then exit;

	if (i < 1) then exit;

	if (i > MaxFBases) {or (i < 1)} then
		begin
			memuboard := tempuboard;
			readuboard := i;	{ was -1 }
			exit;
		end;

	fo := (filerec(FBasesFile).mode<>fmclosed);
	if not fo then
		begin
			reset(FBasesFile);
			if (IOResult > 0) then
				begin
					sysoplog('error opening FBASES.DAT');
					runerror(5);
				end;
		end;

	seek(FBasesFile,i-1);
	read(FBasesFile,memuboard);
	if (IOResult > 0) then
		sysoplog('error loading file base ' + cstr(i))
	else
		readuboard := i;

	if not fo then
		begin
			close(FBasesFile);
			if (IOResult > 0) then
				sysoplog('error closing FBASES.DAT');
		end;
end;

procedure loadboard(i:integer);
var
	fo:boolean;
begin
	if (i = -1) then
		begin
			fillchar(memboard,sizeof(memboard),0);
			memboard.filename:='EMAIL';
			memboard.name:='Private Mail';
			memboard.acs:='^';
			memboard.sysopacs:=general.msop;
			memboard.origin_color:=5;
			memboard.tear_color:=9;
			memboard.text_color:=1;
			memboard.quote_color:=3;
			readboard:= -1;
			NewScanMBase := TRUE;
		end;
	if (i < 1) or (i > MaxMBases) or (readboard = i) then exit;

	fo := (filerec(MBasesFile).mode <> fmclosed);
	if not fo then
		begin
			reset(MBasesFile);
			if (IOResult > 0) then
				begin
					sysoplog('error opening MBASES.DAT');
					runerror(5);
				end;
		end;

	seek(MBasesFile,i-1);
	read(MBasesFile,memboard);

	if (IOResult > 0) then
		sysoplog('error loading message base ' + cstr(i))
	else
		readboard := i;

	if not fo then
		begin
			close(MBasesFile);
			if (IOResult > 0) then
				sysoplog('error closing MBASES.DAT');
		end;
end;

{$V-}
procedure lcmds3(len,c:byte; c1,c2,c3:astr);
var s:astr;
begin
	s:='';
	s:=s+'^1(^'+chr(c + ord('0'))+c1[1]+'^1)'+mln(copy(c1,2,lennmci(c1)-1),len-1);
	if (c2<>'') then
		s:=s+'^1(^'+ chr(c + ord('0')) + c2[1]+'^1)'+mln(copy(c2,2,lennmci(c2)-1),len-1);
	if (c3<>'') then
		s:=s+'^1(^' + chr(c + ord('0')) + c3[1]+'^1)'+copy(c3,2,lennmci(c3)-1);
  printacr(s);
end;

procedure lcmds(len,c:byte; c1,c2:astr);
var
	s:astr;
begin
	s := copy(c1,2,lennmci(c1) - 1);
	if (c2 <> '') then
		s := mln(s,len - 1);
  prompt('^1(^' + cstr(c) + c1[1] + '^1)' + s);
	if (c2 <> '') then
    prompt('^1(^' + cstr(c) + c2[1] + '^1)' + copy(c2,2,lennmci(c2) - 1));
	nl;
end;

function MsgSysOp:boolean;
begin
	MsgSysOp := (CoSysOp) or (aacs(general.msop)) or (aacs(memboard.sysopacs));
end;

function FileSysOp:boolean;
begin
	FileSysOp := ((CoSysOp) or (aacs(general.fsop)));
end;

function CoSysOp:boolean;
begin
	CoSysOp := ((so) or (aacs(general.csop)));
end;

function so:boolean;
begin
	so := (aacs(general.sop));
end;

function timer:longint;
begin
	timer := ticks * 5 div 91;		 { 2.5 times faster than ticks div 18.2 }
end;

function fbaseac(Base:integer):boolean;
begin
	fbaseac := FALSE;
	if (Base < 1) or (Base > MaxFBases) then
		exit;
	loadfileboard(Base);
	fbaseac := aacs(memuboard.acs);
end;

function mbaseac(Base:integer):boolean;
begin
	mbaseac := FALSE;
	if (Base < 1) or (Base > MaxMBases) then
		exit;
	loadboard(Base);
	mbaseac := aacs(memboard.acs);
end;

procedure changefileboard(Base:integer);
var
	s:string[20];
begin
	if (Base < 1) or (Base > MaxFBases) or (not fbaseac(Base)) then
		exit;
	if (memuboard.password <> '') and not sortfilesonly then
		begin
			print(^M^J'File base ' + cstr(cfbase(Base)) + ': ^5' + memuboard.name);
			prt('Password: ');
			echo := FALSE;
			input(s,20);
			echo := TRUE;
			if (s <> memuboard.password) then
				begin
					print('Wrong.');
					exit;
				end;
		end;
	fileboard := Base;
	thisuser.lastfbase := fileboard;
end;

procedure changeboard(Base:integer);
var
	s:string[20];
begin
	if (Base < 1) or (Base > MaxMBases) then
		exit;
	if (not mbaseac(Base)) then
		exit;
	if (memboard.password<>'') then
		begin
			print(^M^J'Message base ' + cstr(cmbase(Base)) + ': ^5' + memboard.name);
			prt('Password: ');
			echo := FALSE;
			input(s,20);
			echo := TRUE;
			if (s <> memboard.password) then
				begin
					print('Wrong.');
					exit;
				end;
		end;
	board := Base;
	thisuser.lastmbase := board;
end;

function okvt100:boolean;
begin
	okvt100 := (vt100 in thisuser.flags);
end;

function okansi:boolean;
begin
	okansi := (ansi in thisuser.flags);
end;

function okrip:boolean;
begin
	okrip := (rip in thisuser.sflags);
end;

function okavatar:boolean;
begin
	okavatar := (avatar in thisuser.flags);
end;

function nsl:longint;
var
	beenon:longint;
begin
	if ((useron) or (not inwfcmenu)) then
		begin
			beenon := getpackdatetime - timeon;
			nsl := ((longint(thisuser.tltoday) * 60 + extratime + freetime) - (beenon + choptime + credittime));
		end
	else
		nsl := 3600;
end;

{$IFDEF MSDOS}
procedure CheckHangup; assembler;
asm
	cmp localioonly, 1
	je @getout
	cmp outcom, 1
	jne @getout
	mov dx, Fossilport
	mov ah, 3
	pushf
	call interrupt14
	and al, 10000000b
	jnz @getout
	mov Hangup, 1
	mov hungup, 1
	@getout:
end;
{$ENDIF}
{$IFDEF WIN32}
procedure CheckHangup;
begin
  if (localioonly) then exit;
  if Not(outcom) then exit;
  
  if Not(com_carrier) then
  begin
    Hangup := true;
    hungup := true;
  end;
end;
{$ENDIF}

function intime(tim,tim1,tim2:longint):boolean;
begin
	intime := TRUE;
	while (tim >= 86400) do
		tim := tim - 86400;
	if (tim1 <> tim2) then
		if (tim2 > tim1) then
			if (tim <= tim1 * 60) or (tim >= tim2 * 60) then
				intime := FALSE
			else
		else
			if (tim <= tim1 * 60) and (tim >= tim2 * 60) then
				intime := FALSE;
end;

function stripcolor(const o:string):string;
var
	i,j:byte;
	s:string;
begin
	i:=0;
	s:='';
	while (i < length(o)) do
		begin
			inc(i);
			case o[i] of
				 ^S:inc(i);
				'^':if (o[i+1] in ['0'..'9']) then
							inc(i)
						else
							s := s+'^';
				'|':if (o[i + 1] in ['0'..'9']) and
							 (o[i + 2] in ['0'..'9']) then
							begin
								inc(i,2);
								inc(j,2);
							end
						else
							s:=s+'|';
				else s:=s+o[i];
			end;
		end;
	stripcolor:=s;
end;

procedure sl1(s:astr);
begin
	if (slogging) then
		begin
			if (general.stripclog) then
				s:=stripcolor(s);

			if (general.slogtype < 2) then
				begin
					append(sysopf);
					if (ioresult = 0) then
						begin
							writeln(sysopf,s);
							close(sysopf);
							Lasterror := IOResult;
						end;
				end;

			if (slogseparate in thisuser.sflags) then
				begin
					append(sysopf1);
					if (IOResult = 0) then
						begin
							writeln(sysopf1,s);
							close(sysopf1);
							Lasterror := IOResult;
						end;
				end;

			if (general.slogtype > 0) then
				begin
					if (not general.stripclog) then
						s := stripcolor(s);
          Lasterror := IOResult;
          append(lpt);
					writeln(lpt,s);
					close(lpt);
					if (ioresult > 0) then
						general.slogtype := 0;
				end;
	end;
end;

procedure sysoplog(s:astr);
begin
	sl1('   '+s);
end;

function Zeropad(s:str8):string;
begin
	if (length(s)>2) then s:=copy(s,length(s)-1,2) else
		if (length(s)=1) then s:='0'+s;
	Zeropad:=s;
end;

function time:string;
var h,m,ampm:string[3];
		hh,mm,ss,ss100:word;
begin
	gettime(hh,mm,ss,ss100);
	if (hh > 11) then
		ampm := ' pm'
	else
		ampm := ' am';
	if (hh > 12) then
		dec(hh,12);
	if (hh = 0) then
		hh := 12;
	str(hh,h); str(mm,m);
	time:=h+':'+Zeropad(m)+ampm;
end;

function date:string;
var y,m,d:string[4];
    yy,mm,dd,dow:word;

begin
	getdate(yy,mm,dd,dow);
	str(yy,y); str(mm,m); str(dd,d);
  date:=Zeropad(m)+'-'+Zeropad(d)+'-'+y;
end;


function value(s:astr):longint;
var i:longint;
		j:integer;
begin
	val(s,i,j);
	if (j > 0) then
		begin
			s[0] := chr(j-1);
			val(s,i,j)
		end;
	value := i;
	if (s = '') then
		value := 0;
end;

function Ageuser(const birthdate:longint):integer;
var
  dt1:datetime;
  dt2:datetime;
  i:integer;
begin
  PackToDate(dt1, birthdate);
  GetDateTime(dt2);
  i := dt2.year - dt1.year;
  if (dt2.month < dt1.month) then
    dec(i);
  if (dt2.month = dt1.month) and (dt2.day < dt1.day) then
    dec(i);
  Ageuser := i;
end;

function allcaps(s:string):string;
var
	i:integer;
begin
	for i:=1 to length(s) do
		if (s[i] in ['a'..'z']) then
			s[i] := chr(ord(s[i]) - ord('a')+ord('A'));
	allcaps:=s;
end;

function caps(s:string):string;
var i:integer;		{ must be integer, otherwise 0 length arg fucks up }
begin
  if (s[1] in ['a'..'z']) then
    dec(s[1], 32);

  for i := 2 to length(s) do
    if (s[i - 1] in ['a'..'z','A'..'Z']) then
      if (s[i] in ['A'..'Z']) then
        inc(s[i], 32)
      else
    else
      if (s[i] in ['a'..'z']) then
        dec(s[i], 32);

	caps := s;
end;

function days(var mo,yr:integer):integer;
var d:integer;
begin
	d:=value(copy('312831303130313130313031',1+(mo-1)*2,2));
	if ((mo=2) and (yr mod 4 = 0)) then inc(d);
	days:=d;
end;

function daycount(var mo,yr:integer):integer;
var
	m,t:integer;
begin
	t:=0;
	for m:=1 to (mo-1) do
		t:=t+days(m,yr);
	daycount:=t;
end;

function daynum(dt:str10):integer;
var
	d,m,y,c,t:integer;
begin
	t:=0;
	m:=value(copy(dt,1,2));
	d:=value(copy(dt,4,2));
	y:=value(copy(dt,7,4));
	for c:=1985 to y-1 do
		if (c mod 4 = 0) then inc(t,366) else inc(t,365);
	t:=t+daycount(m,y)+(d-1);
	daynum:=t;
	if y<1985 then daynum:=0;
end;

function dat:string;
var year,month,day,dayofweek,hour,minute,second,sec100:word;
		ap:string[2];
begin
	getdate(year,month,day,dayofweek);
	gettime(hour,minute,second,sec100);

	if (hour<12) then ap:='AM'
	else begin
		ap:='PM';
		if (hour>12) then dec(hour,12);
	end;
	if (hour=0) then hour:=12;

	dat:=cstr(hour)+':'+Zeropad(cstr(minute))+' '+ap+'  '+
			 copy(DayString[dayofweek],1,3)+' '+
			 copy(MonthString[month],1,3)+' '+cstr(day)+', '+cstr(year);
		{5:43 pm	Fri Feb 18, 2000}
end;

procedure SerialOut(s:string);
begin
	if outcom then
{$IFDEF MSDOS}	
		with regs do
			repeat
				if (digiboard in liner.mflags) then
					begin
						ah:=$0e;
						bx:=ofs(s[1]);
					end
				else
					begin
						ah:=$19;
						di:=ofs(s[1]);
					end;
				cx := length(s);
				dx:=FossilPort;
				es:=seg(s[1]);
				intr($14,regs);
				move(s[ax + 1], s[1],length(s) - ax);
				dec(s[0], ax);
			until (s='');
{$ENDIF}
{$IFDEF WIN32}
        begin
            if Not(DidInit) then Exit;
            EleNorm.Com_SendString(s);
	    end;
{$ENDIF}
end;

function getc(c:byte):string;
const xclr:array[0..7] of char=('0','4','2','6','1','5','3','7');
var s:string[10];
		b:boolean;


	procedure adto(ss:str8);
	begin
		if (s[length(s)]<>';') and (s[length(s)]<>'[') then s:=s+';';
		s:=s+ss; b:=TRUE;
	end;

begin
	b:=FALSE;
	if ((curco and (not c)) and $88)<>0 then begin
		s:=#27+'[0';
		curco:=$07;
	end else
		s:=#27+'[';
	if (c and 7<>curco and 7) then adto('3'+xclr[c and 7]);
	if (c and $70<>curco and $70) then adto('4'+xclr[(c shr 4) and 7]);
	if (c and 128<>0) then adto('5');
	if (c and 8<>0) then adto('1');
	if (not b) then adto('3'+xclr[c and 7]);
	s:=s+'m';
	getc:=s;
end;

procedure setc(c:byte);
begin
	if not (okansi or okavatar) then
		begin
			textattr:=7;
			exit;
		end;

	if (c<>curco) then begin
		if not (color in thisuser.flags) then
			if (c and 8 = 8) then
				 c:=15
			else
				 c:=7;
		if (outcom) then
			if (okavatar) then
				SerialOut(^V^A+chr(c and $7f))
			else
				SerialOut(getc(c));
		textattr:=c;
		curco:=c;
	end;
end;

procedure UserColor(c:integer);
begin
	if (c in [0..9]) then
		if (okansi or okavatar) then
			setc(Scheme.Color[c + 1]);
end;

function sqoutsp(s:string):string;
begin
	while (pos(' ',s)>0) do delete(s,pos(' ',s),1);
	sqoutsp:=s;
end;

function ExtractDriveNumber(s:astr):byte;
begin
	s:=fexpand(s);
	ExtractDriveNumber:=ord(s[1])-64;
end;

function mln(s:string; l:byte):string;
var
	x,j:byte;
begin
	x := lennmci(s);
	if (x > l) then
    while (x > l) do  { can't be done more efficiently, old one had probs }
      begin                      { dealing with the last chars being MCIs }
        s[0] := chr(l + (length(s) - x));
        x := lennmci(s);
      end
	else
		for j := x to l - 1 do
			s := s + ' ';
	mln:=s;
end;

function mrn(s:string; l:byte):string;
var
	x,b:byte;
begin
	x := lennmci(s);
	for b := x to l - 1 do
		s := ' ' + s;
	if x > l then
		s[0] := chr(l + (length(s) - x));
	mrn:=s;
end;

function mn(i:longint; l:byte):string;
begin
	mn:=mln(cstr(i),l);
end;

procedure prompt(const s:string);
var
	old:boolean;
begin
	old:=allowAbort;
	allowAbort:=FALSE;
  printmain(s);
	allowAbort:=old;
end;

procedure print(const s:string);
begin
	prompt(s+^M^J);
end;

procedure nl;
begin
	prompt(^M^J);
end;

procedure prt(const s:string);
begin
	UserColor(4); prompt(s); UserColor(3);
end;

procedure mpl(c:integer);
var i:integer;
		x:byte;
begin
	if (okansi or okavatar) then
		begin
			UserColor(6);
			x:=wherex;
			if (outcom) then
				for i:=1 to c do com_tx(' ');
			if (wantout) then
				for i:=1 to c do write(' ');
			gotoxy(x,wherey);
			if (outcom) then
				begin
					if (okavatar) then
						SerialOut(^Y+^H+chr(c))
					else
						SerialOut(#27+'['+cstr(c)+'D');
				end;
		end;
end;

function empty:boolean;
begin
	Empty := not Keypressed;
	if (Incom) and (not Keypressed) then
		begin
{$IFDEF MSDOS}
			regs.dx := FossilPort;
			regs.ah := $03;
			intr($14, regs);
			Empty := not (regs.ah and 1 = 1);
{$ENDIF}
{$IFDEF WIN32}
            if Not(DidInit) then Exit;
            empty := Not(EleNorm.Com_CharAvail);
{$ENDIF}  
		end;
end;

function inkey:word;
var
  c:char;
  l:longint;
begin
  c := #0; inkey := 0;
  CheckHangup;
  if (keypressed) then
    begin
      c := readkey;
      if (c = #0) and (keypressed) then
        begin
          c := readkey;
          skey1(c);
          if (c = #68) then
            c := #1
          else
            begin
              inkey := ord(c) * 256;        { Return scan code in MSB }
              exit;
            end;
        end;
      if (buf <> '') then
        begin
          c := buf[1];
          buf := copy(buf, 2, 255);
        end;
      inkey := ord(c);
    end
  else
    if (incom) then
      begin
        c := cinkey;
        if (c = #27) then
          begin
            if empty then
              delay(100);

            if (c = #27) and not empty then
              begin
                c := cinkey;
                if (c = '[') or (c = 'O') then
                  begin
                    l := ticks + 4;
                    c := #0;
                    while (l > ticks) and (c = #0) do
                      c := cinkey;
                  end;

                case char(c) of
                  'A':inkey := F_UP;      {UpArrow}
                  'B':inkey := F_DOWN;    {DownArrow}
                  'C':inkey := F_RIGHT;   {RightArrow}
                  'D':inkey := F_LEFT;    {LeftArrow}
                  'H':inkey := F_HOME;    {Home}
                  'K',                {End - PROCOMM+}
                  'R':inkey := F_END;     {End - GT}
                  'r':inkey := F_PGUP;    {PgUp}
                  'q':inkey := F_PGDN;    {PgDn}
                  'n':inkey := F_INS;     {Ins}
                end;
                exit;
              end;
          end;
        if (c = #127) then
          inkey := F_DEL
        else
          inkey := ord(c);
      end;
end;

procedure outtrap(c:char);
begin
	if (c<>^G) then
		write(trapfile,c);
	if (IOResult > 0) then
    begin
      sysoplog('error writing to trap file.');
      trapping := FALSE;
    end;
end;

procedure outkey(c:char);
var bb:byte;
begin
	if (not echo) then
		if (general.localsec) and (c in [#32..#255]) then
			c:=fstring.echoc;

	if (c in [#27,^V,^Y]) then
		dosansion:=TRUE;

	if wantout and dosansion and (NextState <> Waiting) then
		begin
			dosansi(c);
			if (outcom) then
				com_tx(c);
			exit;
		end
	else
		if (c <> ^J) and (c <> ^L) then
			if (wantout) and (not dosansion) and not ((c=^G) and incom) then
				write(c)
			else
				if wantout and not ((c=^G) and incom) then
					dosansi(c);

	if (not echo) and (c in [#32..#255]) then
		c:=fstring.echoc;


	case c of
		^J:begin
				 if (not ch) and (not write_msg) and (not ctrljoff) and (not dosansion)
					 then
						 begin
							 if (((curco shr 4) and 7) > 0) or (curco and 128 = 128) then
								 setc(Scheme.Color[1])
						 end
					 else
						 lil := 1;
         if (trapping) then
           OutTrap(c);
				 if (wantout) then
					 write(^J);
				 if (outcom) then
					 com_tx(^J);
				 inc(lil);
				 if (lil >= pagelength) then
					 begin
						 lil := 1;
						 if TempPause then
							 pausescr(TRUE);
					 end;
			 end;
		^L:begin
				 if (wantout) then
					 clrscr;
				 if (outcom) then
					 com_tx(^L);
				 lil := 1;
			 end;
	 else
     begin
       if (outcom) then
         com_tx(c);
       if (trapping) then OutTrap(c);
     end;
	end;
end;


function pagelength:word;
begin
	if incom then
		pagelength := thisuser.pagelen
	else
		if General.WindowOn and not (InWFCMenu) then
			pagelength := MaxDisplayRows - 2
		else
			pagelength := MaxDisplayRows;
end;

procedure TeleConfCheck;
var
	i:byte;
	f:file;
	s:string;
	oldmciallowed:boolean;
{ Only check if we're bored and not slicing }
begin
	if (maxchatrec > nodechatlastrec) then
		begin
			for i := 1 to lennmci(mlc) + 5 do
				backspace;
			assign(f, general.multpath + 'message.'+cstr(node));
			reset(f, 1);
			seek(f, nodechatlastrec);
			while not eof(f) do
				begin
					blockread(f,s[0],1);
					blockread(f,s[1],ord(s[0]));
					multinodechat := FALSE;  {avoid recursive calls during pause!}
					oldmciallowed := mciallowed;
					mciallowed := FALSE;
					print(s);
					mciallowed := oldmciallowed;
					multinodechat := TRUE;
				end;
			close(f);
			Lasterror := IOResult;
			nodechatlastrec := maxchatrec;
			prompt('^3' + mlc);
		end;
end;

function getkey:word;
const
	LastTimeSlice:longint = 0;
	LastCheckTimeSlice:longint = 0;
var
	TempTimer:longint;
	tf:boolean;
	i:integer;
  c:word;
{$IFDEF MSDOS} 
  killme: pointer absolute $0040:$f000;
{$ENDIF}

begin
  if (DIELATER) then
{$IFDEF MSDOS}
    asm
      call killme
    end;
{$ENDIF}
{$IFDEF WIN32}
    Halt;
{$ENDIF}

	lil := 1;
  if (buf <> '') then
		begin
      c := ord(buf[1]);
      buf := copy(buf, 2, 255);
		end
  else
    begin
      if (not empty) then
        begin
          if (ch) then
            c := ord(chinkey)
          else
            c := inkey;
        end
      else
        begin
          tf := FALSE;
          LastKeyHit := timer;
          c := 0;
          while ((c = 0) and (not Hangup)) do
            begin
              TempTimer := timer;
              if (LastScreenSwap > 0) then
                begin
                  if (TempTimer - LastScreenSwap < 0) then
                    LastScreenSwap := Timer - LastScreenSwap + 86400;
                  if (TempTimer - LastScreenSwap > 10) then
                    update_screen;
                end;

              if (alert in thisuser.flags) or ((not shutupchatcall) and (general.chatcall) and (chatr<>'')) then
                begin
                  if (Temptimer - LastBeep) < 0 then
                    LastBeep := (Temptimer - LastBeep) + 86400;
                  if ((alert in thisuser.flags) and ((Temptimer - LastBeep)>=general.alertbeep)) or
                      ((chatr<>'') and (sysopavailable) and ((Temptimer - LastBeep)>=5)) then
                    begin
{$IFDEF MSDOS}
                      for i := 1 to 100 do
                        begin
                          sound(500 + (i * 10));
                          delay(2);
                          sound(100 + (i * 10));
                          delay(2);
                          nosound;
                        end;
{$ENDIF}
{$IFDEF WIN32}
                      sound(500, 200);
					  sound(1500, 200);
{$ENDIF}
                      LastBeep := Temptimer;
                    end;
                end;

              if (Temptimer - LastKeyHit) < 0 then
                LastKeyHit := (Temptimer - LastKeyHit) + 86400;

              if (general.timeout <> -1) and
                 ((TempTimer - LastKeyHit) > general.timeout * 60) and
                 (not timedout) and (Speed <> 0) then begin
                timedout := TRUE;
                printf('timedout');
                if (nofile) then
                  print(^M^J^M^J'Time out - disconnecting.'^M^J^M^J);
                Hangup := TRUE;
                sysoplog('Inactivity timeout at '+time);
              end;

              if (general.timeoutbell <> -1) and
                 ((Temptimer - LastKeyHit) > general.timeoutbell * 60) and (not tf) then begin
                tf := TRUE;
                outkey(^G); delay(100); outkey(^G);
              end;

              if (Empty) then
                begin
                  if (abs((Ticks - LastTimeSlice)) >= SliceTimer) then
                    begin
{$IFDEF MSDOS}
                      case Tasker of
                        None: asm
                                int 28h
                              end;
                        DesqView: asm
                                    mov ax, 1000h
                                    int 15h
                                  end;
                        MSWindows: asm
                                     mov ax, 1680h
                                     int 2Fh
                                   end;
                        OS2: asm
                               push dx
                               xor dx, dx
                               mov ax, 0
                               sti
                               hlt
                               db 035h, 0Cah
                               pop dx
                             end;
                      end;
{$ENDIF}
{$IFDEF WIN32}
                      Sleep(1);
{$ENDIF}
                      LastTimeSlice := Ticks;
                    end
                  else
                    if multinodechat and not ch
                      and (abs(Ticks - LastCheckTimeSlice) > 9) then
                      begin
                        LastCheckTimeSlice := Ticks;
                        TeleConfCheck;
                        lil := 1;
                      end;
                end;

              if (ch) then
                c := ord(chinkey)
              else
                c := inkey;
            end;

            if (useron) and (GetPackDateTime - CreditsLastUpdated > 60) and not (fnocredits in thisuser.flags) then
              begin
                inc(Thisuser.Debit, General.CreditMinute * ((GetPackDateTime - CreditsLastUpdated) DIV 60));
                CreditsLastUpdated := GetPackDateTime;
              end;
        end;
    end;
  getkey := c;
end;

procedure cls;
begin
	if (okansi or okvt100) then
		SerialOut(^[ + '[1;1H' + ^[ + '[2J')
	else
		outkey(^L);
	if (wantout) then clrscr;
	if (trapping) then OutTrap(^L);
	UserColor(1);
	lil := 1;
end;

procedure swac(var u:userrec; r:uflags);
begin
	with u do
		if (r in flags) then
			flags:=flags-[r]
		else
			flags:=flags+[r];
end;

function tacch(c:char):uflags;
begin
	case c of
		'L':tacch:=rlogon;
		'C':tacch:=rchat;
		'V':tacch:=rvalidate;
		'U':tacch:=ruserlist;
		'A':tacch:=ramsg;
		'*':tacch:=rpostan;
		'P':tacch:=rpost;
		'E':tacch:=remail;
		'K':tacch:=rvoting;
		'M':tacch:=rmsg;
		'1':tacch:=fnodlratio;
		'2':tacch:=fnopostratio;
		'3':tacch:=fnocredits;
		'4':tacch:=fnodeletion;
	end;
end;

procedure acch(c:char; var u:userrec);
begin
	swac(u,tacch(c));
end;

{$IFDEF MSDOS}
function aonoff(b:boolean; const s1, s2:astr):string; assembler;
ASM
       PUSH DS
       TEST b, 1
       JZ   @@1
       LDS  SI, s1
       JMP  @@2
@@1:   LDS  SI, s2
@@2:   LES  DI, @Result
       XOR  CH, CH
       MOV  CL, BYTE PTR DS:[SI]
       MOV  BYTE PTR ES:[DI], CL
       INC  DI
       INC  SI
       CLD
       REP  MOVSB
       POP  DS
END;
{$ENDIF}
{$IFDEF WIN32}
function aonoff(b:boolean; const s1, s2:astr):string;
begin
  if (b) then
    aonoff := s1
  else
    aonoff := s2;
end;
{$ENDIF}

function onoff(b:boolean):string;
begin
	if (b) then onoff:='On ' else onoff:='Off';
end;

function syn(b:boolean):string;
begin
	if (b) then syn:='Yes' else syn:='No ';
end;

function yn:boolean;
var c:char;
begin
	if (not Hangup) then begin
		UserColor(3);
		prompt(sqoutsp(syn(dyny)));
		repeat
      c := upcase(char(getkey));
		until (c in ['Y','N',^M]) or (Hangup);
		if (dyny) and (c<>'N') then c:='Y';
		if (dyny) and (c = 'N') then
      print(#8#8#8'No ')
		else
			if (not dyny) and (c = 'Y') then
        print(#8#8'Yes')
			else
				nl;
    UserColor(1);
		yn := (c = 'Y') and not Hangup;
	end;
	dyny:=FALSE;
end;

function pynq(const s:astr):boolean;
begin
	UserColor(7); prompt(s);
	pynq:=yn;
end;

procedure onek(var c:char; ch:astr);
var
	s:string[3];
begin
  TempPause := (pause in thisuser.flags);
	repeat
    c := upcase(char(getkey));
	until (pos(c, ch) > 0) or (Hangup);
	if (Hangup) then c:=ch[1];
	if (onekda) then
		outkey(c);
	if (trapping) then OutTrap(c);
	if (onekcr) then nl;
	onekcr:=TRUE;
	onekda:=TRUE;
end;

function centre(s:astr):string;
var i,j:integer;
begin
	i := lennmci(s);
	if i < thisuser.linelen then
		begin
			j := (thisuser.linelen - i) div 2;
			move (s[1],s[j+1],length(s));
			inc (s[0],j);
			fillchar (s[1],j,#32);
		end;
	centre:=s;
end;

procedure wkey;
var c:char;
begin
	if (not allowAbort) or (Abort) or (Hangup) or (empty) then exit;
  c := char(getkey);
	if (displayingmenu) and (pos(upcase(c),menukeys)>0) then
		begin
			menuAborted:=TRUE;
			Abort:=true;
			buf:=buf+upcase(c);
		end
	else
		case upcase(c) of
		 ' ',^C,^X,^K:Abort:=TRUE;
					 'N',^N:if (reading_a_msg) then
										begin
											Abort:=TRUE;
											Next:=TRUE;
										end;
           'P',^S:c := char(getkey);
			else
				if (reading_a_msg) or (printingfile) then
					if (c <> #0) then
						buf := buf + c;
		end;
	if (Abort) then
		begin
			com_purge_tx;
			nl;
		end;
end;

function ctim(rl:longint):string;
var h,m,s:string[2];
begin
	h := Zeropad(cstr(rl div 3600));	rl := rl mod 3600;
	m := Zeropad(cstr(rl div 60));		rl := rl mod 60;
	s := Zeropad(cstr(rl));
	ctim:=h+':'+m+':'+s;
end;

{$IFDEF MSDOS}
function cstr(l:longint):string;
var
	Result: ^string;
begin
	Inline($89/$EC/$16/$FF/$76/$0A); {set pointer to function}
	str(l,Result^);
end;
{$ENDIF}
{$IFDEF WIN32}
function cstr(l:longint):string;
var
  Result: string;
begin
  str(l, Result);
  cstr := Result;
end;
{$ENDIF}

procedure printmain(const ss:string);
var i,x:word;
		x2:byte;
		c:char;
		cs:string;
    s:string;
    Justify:byte;
begin
	if (Abort) and (allowAbort) then
		exit;

	if (Hangup) then
		begin
			Abort:=TRUE;
			exit;
		end;


  if (not MCIAllowed) then
    s := ss
  else
    begin
      s := '';
      for i := 1 to length(ss) do
        if (ss[i] = '%') and (i + 2 <= length(ss)) then
          begin
            cs := MCI(copy(ss,i,3));      { faster than adding }
            if (cs = copy(ss,i,3)) then
              begin
                s := s + '%';
                continue;
              end;
            inc(i, 2);
            if (length(ss) >= i + 2) and (ss[i + 1] in ['#','{','}']) then
              begin
                if (ss[i + 1] = '}') then
                  Justify := 0
                else if (ss[i + 1] = '{') then
                  Justify := 1
                else
                  Justify := 2;
                if (ss[i + 2] in ['0'..'9']) then
                  begin
                    x2 := ord(ss[i + 2]) - 48;
                    inc(i, 2);
                    if (ss[i + 1] in ['0'..'9']) then
                      begin
                        x2 := x2 * 10 + ord(ss[i + 1]) - 48;
                        inc(i, 1);
                      end;
                    if (x2 > 0) then
                      case Justify of
                        0:cs := mrn(cs, x2);
                        1:cs := mln(cs, x2);
                        2:while (length(cs) < x2) do
                            begin
                              cs := ' ' + cs;
                              if (length(cs) < x2) then
                                cs := cs + ' ';
                            end;
                      end;
                  end;
              end;
            { s := s + cs; }
            if (length(cs) + length(s) <= 255) then
              begin
                move(cs[1], s[length(s)+1], length(cs));
                inc(s[0], length(cs));
              end
            else
              if (length(s) < 255) then
                begin
                  move(cs[1], s[length(s)+1], 255-length(s));
                  s[0] := #255;
                end;
          end
        else
          if (length(s) < 255) then   { s := s + ss[i]; }
            begin
              inc(s[0]);
              s[length(s)] := ss[i];
            end;
    end;

	if not (okansi or okavatar) then
    s := stripcolor(s);

  i := 1;
  if ((not abort) or (not allowAbort)) and (not Hangup) then  { can't change in loop }
    while (i <= length(s)) do
      begin
        case s[i] of
          '%':if mciallowed and (i + 1 < length(s)) then
                 begin
                   if (upcase(s[i + 1]) = 'P') and (upcase(s[i + 2]) = 'A') then
                     begin
                       inc(i, 2);
                       pausescr(FALSE)
                     end
                   else
                     if (upcase(s[i + 1]) = 'D') then
                       if (upcase(s[i + 2]) = 'E') then
                         begin
                           inc(i, 2);
                           outkey(' '); outkey(#8); { guard against +++ }
                           delay(800);
                         end
                       else
                         if ((upcase(s[i + 2]) = 'F') and (not printingfile)) then
                           begin
                             cs := ''; inc(i, 3);
                             while (i < length(s)) and (s[i] <> '%') do
                               begin
                                 cs := cs + s[i];
                                 inc(i);
                               end;
                             printf(stripname(cs));
                           end
                         else
                     else
                       outkey('%');
                 end
               else
                 outkey('%');
          ^S:if (i < length(s)) and (NextState = Waiting) then
               begin
                 if (ord(s[i + 1]) <= 200) then
                   setc(Scheme.Color[ord(s[i + 1])]);
                 inc(i);
               end
             else
               outkey('');
         '|':if (colorallowed) and (i + 1 < length(s)) and
                (s[i + 1] in ['0'..'9']) and (s[i + 2] in ['0'..'9']) then
               begin
                 x := value(copy(s,i + 1,2));
                 case x of
                   0..15:setc(curco - (curco mod 16) + x);
                   16..23:setc(((x - 16) * 16) + (curco mod 16));
                 end;
                 inc(i,2);
               end
             else
               outkey('|');
           #9:for x := 1 to 5 do
                outkey(' ');
         '^':if (colorallowed) and (i < length(s)) and (s[i+1] in ['0'..'9']) then
               begin
                 inc(i);
                 UserColor(ord(s[i]) - 48);
               end
             else
               outkey('^');
          else
            outkey(s[i]);
        end;
        inc(i);
        x2:=i;
        while (x2 < length(s)) and
          not (s[x2] in [^S,'^','|','%',^G,^L,^V,^Y,^J,^[]) do
          inc(x2);

        if (x2 > i) then
          begin
            cs[0] := chr(x2 - i);
            move(s[i], cs[1], x2 - i);     { twice as fast as copy(s,i,x2-i); }
            i := x2;

            if (trapping) then
              write(trapfile, cs);

            if wantout then
              if not dosansion then
                write(cs)
              else
                for x2 := 1 to length(cs) do
                  dosansi(cs[x2]);

            SerialOut(cs);
          end;
      end;
	wkey;
end;

procedure printacr(s:string);
var
	okdoit,turnoff:boolean;
begin
	if ((allowAbort) and (Abort)) then exit;

	Abort:=FALSE;

	turnoff:=(s[length(s)]=#29);
	if turnoff then
		dec(s[0]);

	okdoit:=TRUE;

  CheckHangup;

	if (not croff) and not (turnoff) then
		s := s + ^M^J;

	printmain(s);

	if (Abort) then
		begin
			curco:=255-curco;  {***}
			UserColor(1);
		end;

	croff:=FALSE;
end;

procedure pfl(fn:astr);
var fil:text;
		ls:string[255];
		ps:byte;
		c:char;
		OldPause,ToggleBack,oaa:boolean;
begin
	printingfile:=TRUE;
	oaa:=allowAbort;
  allowAbort:=TRUE;
	Abort:=FALSE; Next:=FALSE;
	ToggleBack := FALSE;
	OldPause := TempPause;
	fn := allcaps(fn);
	if General.WindowOn and (pos('.AN',fn) > 0) or (pos('.AV',fn) > 0) then
		begin
			TempPause := FALSE;
			ToggleBack := TRUE;
			ToggleWindow(FALSE);
			if (OkRIP) then
				SerialOut('!|*|');
		end;
	if (pos('.RI',fn) > 0) then
		TempPause := FALSE;
	if (not Hangup) then begin
		assign(fil,sqoutsp(fn));
		reset(fil);
		if (ioresult > 0) then
			nofile:=TRUE
		else begin
			Abort:=FALSE;
			while (not eof(fil)) and (not Abort) and (not Hangup) do begin
				ps:=0;
				repeat
					inc(ps);
					read(fil,ls[ps]);
					if eof(fil) then								{check again incase avatar parameter}
						begin
							inc(ps);
							read(fil,ls[ps]);
							if eof(fil) then dec(ps);
						end;
        until ((ls[ps] = ^J) and (NextState in [Waiting..In_Param]))
							or (ps = 255) or eof(fil);
				ls[0]:=chr(ps);
				croff:=TRUE;
				CtrlJOff := ToggleBack;
				printacr(ls);
			end;
			close(fil);
		end;
		nofile := FALSE;
	end;
	allowAbort:=oaa;
	printingfile:=FALSE; ctrljoff:=FALSE;
	if ToggleBack then
		ToggleWindow(TRUE);
	redrawforansi;
	if not TempPause then
		lil := 0;
	TempPause := OldPause;
end;

function exist(fn:astr):boolean;
var srec:searchrec;
begin
	findfirst(sqoutsp(fn),anyfile,srec);
	exist:=(doserror=0);
end;

procedure printfile(fn:astr);
var s:astr;
		year,month,day,dayofweek:word;
		i,j:integer;
begin
	fn:=allcaps(fn); s:=fn;
	if (copy(fn,length(fn) - 3,4)='.ANS') then
		begin
			if (exist(copy(fn,1,length(fn)-4)+'.AN1')) then
				repeat
					i:=random(10);
					if (i=0) then
						fn:=copy(fn,1,length(fn)-4)+'.ANS'
					else
						fn:=copy(fn,1,length(fn)-4)+'.AN'+cstr(i);
				until (exist(fn));
		end
	else
		if (copy(fn,length(fn) - 3,4)='.AVT') then
			begin
				if (exist(copy(fn,1,length(fn)-4)+'.AV1')) then
					repeat
						i:=random(10);
						if (i=0) then
							fn:=copy(fn,1,length(fn)-4)+'.AVT'
						else
							fn:=copy(fn,1,length(fn)-4)+'.AV'+cstr(i);
					until (exist(fn));
			end
		else
			if (copy(fn,length(fn) - 3,4)='.RIP') then
				begin
					if (exist(copy(fn,1,length(fn)-4)+'.RI1')) then
						repeat
							i:=random(10);
							if (i=0) then
								fn:=copy(fn,1,length(fn)-4)+'.RIP'
							else
								fn:=copy(fn,1,length(fn)-4)+'.RI'+cstr(i);
						until (exist(fn));
				end;

	getdate(year,month,day,dayofweek);
	s:=fn;
	s[length(s) - 1] := chr(dayofweek + 48);
	if (exist(s)) then
		fn := s;
	pfl(fn);
end;

procedure printf(fn:astr);							{ see if an *.ANS file is available }
var ffn,ps,ns,es:astr;									{ if you have ansi graphics invoked }
		i,j:integer;
begin
	nofile:=TRUE;
	fn:=sqoutsp(fn);
	if (fn='') then exit;
  if (pos('\',fn) <> 0) then
    j := 1
  else
    begin
      j:=2;
      fsplit(fexpand(fn),ps,ns,es);
      if (not exist(general.miscpath+ns+'.*')) then exit;
    end;
	ffn:=fn;
	if ((pos('\',fn)=0) and (pos(':',fn)=0)) then
		ffn := general.miscpath + ffn;
	ffn:=fexpand(ffn);
	if (pos('.',fn)<>0) then printfile(ffn)
	else begin
		if (okrip) and exist(ffn+'.rip') then printfile(ffn+'.rip');
		if (nofile) and (okavatar) and exist(ffn+'.avt') then printfile(ffn+'.avt');
		if (nofile) and (okansi) and exist(ffn+'.ans') then printfile(ffn+'.ans');
		if (nofile) and (exist(ffn+'.asc')) then printfile(ffn+'.asc');
	end;
end;

function decode(const x:astr; check:byte):string;
var b:byte;
    s:astr;
    t:byte;
begin
  s := '';
  t := 0;
  for b:=1 to length(x) do
    begin
      s:=s+chr(ord(x[b]) - ord(x[b-1]));
      inc(t, ord(s[b]));
    end;
  if (t XOR check = 0) then
    DIELATER := TRUE;
  decode:=s;
end;

function verline(i:integer):string;
begin
{$IFDEF MSDOS}
  if (i = 1) then
    { verline := '|09The |14Renegade Bulletin Board System|09 Version ' + ver; }
    verline := decode('∞‡m’:Z÷;çÚ`≈,çÒVv∏-ôjﬁGµ’ÜÁYΩ›0©êıbﬁGgΩ"îpﬂMm', 189) + ver
  else
    { verline := '|09Copyright (C)MM by Jeff Herrings. All Rights Reserved.'; }
    verline := decode('µÂa–@π+î˚c◊˜bãÿ%Eß @äÔUª€#à˙l’C™Kk¨Ñ§ˆ_∆.¢5áÏ_ƒ6¨u£', 238);
{$ENDIF}
{$IFDEF WIN32}
  if (i = 1) then
    // verline := '|09The |14Renegade Bulletin Board System|09 Version ' + ver
    verline := decode('∞‡m’:Z÷;çÚ`≈,çÒVv∏-ôjﬁGµ’ÜÁYΩ›0©êıbﬁGgΩ"îpﬂMm', 189) + ver
  else
    verline := '|09Ported MMXIII by Rick Parrish. All Rights Reserved.';
{$ENDIF}
{
  if i=1 then verline:=#3#4'The '#3#5'Renegade Bulletin Board System'#3#4', Version '+ver
    else verline:=#3#4'Copyright (C) 1991-1996 by '#3#9'Cott Lang'#3#4'. All Rights Reserved.'

						 if FALSE then verline:=#3#8'Please ask your sysop to register this copy of Renegade!'
								else verline:=#3#4'Registered to: '#3#9+general.sysopname;
}
end;

function aacs1(u:userrec; un:integer; s:acstring):boolean;
var s1,s2:astr;
		i,p1,p2,j:integer;
    c,c1,c2:char;
		b:boolean;

	procedure getrest;
  var incre:byte;
	begin
    s1 := c;
    p1 := i;
    incre := 0;
    if ((i <> 1) and (s[i - 1] = '!')) then
      begin
        s1 := '!' + s1;
        dec(p1);
      end;
    if (c in ['N','C','E','F','G','I','J','M','O','R','V','Z']) then
      begin
        s1 := s1 + s[i + 1];
        inc(i);
        if c in ['N'] then
          while s[i+1+incre] in ['0'..'9'] do
          begin
            inc (incre);
            s1 := s1 + s[i+1+incre];
          end;
      end
    else
      begin
        j := i + 1;
        while (j <= length(s)) and (s[j] in ['0'..'9']) do
          begin
            s1 := s1 + s[j];
            inc(j);
          end;
        i := j - 1;
      end;
    p2 := i;
	end;

	function argstat(s:astr):boolean;
	var vs:astr;
			year,month,day,dayofweek,hour,minute,second,sec100:word;
			vsi:integer;
			boolstate,res:boolean;
			c:char;
	begin
		boolstate:=(s[1]<>'!');
		if (not boolstate) then s:=copy(s,2,length(s)-1);
		vs:=copy(s,2,length(s)-1); vsi:=value(vs);
		case s[1] of
      'A':res:=(ageuser(u.birthdate)>=vsi);
			'B':res:=((ActualSpeed >= (vsi * 100)) and (vsi > 0)) or (Speed = 0);
			'C':begin
						 res:=(currentconf=vs);
						 c:=vs[1];
             if (not confsystem) and (c >= '@') and (c <='Z') then
							 res:=aacs1(thisuser,usernum,confr.conference[vs[1]].acs);
					end;
			'D':res:=(u.dsl>=vsi) or TempSysOp;
			'E':case upcase(vs[1]) of
						'A':res := okansi;
						'N':res := not (okansi or okavatar or okvt100);
						'V':res := okavatar;
						'R':res := okrip;
						'1':res := okvt100;
					end;
			'F':res:=(upcase(vs[1]) in u.ar);
			'G':res:=(u.sex=upcase(vs[1]));
			'H':begin
						gettime(hour,minute,second,sec100);
						res:=(hour=vsi);
					end;
			'I':res:=Invisible;
			'J':res:=(novice in u.flags);
			'K':res:=(readboard = vsi);
			'L':res:=(readuboard = vsi);
			'M':res:=(unvotedtopics = 0);
			'N':res:=(node=vsi);
			'O':res := sysopavailable;
			'P':res := (u.credit - u.debit >= vsi);
			'R':res:=(tacch(upcase(vs[1])) in u.flags);
			'S':res:=(u.sl>=vsi) or TempSysOp;
      'T':res:=(nsl div 60>=vsi);
			'U':res:=(un=vsi);
			'V':res:=(u.sl > general.validation['A'].newsl);
			'W':begin
						getdate(year,month,day,dayofweek);
            res := (dayofweek = ord(s[2]) - 48);
					end;
			'X':res:=(((u.expiration div 86400) - (getpackdatetime div 86400)) <= vsi) and
							 (u.expiration > 0);
			'Y':res:=(timer div 60 >= vsi);
			'Z':if (fnopostratio in u.flags) then
						res:=TRUE
					else
						if (general.postratio[u.sl] > 0) and
               (u.loggedon > 100 / general.postratio[u.sl]) then
              res:=((u.msgpost / u.loggedon * 100) >= general.postratio[u.sl])
						else
							res:=TRUE;
		end;
		if (not boolstate) then res:=not res;
		argstat:=res;
	end;

begin
	i:=0;
	s:=allcaps(s);
  while (i < length(s)) do
    begin
      inc(i);
      c := s[i];
      if (c in ['A'..'Z']) and (i <> length(s)) then
        begin
          getrest;
          b := argstat(s1);
          delete(s, p1, length(s1));
          if (b) then
            s2 := '^'
          else
            s2 := '%';
          insert(s2, s, p1);
          dec(i, length(s1) - 1);
        end;
    end;
  s := '(' + s + ')';

  while (pos('&', s) <> 0) do delete(s,pos('&',s),1);
  while (pos('^^', s) <> 0) do delete(s,pos('^^',s),1);

  while (pos('(', s) <> 0) do begin
    i := 1;
    while ((s[i] <> ')') and (i <= length(s))) do
      begin
        if (s[i] = '(') then
          p1 := i;
        inc(i);
      end;
    p2 := i;
    s1 := copy(s, p1 + 1, (p2 - p1) - 1);
    while (pos('|', s1) <> 0) do
      begin
        i := pos('|', s1);
        c1 := s1[i - 1];
        c2 := s1[i + 1];
        s2 := '%';
        if ((c1 in ['%','^']) and (c2 in ['%','^'])) then
          begin
            if ((c1 = '^') or (c2 = '^')) then
              s2 := '^';
            delete(s1, i - 1, 3);
            insert(s2, s1, i - 1);
          end
        else
          delete(s1, i, 1);
      end;
    while(pos('%%', s1) <> 0) do delete(s1,pos('%%',s1),1);   {leave only "%"}
    while(pos('^^', s1) <> 0) do delete(s1,pos('^^',s1),1);   {leave only "^"}
    while(pos('%^', s1) <> 0) do delete(s1,pos('%^',s1)+1,1); {leave only "%"}
    while(pos('^%', s1) <> 0) do delete(s1,pos('^%',s1),1);   {leave only "%"}
    delete(s, p1, (p2 - p1) + 1);
    insert(s1, s, p1);
	end;
	aacs1:=(pos('%',s) = 0);
end;

function aacs(s:acstring):boolean;
begin
	aacs:=aacs1(thisuser,usernum,s);
end;

procedure loadnode(i:integer);
begin
	if not general.multinode then exit;
	reset(nodef);
	if (i > 0) and (i <= filesize(nodef)) and (IOResult = 0) then
		begin
			seek(nodef,i - 1);
			read(nodef,noder);
		end;
	close(nodef);
	Lasterror := IOResult;
end;

function update_node(x:byte):byte;
begin
	if general.multinode then
		begin
			loadnode(node);
			update_node := noder.activity;
			if (x > 0) then
				noder.activity:=x;
			if (useron) then
				begin
					noder.user := usernum;
					noder.username := thisuser.name;
					noder.sex := thisuser.sex;
          noder.age := ageuser(thisuser.birthdate);
					noder.citystate := thisuser.citystate;
					noder.logontime := timeon;
          noder.channel := chatchannel;
				end;
			{else
				noder.user := 0;}
			if (x = node) and Invisible then
				noder.status := noder.status + [NInvisible];
			savenode(node);
		end;
end;

function maxchatrec:longint;
begin
	findfirst(general.multpath + 'message.'+cstr(node),0,junkinfo);
	if (doserror = 0) then
		maxchatrec := junkinfo.size
	else
		maxchatrec := 0;
end;

function maxnodes:integer;
begin
	findfirst(general.multpath+'multnode.dat',0,junkinfo);
	if doserror=0 then
		maxnodes:=junkinfo.size div sizeof(noderec)
	else
		maxnodes:=0;
end;

procedure savenode(i:integer);
begin
	if not general.multinode then exit;
	reset(nodef);
	if (i > 0) and (i <= filesize(nodef)) and (IOResult = 0) then
		begin
			seek(nodef,i - 1);
			write(nodef,noder);
		end;
	close(nodef);
	Lasterror := IOResult;
end;

procedure loadurec(var u:userrec; i:integer);
var
	fo:boolean;
begin
	fo := filerec(uf).mode<>fmclosed;
	if not fo then
		begin
			reset(uf);
			if (IOResult > 0) then
				begin
					sysoplog('error opening user file.');
					runerror(5);
				end;
		end;

	if (i <> usernum) or (not useron) then begin
		seek(uf,i);
		read(uf,u);
	end else
		u:=thisuser;

	if not fo then
		close(uf);

	Lasterror := IOResult;
end;

procedure saveurec(u:userrec; i:integer);
var
	fo:boolean;
begin
	fo := filerec(uf).mode<>fmclosed;
	if not fo then
		begin
			reset(uf);
			if (IOResult > 0) then
				begin
					sysoplog('error opening user file.');
					runerror(5);
				end;
		end;

	seek(uf,i);
	write(uf,u);

	if not fo then
		close(uf);

	if (i = usernum) then
		thisuser := u
	else
	 if general.multinode then
		 begin
			 i := onnode(i);
			 if (i > 0) then
				 begin
					 loadnode(i);
					 noder.status := noder.status + [NUpdate];
					 savenode(i);
				 end;
		 end;

	Lasterror := IOResult;
end;

function maxusers:integer;
begin
	findfirst(general.datapath+'users.dat',0,junkinfo);
	if (doserror = 0) then
		maxusers := junkinfo.size div sizeof(userrec)
	else
		maxusers := 0;
end;

procedure loadsfrec(i:integer; var sr:useridxrec);
var
	fo:boolean;
begin
	fo := filerec(sf).mode<>fmclosed;
	if not fo then
		reset(sf);
	seek(sf,i);
	read(sf,sr);
	if not fo then
		close(sf);
	Lasterror := IOResult;
end;

procedure savesfrec(i:integer; sr:useridxrec);
var
	fo:boolean;
begin
	fo := filerec(sf).mode<>fmclosed;
	if not fo then
		reset(sf);
	seek(sf,i);
	write(sf,sr);
	if not fo then
		close(sf);
	Lasterror := IOResult;
end;

function maxsf:integer;
begin
	findfirst(general.datapath+'users.idx',0,junkinfo);
	if (doserror = 0) then
		maxsf := junkinfo.size div sizeof(useridxrec)
	else
		maxsf := 0;
	if (not useron) and (junkinfo.size mod sizeof(useridxrec) <> 0) then
		maxsf := -1;		{ useron is so it'll only slow during boot up }
end;

function himsg:integer;
begin
	findfirst(general.msgpath+memboard.filename+'.HDR',0,junkinfo);
	if (doserror = 0) then
		himsg := junkinfo.size div sizeof(mheaderrec)
	else
		himsg := 0;
end;

function Usename(b:byte; s:string):string;
begin
	case b of
		1,
		2:s:=fstring.anonymous;
		3:s:='Abby';
		4:s:='Problemed Person';
	else
		s:=caps(s);
	end;
	Usename:=s;
end;

procedure com_flush_rx;
begin
	if not LocalIOOnly then
		if not InWfcMenu then
			begin
{$IFDEF MSDOS}
				regs.dx := FossilPort;
				if (DigiBoard in liner.mflags) then
					regs.ah := $9
				else
					regs.ah := $A;
				intr($14, regs);
{$ENDIF}
{$IFDEF WIN32}
                if Not(DidInit) then Exit;
                EleNorm.Com_PurgeInBuffer;
{$ENDIF}
			end
		else
			begin
				while not (Com_RX_Empty) do
					WriteWFC(cinkey);
			end;
end;

function com_tx_empty:boolean;
{$IFDEF WIN32}
var InFree, OutFree, InUsed, OutUsed: Longint;
{$ENDIF}
begin
	Com_TX_Empty := TRUE;
	if not LocalIOOnly then
		begin
{$IFDEF MSDOS}
			regs.dx := FossilPort;
			regs.ah := $3;
			intr($14, regs);
			Com_TX_Empty := (regs.ah and 64 = 64);
{$ENDIF}
{$IFDEF WIN32}
            if Not(DidInit) then Exit;
            EleNorm.Com_GetBufferStatus(InFree, OutFree, InUsed, OutUsed);
            com_tx_empty := (OutUsed = 0);
{$ENDIF}
		end;
end;

procedure com_flush_tx;
var
	r:longint;
begin
	r := timer + 5;
	while (r > timer) and (outcom and com_carrier) and (not com_tx_empty) do;
end;

procedure com_purge_tx;
begin
	if not LocalIOOnly then
		begin
{$IFDEF MSDOS}
			regs.dx := FossilPort;
			regs.ah := $9;
			intr($14, regs);
{$ENDIF}
{$IFDEF WIN32}
            if Not(DidInit) then Exit;
            EleNorm.Com_PurgeOutBuffer;
{$ENDIF}
		end;
end;

{$IFDEF MSDOS}
function com_carrier:boolean; assembler;
asm
	mov al, 1
	cmp localioonly, 1
	je @getout
	mov dx, Fossilport
	mov ah, 3
	pushf
	call interrupt14
	and al, 10000000b
	jnz @getout
	xor al, al
	@getout:
end;
{$ENDIF}
{$IFDEF WIN32}
function com_carrier:boolean;
begin
    com_carrier := true;
    if (localioonly) then Exit;
    if Not(DidInit) then Exit;
    com_carrier := EleNorm.Com_Carrier;
end;
{$ENDIF}

function com_rx:char;
{$IFDEF WIN32}
var ch: char;
{$ENDIF}
begin
	Com_RX := #0;
	if not LocalIOOnly then
		begin
{$IFDEF MSDOS}
			regs.dx := FossilPort;
			if (DigiBoard in liner.mflags) then
				regs.ah := $8
			else
				regs.ah := $C;
			intr($14, regs);
			if (regs.ah <> $FF) then
				begin
					regs.ah := $2;
					intr($14, regs);
					Com_RX := chr(regs.al);
				end;
{$ENDIF}
{$IFDEF WIN32}
            if Not(DidInit) then Exit;
            if Not(EleNorm.Com_CharAvail) then Exit;

            // Get character from buffer
            ch := EleNorm.Com_GetChar;
            if (ch = #10) then
            begin
                // Translate bare LF to CR
                com_rx := #13;
            end else
            begin
                com_rx := ch;
            end;

            // If this char is CR, check if the next char is LF (so we can discard it)
            if (ch = #13) and (EleNorm.Com_CharAvail) then
            begin
                ch := EleNorm.Com_PeekChar;
                if (ch = #10) then EleNorm.Com_GetChar; // Discard that LF
            end;
{$ENDIF}
		end;
end;

function com_rx_empty:boolean;
begin
	Com_RX_Empty := TRUE;

	if not LocalIOOnly then
		begin
{$IFDEF MSDOS}
			regs.dx := FossilPort;
			regs.ah := $3;
			intr($14, regs);
			Com_RX_Empty := not (regs.ah and 1 = 1);
{$ENDIF}
{$IFDEF WIN32}
            if Not(DidInit) then Exit;
            com_rx_empty := Not(EleNorm.Com_CharAvail);
{$ENDIF}
		end;
end;

procedure com_tx(c:char);
begin
	if not LocalIOOnly then
{$IFDEF MSDOS}
		with regs do
			if (DigiBoard in liner.mflags) then
				begin
					repeat
						ah := $1;
						al := ord(c);
						dx := FossilPort;
						intr($14, regs);
					until not (regs.ah and 128 = 128);
				end
			else
				begin
					ah := $1;
					al := ord(c);
					dx := FossilPort;
					intr($14, regs);
				end;
{$ENDIF}
{$IFDEF WIN32}
        begin
            if Not(DidInit) then Exit;
            EleNorm.Com_SendChar(c);
        end;
{$ENDIF}
end;

procedure com_set_speed(speed:longint);
begin
	if not LocalIOOnly then
		begin
{$IFDEF MSDOS}
			if (DigiBoard in liner.mflags) then
				begin
					regs.ah := $04;
					regs.bh := 0;
					regs.bl := 1;
					regs.ch := 3;
					case Speed of
						 300:regs.cl := $2;
						 600:regs.cl := $3;
						1200:regs.cl := $4;
						2400:regs.cl := $5;
						4800:regs.cl := $6;
						9600:regs.cl := $7;
					 19200:regs.cl := $8;
					end;
					if (Speed = 38400) then regs.cl := $9
						else if (Speed = 57600) then regs.cl := $A;
				end
			else
				begin
					regs.ah := $00;
					case Speed of
						 300:regs.al :=  64;
						 600:regs.al :=  96;
						1200:regs.al := 128;
						2400:regs.al := 160;
						4800:regs.al := 192;
						9600:regs.al := 224;
					 19200:regs.al := 	0;
					 else
						 regs.al := 32;
					end;
					inc(regs.al, 3);
				end;
			regs.dx := FossilPort;
			intr($14, regs);
{$ENDIF}
{$IFDEF WIN32}
            if Not(DidInit) then Exit;
            // REENOTE Telnet can't set speed
{$ENDIF}
		end;
end;

procedure com_deinstall;
begin
	if not LocalIOOnly and not (DigiBoard in liner.mflags) then
		begin
{$IFDEF MSDOS}
			regs.dx := FossilPort;
			regs.ah := $5;
			intr($14, regs);
{$ENDIF}
{$IFDEF WIN32}
            if Not(DidInit) then Exit;
            EleNorm.Com_ShutDown;
{$ENDIF}
		end;
end;

procedure dtr(status:boolean);
begin
	if not LocalIOOnly then
		begin
{$IFDEF MSDOS}
			if (DigiBoard in liner.mflags) then
				if status then
					regs.ah := $13
				else
					regs.ah := $B
			else
				regs.ah := $6;

			regs.al := byte(Status);
			intr($14, regs);
{$ENDIF}
{$IFDEF WIN32}
            if Not(DidInit) then Exit;
            // REENOTE Telnet can't set DTR
{$ENDIF}
		end;
end;

procedure scaninput(var s:astr; const allowed:astr);
var os:astr;
		i:integer;
		c:char;
		gotcmd:boolean;
begin
	gotcmd:=FALSE;
	s:='';
	repeat
    c:=upcase(char(getkey));
		os:=s;
		if ((pos(c,allowed)<>0) and (s='')) then
			begin
				gotcmd:=TRUE;
				s:=c;
			end
		else
			if (pos(c,'0123456789') > 0) or (c = '-') then
				begin
					if ((length(s) < 5) or
							((pos('-', s) > 0) and (length(s) < 9))) then s := s + c;
				end
			else
				if ((s<>'') and (c=^H)) then
					dec(s[0])
				else
					if (c=^X) then
						begin
							for i:=1 to length(s) do backspace;
							s:=''; os:='';
						end
					else
						if (c = #13) then gotcmd:=TRUE;
		if (length(s)<length(os)) then backspace;
		if (length(s)>length(os)) then prompt(s[length(s)]);
	until ((gotcmd) or (Hangup));
	nl;
end;

procedure screendump(const f:astr);
var t:text;
		x,y:byte;
		vidseg:word;
		s:astr;
		c:char;
begin
	assign(t,f);
	append(t);
  if (ioresult = 2) then
		rewrite(t);
	if (MonitorType = 7) then
		vidseg:=$B000
	else
		vidseg:=$B800;
	for y:=1 to MaxDisplayRows do begin
		s:='';
		for x:=1 to MaxDisplayCols do begin
{$IFDEF MSDOS}	
			 c:=chr(mem[vidseg:(160*(y-1)+2*(x-1))]);
{$ENDIF}
{$IFDEF WIN32}
             c:=SysReadCharAt(x-1, y-1);
{$ENDIF}
			 if (c=#0) then c:=#32;
			 if ((x=wherex) and (y=wherey)) then c:=#178;
			 s:=s+c;
		end;
		while s[length(s)] = ' ' do
			dec(s[0]);
    writeln(t,s);
	end;
	close(t);
	Lasterror := IOResult;
end;

procedure inputpath(const s:astr; var v:astr);
var
	changed:boolean;
begin
	print('^1'+s);
  prt(':'); mpl(39);
  inputwn1(v, 39, 'ui', changed);
  if (v[length(v)] <> '\') and (length(v) > 0) then
		v := v + '\';
end;

function onnode(x:word) : byte;
var i:byte;
begin
	onnode := 0;
	if general.multinode and (x > 0) then
		for i := 1 to maxnodes do
			begin
				loadnode(i);
				if (noder.user = x) then
					begin
						onnode := i;
						exit;
					end;
			end;
end;

procedure purgedir(s:astr; SubDirs:boolean);
{
 Deletes everything in given directory, including recursive
 directories. Deletes directory if SubDirs is TRUE, thus deletes
 any directories under s, no matter what.
}
var
	odir:string[80];
	dirinfo:searchrec;
	f:file;
begin
	s:=fexpand(s);
	while s[length(s)] = '\' do
		dec(s[0]);
	getdir(ExtractDriveNumber(s),odir);
	chdir(s);
	if (IOResult <> 0) then
		begin
			chdir(odir);
			exit;
		end;
	findfirst('*.*',AnyFile,dirinfo);
	while (doserror = 0) do
		begin
			if (dirinfo.attr = Directory) and
				 (dirinfo.name <> '.') and
				 (dirinfo.name <> '..') then
				purgedir(s + '\' + dirinfo.name, TRUE)
			else
				begin
          assign(f,fexpand(dirinfo.name));
					setfattr(f,0);
					erase(f);
					Lasterror := IOResult;
				end;
			findNext(dirinfo);
		end;
	chdir(odir);
	if SubDirs then
		rmdir(s);
	Lasterror := IOResult;
	chdir(start_dir);
end;

function stripname(s:astr):string;
var
	n:integer;
begin
	n := length(s);
	while (n > 0) and (pos(s[n],':\/') = 0) do
		dec(n);
	delete(s,1,n);
	stripname := s;
end;

procedure star(s:astr);
begin
	if (okansi or okavatar) then prompt('^4˛ ') else prompt('* ');
	if (s[length(s)] = #29) then
    dec(s[0])
  else
    s := s + ^M^J;
  prompt('^3'+s);
end;

function ctp(t,b:longint):string;
var s,s1:astr;
		n:longint;
begin
	if ((t=0) or (b=0)) then
		n := 0
	else
		n := (t * 100) div b;
	str(n:6,s);
	ctp:=s;
end;

function cinkey:char;
begin
	if not (localioonly) and (not com_rx_empty) then
    cinkey := com_rx
  else
    cinkey := #0;
end;

function CRC16(const s:astr):word;
var
	crc:word;
	t,r:byte;
begin
	crc := $FFFF;
	for t:=1 to length(s) do
		begin
			crc:=(crc xor (ord(s[t]) shl 8));
			for r:=1 to 8 do
				if (crc and $8000) > 0 then
					crc := ((crc shl 1) xor $1021)
				else
					crc := (crc shl 1);
		end;
	CRC16 := (crc and $FFFF);
end;

procedure outmodemstring(const s:astr);
var i:integer;
begin
	for i:=1 to length(s) do
		case s[i] of
      '~':delay(250);
			'|':begin
						com_tx(^M);
						if InWFCMenu then
							WriteWFC(^M);
					end;
			'^':begin
						dtr(FALSE);
            delay(250);
						dtr(TRUE);
					end;
		else
			begin
				com_tx(s[i]);
				delay(2);
				if InWFCMenu then
					WriteWFC(s[i]);
			end;
		end;
end;

procedure dophoneHangup(showit:boolean);
var rl:longint;
		try:integer;
		c:char;
begin
	if (not localioonly) then
		begin
      if (showit) and not blankmenunow then
				begin
					textcolor(15);
					textbackground(1);
					gotoxy(32,17);
					write('Hanging up phone...');
				end;
			try:=0;
      while (try < 6) and (not keypressed) do
				begin
					com_flush_rx;
					outmodemstring(Liner.Hangup);
					rl := timer;
					while (abs(timer - rl) <= 2) and (com_carrier) do
						begin
							c := cinkey;
							if (c > #0) and inwfcmenu then
								WriteWFC(c);
						end;
					inc(try);
				end;
		end;
	if showit and sysopon and not blankmenunow then
		begin
			textcolor(15);
			textbackground(1);
			gotoxy(1,17); clreol;
		end;
end;

procedure dophoneoffhook(showit:boolean);
var rl1:longint;
		c:char;
		s:astr;
		Done:boolean;
begin
	if showit and not blankmenunow and sysopon then
		begin
			textcolor(15);
			textbackground(1);
			gotoxy(33,17);
			write('Phone off hook');
		end;
	com_flush_rx;
	outmodemstring(liner.offhook);
	rl1 := timer;
	repeat
		c := cinkey;
		if (c > #0) then
			begin
				if InWFCMenu then
					WriteWFC(c);
				if (length(s) >= 160) then
					delete(s, 1, 120);
				s := s + c;
				if (pos(Liner.OK, s) > 0) then
					Done := TRUE;
			end;
	until (abs(timer - rl1) > 2) or (Done) or (keypressed);
	com_flush_rx;
end;

procedure pausescr(IsCont:boolean);
var
	i:integer;
	c:char;
	bb:byte;
	b:boolean;
begin
	b := mciallowed;
	mciallowed := TRUE;
{$IFDEF MSDOS}
	nosound;
{$ENDIF}
	bb := curco;
  if (not AllowContinue) and not (printingfile and allowabort) then
		IsCont := FALSE;

	if IsCont then
		prompt(fstring.continue)
	else
		prompt(fstring.pause);

	lil := 1;
	if IsCont then
		begin
			onekcr := FALSE;
			onekda := FALSE;
			onek(c,'YNQC '^M);
			case c of
        'C':if IsCont then
							TempPause := FALSE;
				'N':Abort := TRUE;
			end;
		end
	else
    c := char(getkey);

	if IsCont then
    for i := 1 to lennmci(fstring.continue) do
			backspace
	else
    for i := 1 to lennmci(fstring.pause) do
			backspace;
	if Abort then
		nl;
	if (not Hangup) then
		setc(bb);
	mciallowed:=b;
end;

function ambase(x:integer):integer;
var
	y,z:integer;
begin
  if (not general.compressbases) then
    ambase := x
  else
    begin
      z := 0;
      y := 0;
      while (y < x) and (z < MAXBASES) do
        begin
          if (z mod 8) in ccboards[z div 8] then
            inc(y);
          inc(z);
        end;
      ambase := z;
    end;
end;

function cmbase(x:integer):integer;
var
	z,y:integer;
begin
  if (not general.compressbases) then
    cmbase := x
  else
    begin
      z:=1;
      dec(x);
      if (x mod 8) in ccboards[x div 8] then
        for y := 0 to (x - 1) do
          if ((y mod 8) in ccboards[y div 8]) then
            inc(z)
      else
      else
        z := 0;
      cmbase := z;
    end;
end;

function afbase(x:integer):integer;
var
	y,z:integer;
begin
  if (not general.compressbases) then
    afbase := x
  else
    begin
      z := 0;
      y := 0;
      while (y < x) and (z < MAXBASES) do
        begin
          if (z mod 8) in ccuboards[z div 8] then
            inc(y);
          inc(z);
        end;
      afbase := z;
    end;
end;

function cfbase(x:integer):integer;
var
	z,y:integer;
begin
  if (not general.compressbases) then
    cfbase := x
  else
    begin
      z:=1;
      dec(x);
      if (x mod 8) in ccuboards[x div 8] then
        for y := 0 to (x - 1) do
          if ((y mod 8) in ccuboards[y div 8]) then
            inc(z)
      else
      else
        z := 0;
      cfbase := z;
    end;
end;

function searchuser(Uname:astr; RealNameOK:boolean): word;
var
	Current:integer;
	Done:boolean;
	IndexR:useridxrec;
begin

	SearchUser := 0;

	reset(sf);
	if (IOResult > 0) then
		begin
			sysoplog('error opening user file.');
			runerror(5);
		end;

	while (Uname[length(Uname)] = ' ') do
		dec(Uname[0]);

	Uname := Allcaps(Uname);

	Current := 0;
	Done := FALSE;

	if (filesize(sf) > 0) then
		repeat
			seek(sf, Current);
			read(sf, IndexR);
			if (Uname < IndexR.Name) then
				Current := IndexR.Left
			else
				if (Uname > IndexR.Name) then
					Current := IndexR.Right
				else
					Done := TRUE;
		until (Current = -1) or (Done);
	close(sf);

	if (Done) and (RealNameOK or not IndexR.RealName) and (not IndexR.Deleted) then
		SearchUser := IndexR.Number;

	Lasterror := IOResult;
end;

function Plural(Number:longint): string;
begin
	if (Number <> 1) then
		 Plural := 's'
	else
		 Plural := '';
end;

function FormattedTime(TimeUsed:longint) : string;
var
	s:astr;
begin
	s := '';
	if (TimeUsed > 3600) then
		begin
			s := cstr(TimeUsed div 3600) + ' hour' + Plural(TimeUsed div 3600) + ' ';
			TimeUsed := TimeUsed mod 3600;
		end;
	if (TimeUsed > 60) then
		begin
			s := s + cstr(TimeUsed div 60) + ' minute' + Plural(TimeUsed div 60) + ' ';
			TimeUsed := TimeUsed mod 60;
		end;
	if (TimeUsed > 0) then
		s := s + cstr(TimeUsed) + ' second' + Plural(TimeUsed);
	if (s = '') then
		s := 'no time';

	while (s[length(s)] = ' ') do
		dec(s[0]);
	FormattedTime := s + '.';
end;

function FunctionalMCI(const s:astr; FileName, InternalFileName:astr): string;
var
	Index:byte;
	Temp:String;
	Add:astr;
begin
	Temp := '';
	for Index := 1 to length(s) do
		if (s[Index] = '%') then
			begin
				case upcase(s[Index + 1]) of
				 'A':if localioonly then
							 Add := '0'
						 else
							 Add := cstr(ActualSpeed);
				 'B':Add := cstr(Speed);
				 'C':Add := liner.Address;
				 'D':Add := FunctionalMCI(Protocol.DLFList,'','');
				 'E':Add := liner.IRQ;
				 'F':Add := SqOutSp(FileName);
				 'G':if (OKAvatar or OKAnsi) then
							 Add := '1'
						 else
							 Add := '0';
				 'I':Add := InternalFileName;
         'K':begin
               loadfileboard(fileboard);
               if (fbdirdlpath in memuboard.fbstat) then
                 Add := memuboard.dlpath+memuboard.filename+'.DIR'
               else
                 Add := general.datapath+memuboard.filename+'.DIR';
             end;
				 'L':Add := FunctionalMCI(Protocol.TempLog,'','');
				 'M':Add := Start_Dir;
				 'N':Add := Cstr(Node);
				 'O':Add := liner.doorpath;
				 'P':Add := Cstr(Liner.ComPort);
				 'R':Add := Thisuser.RealName;
				 'T':Add := Cstr(nsl div 60);
				 'U':Add := Thisuser.Name;
				 '#':Add := cstr(usernum);
				 '1':Add := Copy(Caps(Thisuser.RealName),1,pos(' ',Thisuser.RealName) - 1);
				 '2':if (pos(' ', Thisuser.RealName) = 0) then
							 Add := Caps(Thisuser.RealName)
						 else
							 Add := Copy(Caps(Thisuser.RealName),pos(' ',ThisUser.RealName) + 1,255);
					else
						Add := '%' + s[Index + 1];
				end;
				Temp := Temp + Add;
				inc(Index);
			end
		else
			Temp := Temp + s[Index];
	FunctionalMCI := Temp;
end;

function MCI(const s:string): string;
var
	Index,I:integer;
	Temp:String;
	Add:astr;
begin
	Temp := '';
	for Index := 1 to length(s) do
		if (s[Index] = '%') and (Index + 1 < Length(s)) then
			begin
				Add := '%' + s[Index + 1] + s[Index + 2];
				with thisuser do
				case upcase(s[Index + 1]) of
					'A':case upcase(s[Index + 2]) of
                'B':Add := FormatNumber(Credit - Debit);
								'D':Add := Street;
								'O':begin
											if (printingfile) or (reading_a_msg) then
												AllowAbort := FALSE;
											Add := '';
										end;
							end;
					'B':case upcase(s[Index + 2]) of
                'D':Add := cstr(ActualSpeed);
								'N':Add := General.BBSName;
								'P':Add := General.BBSPhone;
							end;
          'C':case upcase(s[Index + 2]) of
                'L':Add := ^L;
                'M':Add := cstr(Msg_On);
								'N':Add := Confr.Conference[CurrentConf].Name;
                'R':Add := FormatNumber(Credit);
								'T':Add := CurrentConf;
							end;
					'D':case upcase(s[Index + 2]) of
								'1'..'3':Add := UsrDefStr[ord(s[Index + 2]) - 48];
								'A':Add := Date;
                'B':Add := FormatNumber(Debit);
                'D':Add := FormatNumber(General.DlOneDay[sl]);
                'K':Add := FormatNumber(DK);
                'L':Add := FormatNumber(Downloads);
                'S':Add := cstr(DSL);
                'T':begin
                      if (Timer > 64800) then
                        Add := 'evening'
                      else if (Timer > 43200) then
                        Add := 'afternoon'
                      else Add := 'morning'
                    end;
							end;
					'E':case upcase(s[Index + 2]) of
								'D':if (Expiration = 0) then
                      Add := 'Never'
										else
											Add := todate8(pd2date(Expiration));
                'S':Add := FormatNumber(emailsent);
                'W':Add := FormatNumber(waiting);
								'X':if (Expiration > 0) then
											Add := cstr((Expiration div 86400) - (GetPackDateTime div 86400))
										else
											Add:='Never';
							end;
					'F':case upcase(s[Index + 2]) of
								'#':Add := cstr(CFBase(FileBoard));
								'B':begin
											loadfileboard(fileboard);
											Add := memuboard.name;
										end;
                'D':Add := todate8(pd2date(firston));
                'K':Add := FormatNumber(diskfree(ExtractDriveNumber(memuboard.ulpath)) div 1024);
								'N':Add := copy(RealName, 1, pos(' ', RealName) - 1);
							end;
					'G':case upcase(s[Index + 2]) of
								'N':if (Sex = 'M') then
											Add := 'Mr.'
										else
											Add:='Ms.';
							end;
					'H':case upcase(s[Index + 2]) of
								'M':Add := cstr(HiMsg);
							end;
          'I':case upcase(s[Index + 2]) of
                'L':Add := cstr(illegal);
							end;
					'K':case upcase(s[Index + 2]) of
                'D':Add := FormatNumber(General.DLKOneday[SL]);
								'R':if (DK > 0) then
                      str((UK / DK):3:3, Add)
										else
											Add := '0';
							end;
					'L':case upcase(s[Index + 2]) of
                'C':Add := todate8(pd2date(LastOn));
								'F':Add := ^M^J;
								'N':begin
											I := length(Realname);
											while ((Realname[i] <> ' ') and (i > 1)) do
												dec(i);
                      Add := copy(Caps(Realname), i + 1, 255);
										end;
								'O':Add := CityState;
							end;
					'M':case upcase(s[Index + 2]) of
								'#':Add := cstr(CMBase(board));
								'B':begin
											i := readboard;
											if (i <> board) then
												loadboard(board);
											Add := memboard.name;
											if (i <> board) then
												loadboard(i);
										end;
								'L':Add := cstr(nsl div 60);
								'O':Add := cstr((GetPackDateTime - TimeOn) div 60);
								'R':Add := cstr(HiMsg - Msg_On);
							end;
					'N':case upcase(s[Index + 2]) of
								'D':Add := cstr(Node);
								'R':if (Downloads > 0) then
                      str((Uploads / Downloads):3:3, Add)
										else
											Add := '0';
							end;
					'O':case upcase(s[Index + 2]) of
								'1':if (RIP in sflags) then
											Add := 'RIP'
										else
											if (Avatar in flags) then
												Add := 'Avatar'
											else
												if (Ansi in flags) then
													Add := 'Ansi'
												else
													if (vt100 in flags) then
														Add := 'VT-100'
													else
														Add := 'None';
								'2':Add := cstr(LineLen) + 'x' + cstr(PageLen);
								'3':Add := OnOff(ClsMsg in Sflags);
								'4':Add := OnOff(FSEditor in Sflags);
								'5':Add := OnOff(Pause in Flags);
								'6':Add := OnOff(HotKey in Flags);
                '7':Add := OnOff(not (Novice in Flags));
                '8':if (Forusr > 0) then
                      Add := 'Forwarded - ' + cstr(Forusr)
                    else
                      if (Nomail in Flags) then
                        Add := 'Closed'
                      else
                        Add := 'Open';
                '9':Add := OnOff(Color in Flags);
							end;
					'P':case upcase(s[Index + 2]) of
								'C':if (LoggedOn > 0) then
											str((msgpost / loggedon) * 100:3:2, Add)
										else
											Add := '0';
								'N':Add := Ph;
								'O':begin
											if (printingfile) or (reading_a_msg) then
												TempPause := FALSE;
											Add := '';
										end;
                'S':Add := FormatNumber(MsgPost);
							end;
					'Q':case upcase(s[Index + 2]) of
								'D': Add := cstr(numbatchfiles);
								'U': Add := cstr(numubatchfiles);
							end;
					'R':case upcase(s[Index + 2]) of
								'N':Add := Caps(RealName);
							end;
					'S':case upcase(s[Index + 2]) of
								'1'..'3':Add := fString.UserDefEd[ord(s[Index + 2]) - 48];
                'C':Add := FormatNumber(General.CallerNum);
								'L':Add := cstr(SL);
								'N':Add := General.SysopName;
								'X':if (Sex = 'M') then
											Add := 'Male'
										else
											Add := 'Female';
							end;
					'T':case upcase(s[Index + 2]) of
                'A':Add := FormatNumber(timebankadd);
                'B':Add := FormatNumber(timebank);
                'C':Add := FormatNumber(LoggedOn);
                'D':Add := FormatNumber(DLToday);
								'I':Add := Time;
                'K':Add := FormatNumber(DLKToday);
								'L':Add := ctim(NSL);
                'O':Add := cstr(general.timeallow[sl] - tltoday);
                'T':Add := FormatNumber(ttimeon);
                'U':Add := cstr(General.NumUsers);
							end;
					'U':case upcase(s[Index + 2]) of
                'A':Add := cstr(Ageuser(Birthdate));
                'B':Add := todate8(pd2date(Birthdate));
								'C':Add := cstr(OnToday);
                'F':Add := FormatNumber(Feedback);
                'K':Add := FormatNumber(UK);
                'L':Add := FormatNumber(Uploads);
								'N':Add := Caps(Name);
								'U':Add := cstr(UserNum);
							end;
					'V':case upcase(s[Index + 2]) of
                'R':Add := Ver;
							end;
					'Z':case upcase(s[Index + 2]) of
								'P':Add := ZipCode;
							end;
				end;
				Temp := Temp + Add;
				inc(Index, 2);
			end
		else
      Temp := Temp + s[index];
	MCI := Temp;
end;

procedure BackErase(Len:byte);
var
	b:byte;
begin
	if (okansi) or (okvt100) then
		SerialOut(^[ + '[' + cstr(Len) + 'D' + ^[ + '[K')
	else if (okavatar) then
		begin
			for b := 1 to len do
				com_tx(^H);
			SerialOut(^V^G);
		end
	else
		for b := 1 to len do
			begin
				com_tx(^H); com_tx(' '); com_tx(^H);
			end;
	gotoxy(WhereX - len, WhereY); clreol;
end;

end.
|09Copyright (C)MM by Jeff Herrings. All Rights Reserved.

