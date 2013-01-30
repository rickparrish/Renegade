const
  Build = 'Y2Ka3';
{$IFDEF MSDOS}
  OS = '';
{$ENDIF}
{$IFDEF WIN32}
  OS = '/32';
{$ENDIF}
{$IFDEF OS2}
  OS = '/2';
{$ENDIF}
  ver = Build + OS;
  MAXPROTOCOLS = 120;
  MAXEVENTS = 10;
  MAXARCS = 8;
  MAXBATCHFILES = 50;
  MAXMENUCMDS = 100;
  MAXRESULTCODES = 20;
  MAXEXTDESC = 9;
  MAXBASES = 2048;
  MAXCONFIGURABLE = 1024;
  SLICETIMER=1; { Used for time slicing }

TYPE
{$IFDEF MSDOS}
  SmallInt = System.Integer;
  SmallWord = System.Word;
{$ENDIF}
  astr = string[160];
  str40 = string[40];
  str8 = string[8];
  str10 = string[10];
  str160 = string[160];
  unixtime = longint;             { Seconds since 1-1-70 }

  ACString=string[20];            { Access Condition String }
  acrq='@'..'Z';                  { Access Restriction flags }

  uflags =
   (rlogon,                       { L - Limited to one call a day }
    rchat,                        { C - No SysOp paging }
    rvalidate,                    { V - Posts are unvalidated }
    ruserlist,                    { U - Can't list users }
    ramsg,                        { A - Can't leave automsg }
    rpostan,                      { * - Can't post anonymously }
    rpost,                        { P - Can't post }
    remail,                       { E - Can't send email }
    rvoting,                      { K - Can't use voting booth }
    rmsg,                         { M - Force email deletion }
    vt100,                        { Supports VT00 }
    hotkey,                       { hotkey input mode }
    avatar,                       { Supports Avatar }
    pause,                        { screen pausing }
    novice,                       { user requires novice help }
    ansi,                         { Supports ANSI }
    color,                        { Supports color }
    alert,                        { Alert SysOp upon login }
    smw,                          { Short message(s) waiting }
    nomail,                       { Mailbox is closed }
    fnodlratio,                   { 1 - No UL/DL ratio }
    fnopostratio,                 { 2 - No post/call ratio }
    fnocredits,                   { 3 - No credits checking }
    fnodeletion);                 { 4 - Protected from deletion }

  suflags =
    (lockedout,                   { if locked out }
    deleted,                      { if deleted }
    trapactivity,                 { if trapping users activity }
    trapseparate,                 { if trap to seperate TRAP file }
    chatauto,                     { if auto chat trapping }
    chatseparate,                 { if separate chat file to trap to }
    slogseparate,                 { if separate SysOp log }
    clsmsg,                       { if clear-screens }
    RIP,                          { if RIP graphics can be used }
    fseditor,                     { if Full Screen Editor }
    AutoDetect                    { Use auto-detected emulation }
  );

  anontyp =
   (atno,                         { Anonymous posts not allowed }
    atyes,                        { Anonymous posts are allowed }
    atforced,                     { Force anonymous }
    atdearabby,                   { "Dear Abby" base }
    atanyname);                   { Post under any name }

  netattr=
    (Private,
     Crash,
     Recd,
     NSent,
     FileAttach,
     Intransit,
     Orphan,
     KillSent,
     Local,
     Hold,
     Unused,
     FileRequest,
     ReturnReceiptRequest,
     IsReturnReceipt,
     AuditRequest,
     FileUpdateRequest);

  NetAttribs = set of netattr;

  secrange = array[0..255] of SmallInt;        { Access tables }

  useridxrec=                         { USERS.IDX : Sorted names listing }
  record
    Name:string[36];                  { the user's name }
    Number,                           { user number          }
    Left,                             { Left node }
    Right:SmallInt;                    { Right node }
    RealName,                         { User's real name?    }
    Deleted:boolean;                  { deleted or not       }
  end;

  userrec=                            { USERS.DAT : User records }
    record
      name,                             { system name        }
      realname:string[36];              { real name          }
      street,                           { street address     }
      citystate:string[30];             { city, state        }
      callerid:string[20];              { caller ID string   }
      zipcode:string[10];               { zipcode            }
      ph:string[12];                    { phone #            }
      pw:longint;                       { password           }
      usrdefstr:array[1..3] of
          string[35];                   { definable strings  }
      Birthdate,                        { Birth date         }
      FirstOn,                          { First On Date      }
      LastOn:unixtime;                  { Last On Date       }
      note:string[35];                  { SysOp note         }
      userstartmenu:string[8];          { menu to start at   }
      lockedfile:string[8];             { print lockout msg  }
      flags:set of uflags;              { flags              }
      sflags:set of suflags;            { status flags       }
      ar:set of acrq;                   { AR flags           }
      vote:array[1..25] of byte;        { voting data        }

      res8:byte;                        { reserved for later }
      sex:char;                         { gender             }
      ttimeon,                          { total time on      }
      uk,                               { UL k               }
      dk,                               { DL k               }
      lastqwk,                          { last qwk packet    }
      credit,                           { Amount of credit   }
      debit,                            { Amount of debit    }
      expiration,                       { Expiration date    }
      passwordchanged:unixtime;         { date pw changed    }

      tltoday,                          { # min left today   }
      forusr:SmallInt;                   { forward mail to    }

      uploads,                          { # of DLs           }
      downloads,                        { # of DLs           }
      loggedon,                         { # times on         }
      msgpost,                          { # message posts    }
      emailsent,                        { # email sent       }
      feedback,                         { # feedback sent    }
      timebank,                         { # mins in bank     }
      timebankadd,                      { # added today      }
      dlktoday,                         { # kbytes dl today  }
      dltoday,                          { # files dl today   }
      timebankwith,                     { Time withdrawn     }
      lastmbase,                        { # last msg base    }
      lastfbase:SmallWord;                   { # last file base   }

      waiting,                          { mail waiting       }
      linelen,                          { line length        }
      pagelen,                          { page length        }
      ontoday,                          { # times on today   }
      illegal,                          { # illegal logons   }
      defarctype,                       { QWK archive type   }
      ColorScheme,                      { Color scheme #     }
      sl,dsl:byte;                      { SL / DSL           }

      Subscription,                     { their subscription }
      expireto,                         { level to expire to }
      lastconf:char;                    { last conference in }

      TeleConfEcho,                     { Teleconf echo?     }
      TeleConfInt,                      { Teleconf interrupt }
      getownqwk,                        { Get own messages   }
      scanfilesqwk,                     { new files in qwk   }
      privateqwk:boolean;               { private mail qwk   }
      UserID:longint;                   { Permanent userid   }
      reserved:array[479..512] of byte;
    end;

  msgstatusr=
    (mdeleted,
     sent,
     unvalidated,
     permanent,
     allowmci,
     netmail,
     prvt,
     junked);

  mhireadrec=
  record
    NewScan:boolean;           { New scan this base? }
    LastRead:longint;          { Last message date read }
  end;

  fromtoinfo=                  { from/to information for mheaderrec }
  record
    anon:byte;
    usernum:SmallWord;              { user number   }
    as:string[36];             { posted as     }
    real:string[36];           { real name     }
    name:string[36];           { system name   }
    zone,
    net,
    node,
    point:SmallWord;
  end;

  mheaderrec=
  record
     from,mto:fromtoinfo;            { message from/to info    }
     pointer:longint;                { starting record of text }
     textsize:SmallWord;                  { size of text            }
     replyto:SmallWord;                   { ORIGINAL + REPLYTO = CURRENT }
     date:unixtime;                  { date/time packed string }
     dayofweek:byte;                 { message day of week     }
     status:set of msgstatusr;       { message status flags    }
     replies:SmallWord;                   { times replied to        }
     subject:string[40];             { subject of message      }
     origindate:string[19];          { date of echo/group msgs }
     fileattached:byte;              { 0=No, 1=Yes&Del, 2=Yes&Save }
     netattribute:NetAttribs;        { Netmail attributes }
     res:array[1..2] of byte;        { reserved }
  end;


  historyrec=                     { HISTORY.DAT : Summary logs }
  record
    date:string[10];
    userbaud:array[0..4] of SmallWord;
    active,callers,newusers,posts,email,feedback,
    errors,uploads,downloads,uk,dk:longint;    {:word;}
                                               {uk,dk:longint;}
  end;

  filearcinforec=                 { Archive configuration records }
  record
    active:boolean;               { active or not  }
    ext:string[3];                { file extension }
    listline,                     { /x for internal;
                                     x: 1=ZIP, 2=ARC/PAK, 3=ZOO, 4=LZH }
    arcline,                      { compression cmdline    }
    unarcline,                    { de-compression cmdline }
    testline,                     { integrity test cmdline }
    cmtline:string[25];           { comment cmdline        }
    succlevel:SmallInt;            { success errorLEVEL, -1=ignore results }
  end;

  fstringrec=                     { STRING.DAT }
  record
    anonymous:string[80];             { "[Anonymous]" string }
    note:array[1..2] of string[80];   { Logon notes (L #1-2) }
    lprompt:string[80];               { Logon prompt (L #3) }
    echoc:char;                       { Echo char for PWs }
    yourpassword,                     { "Your password:" }
    yourphonenumber,                  { "Your phone number:" }
    engage,                           { "Engage Chat" }
    endchat,                          { "End Chat" }
    wait,                             { "SysOp Working" }
    pause,                            { "Pause" }
    entermsg1,                        { "Enter Message" line #1 }
    entermsg2,                        { "Enter Message" line #2 }
    newscan1,                         { "NewScan begin" }
    newscan2,                         { "NewScan done" }
    newuserpassword,                  { "Newuser password:"}
    automsgt:string[80];              { Auto-Message title }
    autom:char;                       { Auto-Message border characters }

    shelldos1,                        { " >> SysOp shelling to DOS ..." }
    readingemail,                     { "Read mail (?=Help) :" }
    chatcall1,                        { "Paging SysOp, please wait..." }
    chatcall2,                        { ">>><*><<<" }
    shuttleprompt,                    { "Enter your user name or number : " }
    namenotfound,                     { "Name NOT found in user list." }
    bulletinline,                     { Bulletin line }
    protocolp,                        { "Protocol (?=List) :" }

    listline,                         { "List files - P to pause" }
    newline,                          { "Search for new files -" }
    searchline,                       { "Search all dirs for file mask" }
    findline1,                        { "Search for descriptions... " }
    findline2,                        { "Enter the string to search for.." }
    downloadline,                     { "Download - " }
    uploadline,                       { "Upload - " }
    viewline,                         { "View interior files - " }
    nofilecredits,                    { "Insufficient file credits." }
    unbalance,                        { "Your UL/DL ratio is unbalanced" }

    ilogon,                           { "Logon incorrect" }
    gfnline1,                         { "[Enter]=All files" }
    gfnline2,                         { "File mask: " }
    batchadd,                         { "File added to batch queue." }
    addbatch,                         { "Batch download flagging - " }
    readq,                            { "Begin reading at [1-54] (Q=Quit): " }
    sysopprompt,                      { "System password: " }
    default,                          { "Press [Enter] to use defaults" }
    newscanall,                       { ")[ Newscan All ](" }
    newscandone,                      { ")[ Newscan Done ](" }
    chatreason:string[80];            { 'Give me a good reason to chat' }
    quote_line:array[1..2] of string[80]; { Quoting so and so to so and so }
    userdefques:array[1..3] of string[80];{ user defined question 1...3}
    userdefed:array[1..3] of string[10];  { user def'd q, user editor strings}
    continue:string[80];              { Continue? }
  end;

  ModemFlags=         { MODEM.DAT status flags }
  (
    lockedport,       { COM port locked at constant rate }
    xonxoff,          { XON/XOFF (software) flow control }
    ctsrts,           { CTS/RTS (hardware) flow control }
    DigiBoard         { This line uses a Digiboard }
  );

linerec=
  record
    InitBaud:longint;                 { initialization baud }
    ComPort:byte;                     { COM port number }
    MFlags:set of ModemFlags;         { status flags }
    Init,                             { init string }
    Answer,                           { answer string or blank }
    Hangup,                           { hangup string }
    Offhook:string[30];               { phone off-hook string }
    DoorPath,                         { door drop files written to }
    TeleConfNormal,
    TeleConfAnon,                     { Teleconferencing strings }
    TeleConfGlobal,
    TeleConfPrivate:string[40];
    OK,
    RING,
    RELIABLE,
    CALLERID,
    NOCARRIER:string[20];
    CONNECT:array [1..22] of string[20];
    { 300, 600, 1200, 2400, 4800, 7200, 9600, 12000, 14400, 16800, 19200,
      21600, 24000, 26400, 28800, 31200, 33600, 38400, 57600, 115200 + 2 extra }
    UseCallerID:boolean;              { Insert Caller ID into sysop note? }
    LogonACS:ACString;                { ACS string to logon this node }
    IRQ,
    Address:string[10];               { used only for functional MCI codes
                                        %C = Comport address
                                        %E = IRQ
                                      }
    AnswerOnRing:byte;                { Answer after how many rings? }
    MultiRing:boolean;                { Answer Ringmaster or some other type
                                        of multiple-ring system ONLY }
  end;

  validationrec = record
    description:string[25];           { description }
    newsl,                            { new SL }
    newdsl:byte;                      { new DSL }
    newar:set of acrq;                { new AR }
    newac:set of uflags;              { new AC }
    newfp:SmallInt;                    { nothing }
    newcredit:longint;                { new credit (added) }
    expiration:SmallWord;                  { days until expiration }
    expireto:char;                    { validation level to expire to }
    softar:boolean;                   { TRUE=AR added to current, else replaces }
    softac:boolean;                   { TRUE=AC    "   "   "       "      "  }
    newmenu:string[8];                { User start out menu }
  end;

generalrec=
  record
    datapath:string[40];              { DATA path }
    miscpath:string[40];              { MISC path }
    menupath:string[40];              { MENU path }
    logspath:string[40];              { LOGS path }
    msgpath:string[40];               { MSGS path }
    nodepath:string[40];              { NODE list path }
    temppath:string[40];              { TEMP path }
    protpath:string[40];              { PROT path }
    arcspath:string[40];              { ARCS path }

    bbsname:string[40];               { BBS name }
    bbsphone:string[12];              { BBS phone number }
    sysopname:string[30];             { SysOp's name }

    lowtime,                          { SysOp begin minute (in minutes) }
    hitime,                           { SysOp end time }
    dllowtime,                        { normal downloading hours begin.. }
    dlhitime,                         { ..and end }
    minbaudlowtime,                   { minimum baud calling hours begin.. }
    minbaudhitime,                    { ..and end }
    minbauddllowtime,                 { minimum baud downloading hours begin.. }
    minbauddlhitime:SmallInt;          { ..and end }

    minimumbaud,                      { minimum baud rate to logon }
    minimumdlbaud:longint;            { minimum baud rate to download }

    shuttlelog,                       { Use Shuttle Logon? }
    closedsystem,                     { Allow new users? }
    swapshell:boolean;                { Swap on shell? }

    sysoppw,                          { SysOp password }
    newuserpw,                        { newuser password }
    minbaudoverride,                  { override minimum baud rate }
    qwknetworkACS:ACString;           { QWK network REP ACS }

    crapola2:string[8];               { }

    sop,                              { SysOp }
    csop,                             { Co-SysOp }
    msop,                             { Message SysOp }
    fsop,                             { File SysOp }
    spw,                              { SysOp PW at logon }
    addchoice,                        { Add voting choices acs }
    normpubpost,                      { make normal public posts }
    normprivpost,                     { send normal e-mail }
    anonpubread,                      { see who posted public anon }
    anonprivread,                     { see who sent anon e-mail }
    anonpubpost,                      { make anon posts }
    anonprivpost,                     { send anon e-mail }
    seeunval,                         { see unvalidated files }
    dlunval,                          { DL unvalidated files }
    nodlratio,                        { no UL/DL ratio }
    nopostratio,                      { no post/call ratio }
    nofilecredits,                    { no file credits checking }
    ulvalreq,                         { uploads require validation }
    TeleConfMCI,                      { ACS access for MCI codes while teleconfin' }
    overridechat:ACString;            { override chat hours }

    maxprivpost,                      { max email can send per call }
    maxfback,                         { max feedback per call }
    maxpubpost,                       { max posts per call }
    maxchat,                          { max sysop pages per call }
    maxwaiting,                       { max mail waiting }
    csmaxwaiting,                     { max mail waiting for Co-SysOp + }
    junk1,                            { ------------------------------- }
    junk2,                            { ------------------------------- }
    maxlogontries,                    { tries allowed for PW's at logon }
    sysopcolor,                       { SysOp color in chat mode }
    usercolor:byte;                   { user color in chat mode }
    minspaceforpost,                  { minimum drive space left to post }
    minspaceforupload:SmallInt;        { minimum drive space left to upload }

    backsysoplogs,                    { days to keep SYSOP##.LOG }
    eventwarningtime,                 { minutes before event to warn user }
    wfcblanktime:byte;                { minutes before blanking WFC menu }

    allowalias,                       { allow handles? }
    phonepw,                          { phone number password in logon? }
    localsec,                         { use local security? }
    globaltrap,                       { trap everyone's activity? }
    autochatopen,                     { automatically open chat buffer? }
    autominlogon,                     { Auto-Message at logon? }
    bullinlogon,                      { bulletins at logon? }
    lcallinlogon,                     { "Last Few Callers" list at logon? }
    yourinfoinlogon,                  { "Your Info" at logon? }
    offhooklocallogon,                { phone off-hook for local logons? }
    forcevoting,                      { manditory voting? }
    compressbases,                    { "compress" file/msg base numbers? }
    searchdup:boolean;                { search for dupes files when UL? }
    slogtype:byte;                    { log type: File/Printer/Both }
    stripclog:boolean;                { strip colors from SysOp log? }
    newapp,                           { send new user application to # }
    timeoutbell,                      { minutes before timeout beep }
    timeout:SmallInt;                  { minutes before timeout }
    useems:boolean;                   { use EMS for overlay }
    usebios:boolean;                  { use BIOS for video output }
    useIEMSI:boolean;                 { use IEMSI }
    alertbeep:SmallInt;                { time between alert beeps }

    filearcinfo:
        array[1..maxarcs] of filearcinforec;           { archive specs }
    filearccomment:
        array[1..3] of string[40];    { BBS comment files for archives }
    uldlratio,                        { use UL/DL ratios? }
    filecreditratio:boolean;          { use auto file-credit compensation? }
    filecreditcomp,                   { file credit compensation ratio }
    filecreditcompbasesize,           { file credit base compensation size }
    ulrefund,                         { percent of time to refund on ULs }
    tosysopdir:byte;                  { SysOp file base }
    validateallfiles:boolean;         { validate files automatically? }
    maxintemp,                        { max K allowed in TEMP }
    minresume:SmallInt;                { min K to allow resume-later }

    filediz:boolean;                  { Search/Import file_id.diz }

    maxqwktotal,                      { max msgs in a packet, period }
    maxqwkbase:SmallWord;                  { max msgs in a base }

    CreditMinute,                     { Credits per minute }
    CreditPost,                       { Credits per post }
    CreditEmail:SmallInt;              { Credits per Email sent }

    sysoppword:boolean;               { check for sysop password? }

    CreditFreeTime:SmallInt;           { Amount of "Free" time given to user at logon }

    TrapTeleConf:boolean;             { Trap teleconferencing to ROOMx.TRP? }

    RES98:array[1..6] of byte;

    allstartmenu:string[8];           { logon menu to start users on }
    bulletprefix:string[8];           { default bulletins filename }

    timeallow,                        { time allowance }
    callallow,                        { call allowance }
    dlratio,                          { # ULs/# DLs ratios }
    dlkratio,                         { DLk/ULk ratios }
    postratio,                        { posts per call ratio }
    dloneday,                         { Max number of dload files in one day}
    dlkoneday:secrange;               { Max k downloaded in one day}

    lastdate:string[10];               { last system date }
    curwindow:byte;                   { type of SysOp window in use }
    istopwindow:boolean;              { is window at top of screen? }
    callernum:longint;                { system caller number }
    numusers:SmallInt;                 { number of users }

    multpath:string[40];              { MULT path }

    junkola:array[1..3] of byte;     { -= NOT USED =- }

    recompress:boolean;               { recompress like archives? }

    rewardsystem:boolean;             { use file rewarding system? }

    passwordchange:SmallWord;              { change password at least every x days }

    netmailpath:string[40];           { path to netmail }
    netmailACS:ACString;              { do they have access to netmail? }

    rewardratio:SmallInt;              { % of file points to reward back }

    birthdatecheck:byte;              { check user's birthdate every xx logons }

    Invisible:ACString;                 { Invisible mode? }

    fileattachpath:string[40];        { directory for file attaches }

    fileattachACS:ACString;           { ACS to attach files to messages }
    changevote:ACString;              { ACS to change their vote }

    trapgroup:boolean;                { record group chats? }

    qwktimeignore:boolean;            { ignore time remaining for qwk download? }

    networkmode:boolean;              { Network mode ? }

    SwapTo:byte;                      { Swap where?    }

    res:array[1..23] of byte;         { bleah }

    windowon:boolean;                 { is the sysop window on? }
    regnumber:longint;                { registration number }

    chatcall:boolean;                 { Whether system keeps beeping after chat}

    packetname:string[8];             { QWK packet name }
    qwkwelcome:string[50];            { QWK welcome file name }
    qwknews:string[50];               { QWK news file name }
    qwkgoodbye:string[50];            { QWK goodbye file name }
    qwklocalpath:string[40];          { QWK path for local usage }

    dailylimits:boolean;              { Daily file limits on/off }
    multinode:boolean;                { enable multinode support }
    daysonline:SmallWord;                  { days online }
    totalcalls:longint;               { incase different from callernum }
    totalusage:longint;               { total usage in minutes }
    totalposts:longint;               { total number of posts }
    totaldloads:longint;              { total number of dloads }
    totaluloads:longint;              { total number of uloads }

    percall:boolean;                  { time limits are per call or per day?}
    testuploads:boolean;              { perform integrity tests on uploads? }
    Origin:string[50];                { Default Origin line }
    Text_Color,                       { color of standard text }
    Quote_Color,                      { color of quoted text }
    Tear_Color,                       { color of tear line }
    Origin_Color:byte;                { color of origin line }
    SKludge,                          { show kludge lines? }
    SSeenby,                          { show SEEN-BY lines? }
    SOrigin,                          { show origin line? }
    AddTear:boolean;                  { show tear line? }
    Netattribute:NetAttribs;          { default netmail attribute }
    Aka:array[0..20] of record        { 20 Addresses }
      zone,                           { 21st is for UUCP address }
      net,
      node,
      point:SmallWord;
    end;
    DefEchoPath:string[40];           { default echomail path }
    CreditInternetMail:SmallInt;       { cost for Internet mail }
    crap5:array[1..372] of byte;
    validation:array['A'..'Z'] of
               validationrec;         { Validation records A - Z }

    macro:array[0..9] of string[100]; { sysop macros }
  end;

  smr=                            { SHORTMSG.DAT : One-line messages }
  record
    msg:astr;
    destin:SmallInt;
  end;

  votingr=                        { VOTING.DAT : Voting records }
  record
    description:string[65];       { voting question }
    ACS:ACString;                 { ACS required to vote on this }
    choicenumber:SmallWord;            { number of choices }
    numvoted:SmallWord;                { number of votes on it }
    madeby:string[35];            { who created it }
    addchoicesACS:ACString;       { ACS required to add choices }
    choices:array[1..25] of
    record
      description:string[65];     { answer description }
      description2:string[65];    { answer description #2 }
      numvoted:SmallInt;           { # user's who picked this answer }
    end;
  end;

  mbflags=
   (mbunhidden,                   { whether *VISIBLE* to users w/o access }
    mbrealname,                   { whether real names are forced }
    mbcrap,                       { }
    mbinternet,                   { if internet message base }
    mbfilter,                     { whether to filter ANSI/8-bit ASCII }
    mbskludge,                    { strip IFNA kludge lines }
    mbsseenby,                    { strip SEEN-BY lines }
    mbsorigin,                    { strip origin lines }
    mbprivate,                    { allow private messages }
    mbforceread,                  { force the reading of this base }
    mbScanOut,                    { Needs to be scanned out by renemail }
    mbaddtear,                    { add tear/origin lines }
    mbcrap2);                     { }

  boardrec=                       { MBASES.DAT : Message base records }
  record
    name:string[40];              { message base description }
    filename:string[8];           { HDR/DAT data filename }
    msgpath:string[40];           { messages pathname   }
    ACS,                          { access requirement }
    postACS,                      { post access requirement }
    mciACS,                       { MCI usage requirement }
    sysopACS:ACString;            { Message base sysop requirement }
    maxmsgs:SmallWord;                 { max message count }
    anonymous:anontyp;            { anonymous type }
    password:string[20];          { base password }
    mbstat:set of mbflags;        { message base status vars }
    mbtype:SmallInt;               { base type (0=Local,1=Echo, 3=Qwk) }
    origin:string[50];            { origin line }
    text_color,                   { color of standard text }
    quote_color,                  { color of quoted text }
    tear_color,                   { color of tear line }
    origin_color:byte;            { color of origin line }
    aka:byte;                     { alternate address }
    QWKIndex:SmallWord;                { QWK indexing number }
    res:array[1..11] of byte;      { RESERVED }
  end;

  fbflags=
   (fbnoratio,                    { if <No Ratio> active }
    fbunhidden,                   { whether *VISIBLE* to users w/o access }
    fbdirdlpath,                  { if *.DIR file stored in DLPATH }
    fbshowname,                   { show uploaders in listings }
    fbusegifspecs,                { whether to use GifSpecs }
    fbcdrom,                      { base is read only, no sorting or ul scanning }
    fbshowdate,                   { show date uploaded in listings }
    fbnodupecheck);               { No dupe check on this area }

  ulrec=                          { FBASES.DAT  : File base records }
  record
    name:string[40];              { area description  }
    filename:string[12];          { filename + ".DIR" }
    dlpath,                       { download path     }
    ulpath:string[40];            { upload path       }
    maxfiles:SmallWord;                { max files allowed }
    password:string[20];          { password required }
    arctype,                      { wanted archive type (1..max,0=inactive) }
    cmttype:byte;                 { wanted comment type (1..3,0=inactive) }
    res1:SmallInt;                 { not used }
    fbstat:set of fbflags;        { file base status vars }
    ACS,                          { access requirements }
    ulACS,                        { upload requirements }
    dlACS:ACString;               { download requirements }
    res:array[1..10] of byte;     { RESERVED }
  end;

  filstat=
   (notval,                       { if file is NOT validated }
    isrequest,                    { if file is REQUEST }
    resumelater,                  { if file is RESUME-LATER }
    hatched);                     { has file been hatched? }

  ulfrec=                         { *.DIR : File records }
  record
    filename:string[12];          { Filename }
    description:string[60];       { File description }
    credits:SmallInt;              { File points }
    downloaded:SmallWord;              { Number DLs }
    sizemod:byte;                 { # chars over last 128 byte block }
    blocks:SmallWord;                  { # 128 byte blks }
    owner:SmallWord;                   { ULer of file }
    stowner:string[36];           { ULer's name }
    date:string[10];              { Date ULed }
    daten:SmallWord;                   { Numeric date ULed }
    vpointer:longint;             { Pointer to verbose descr, -1 if none }
    filestat:set of filstat;      { File status }
    res:array[1..10] of byte;     { RESERVED }
  end;

  verbrec=                        { EXTENDED.DAT: Extendeddescriptions }
  record
    descr:array[1..9] of string[50];
  end;

  LastCallerRec =                  { LASTON.DAT : Last few callers records }
  record
    Node:byte;                     { Node number }
    UserName:string[36];           { User name of caller }
    Location:string[30];           { Location of caller }
    Caller,                        { system caller number }
    UserID,                        { User ID # }
    Speed:longint;                 { Speed of caller 0=Local }
    LogonTime,                     { time user logged on }
    LogoffTime:unixtime;           { time user logged off }
    NewUser,                       { was it a new user? }
    Invisible:boolean;             { Invisible user? }
    Uploads,                       { Uploads/Downloads during call }
    Downloads,
    MsgRead,                       { Messages Read }
    MsgPost,                       { Messages Posted }
    EmailSent,                     { Email sent }
    FeedbackSent:SmallWord;             { Feedback sent }
    UK,                            { Upload/Download kbytes during call }
    DK:longint;
    Reserved:array [1..17] of byte; { Reserved }
  end;

  eventrec=                       { EVENTS.DAT : Event records }
  record
    active:boolean;               { whether active }
    description:string[30];       { event description }
    etype:char;                   { ACS,Chat,Dos,External,Pack Msgs,Sort Files }
    execdata:string[20];          { errorlevel if "E", commandline if "D" }
    softevent,                    { event runs whenever "convenient" }
    missed,                       { run even even if missed }
    monthly,                      { monthly event? }
    busyduring:boolean;           { busy phone DURING event? }
    exectime,                     { time of execution }
    durationorlastday:SmallInt;    { length of time event takes }
    offhooktime,                  { off-hook time before; 0 if none }
    Enode,                        { node number to execute on (0 = all) }
    execdays:byte;                { bitwise execution days or day of month if monthly }
  end;

  xbflags=
   (xbactive,
    xbisbatch,
    xbisresume,
    xbxferokcode,
    xbbidirectional,
    xbreliable);

  protrec=                          { PROTOCOL.DAT records }
  record
    xbstat:set of xbflags;                       { protocol flags }
    ckeys:string[14];                            { command keys }
    descr:string[40];                            { description }
    ACS:ACString;                                { access string }
    templog:string[25];                          { temp. log file }
    uloadlog,dloadlog:string[25];                { permanent log files }
    ulcmd,dlcmd:string[78];                      { UL/DL commandlines }
    ulcode,dlcode:array [1..6] of string[6];     { UL/DL codes }
    envcmd:string[60];                           { environment setup cmd }
    dlflist:string[25];                          { DL file lists }
    maxchrs:SmallInt;                             { max chrs in cmdline }
    logpf,logps:SmallInt;                         { pos in log file for data }
    res:array[1..15] of byte;                    { RESERVED }
  end;

  confrec=            { CONFRENC.DAT : Conference data }
  record
    conference:array['@'..'Z'] of
    record
      ACS:ACString;       { access requirement }
      name:string[40];    { name of conference }
    end;
  end;

  nodeflags=
    (NActive,                 { Is this node active?               }
     NAvail,                  { Is this node's user available?     }
     NUpdate,                 { This node should re-read it's user }
     NHangup,                 { Hangup on this node                }
     NRecycle,                { Recycle this node to the OS        }
     NInvisible);             { This node is Invisible             }

  noderec=                         { MULTNODE.DAT }
    record
      User:SmallWord;                                 { What user number     }
      UserName:string[36];                       { User's name }
      CityState:string[30];                      { User's location }
      Sex:char;                                  { User's sex }
      Age:byte;                                  { User's age }
      LogonTime:unixtime;                        { What time they logged on }
      Activity:byte;                             { What are they doing? }
      Description:string[20];                    { Optional string }
      Status:set of nodeflags;
      Room:byte;                                 { What room are they in?      }
      Channel:SmallWord;                              { What channel are they in?   }
      Invited:array[0..31] of set of 0..7;       { Have they been invited ?    }
      Booted:array[0..31] of set of 0..7;        { Have they been kicked off ? }
      Forget:array[0..31] of set of 0..7;        { Who are they forgetting?    }
    end;

  RoomRec=                         { ROOM.DAT }
    record
      Topic:string[40];            { Topic of this room          }
      Anonymous:boolean;           { Is Room anonymous ?         }
      Private:boolean;             { Is Room private ?           }
      Occupied:boolean;            { Is anyone in here?          }
      Moderator:SmallWord;              { Who's the moderator?        }
    end;

  scanrec=                         { *.SCN files }
    record
      NewScan:boolean;             { Scan this base? }
      LastRead:unixtime;           { Last date read  }
    end;

  SchemeRec=                       { Scheme.dat }
    record
      Description:string[30];       { Description of the color scheme }
      Color:array[1..200] of byte;  { Colors in scheme }
    end;

  { 1 - 10 system colors
    11 -   file list colors
    28 -   msg list colors
    45 -   file area list colors
    55 -   msg area list colors
    65 -   user list colors
    80 -   who's online colors
    100-   last on colors
    115-   qwk colors
    135-   email colors
   }

  BBSListRec=                        { *.BBS file records }
    record
      PhoneNumber:string[20];        { Phone number of BBS }
      BBSName,                       { Name of BBS }
      SysOpName:string[30];          { SysOp of BBS }
      Description:string[60];        { Description of BBS }
      Software,                      { Software used by BBS }
      Speed:string[8];               { Highest connect speed of BBS }
      DateAdded,                     { Date entry was added }
      DateEdited:unixtime;           { Date entry was last edited }
      UserID,                        { User ID of person adding this }
      Next:longint;                  { Next Record # }
      Reserved:array[1..78] of byte; { Reserved }
    end;

