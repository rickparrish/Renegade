{ ************************************************************************ }
{ The Mystic Bulletin Board System            Turbo Pascal File Structures }
{ Copyright (C) 1997-99 By James Coyle                 All Rights Reserved }
{ ************************************************************************ }

Type
  SmallInt   = System.Integer;
  SmallWord  = System.Word;

Const
  SoftID    = 'Mystic';          { Software name         }
  Version   = '1.06';            { Software version      }

{$IFDEF MSDOS}
  OSID     = 'DOS';
{$ENDIF}
{$IFDEF WIN32}
  OSID     = 'WIN';
{$ENDIF}
{$IFDEF OS2}
  OSID     = 'OS2';
{$ENDIF}
{$IFDEF LINUX}
  OSID     = 'LNX';
{$ENDIF}

  Max_Menu_Cmds  = 50;            { Maximum menu commands per menu      }
  Max_Vote       = 20;            { Max number of voting questions      }
  MaxBatch       = 99;            { Maxinum # of batch queue entires    }
  Total_Lang_Str = 426;           { Total # of strings in language file }

Type
  AddrType = Record               { FidoNet-style network address    }
    Zone,
    Net,
    Node,
    Point : SmallWord;
  End;

(* MYSTIC.DAT is found in the root Mystic BBS directory, and contains *)
(* most of the general configuration options. *)

  ConfigRec = Record                  { MYSTIC.DAT in root BBS directory   }
    SysPath,                          { System path (root BBS directory)   }
    AttachPath,                       { File attach directory              }
    DataPath,                         { Data file directory                }
    MsgsPath,                         { Default JAM directory              }
    ProtPath,                         { Protocol path                      }
    ArcsPath,                         { Archive software directory         }
    QwkPath,                          { Local QWK directory                }
    ScriptPath,                       { Script file directory              }
    LogsPath  : String[40];           { Log file directory                 }

    BBSName,                          { BBS Name                           }
    SysopName    : String[30];        { Sysop Name                         }
    SysopPW      : String[15];        { Sysop Password                     }
    SystemPW     : String[15];        { System Password                    }
    MaxNode      : Byte;              { Max # of nodes the BBS has         }
    dStartMNU    : String[8];         { Default start menu                 }
    dFallMNU     : String[8];         { Default fallback menu              }
    dLangFile    : String[8];         { Default language file              }
    TermMode     : Byte;              { 0 Ask, 1 Detect, 2 Detect/Ask      }
    ScreenBlank  : Byte;              { Mins before WFC screen saver starts}
    Reserved1    : Byte;
    ChatStart    : SmallInt;          { Chat hour start,                   }
    ChatEnd      : SmallInt;          { Chat hour end: mins since midnight }
    ChatFeedback : Boolean;           { E-mail sysop if page isn't answered}
    BBSListACS   : String[20];        { BBS List Editor ACS              }

    AllowNewUser  : Boolean;          { Allow new users?                   }
    NewUserPW     : String[15];       { New user password                  }
    NewSec        : SmallInt;         { New user security level            }
    AskRealName,                      { Ask new users for real name?       }
    AskAlias,                         { Ask new users for an alias?        }
    AskStreet,                        { Ask new user for street address?   }
    AskCityState,                     { Ask new users for city/state?      }
    AskZipCode,                       { Ask new users for ZIP code         }
    AskHomePhone,                     { Ask new users for home phone #?    }
    AskDataPhone,                     { Ask new users for data phone #?    }
    AskBirthdate,                     { Ask new users for date of birth?   }
    AskGender,                        { Ask new users for their gender?    }
    AskLanguage,                      { Ask new users to select a language?}
    UseUSA        : Boolean;          { Use XXX-XXX-XXXX format phone #s?  }
    EditType      : Byte;             { 0 = Line Editor }
                                      { 1 = Full Editor }
                                      { 2 = Ask         }
    DateType      : Byte;             { 1 = MM/DD/YY }
                                      { 2 = DD/MM/YY }
                                      { 3 = YY/DD/MM }
                                      { 4 = Ask      }
    UseMatrix     : Boolean;          { Use MATRIX-style login? }
    MatrixMenu    : String[8];        { Matrix Menu Name }
    MatrixPW      : String[15];       { Matrix Password }
    SeeMatrixPW   : String[20];       { ACS required to see Matrix PW }
    Feedback      : Boolean;          { Force new user feedback }

    FCompress     : Boolean;          { Compress file area numbers?      }
    ImportDIZ     : Boolean;          { Search for FILE_ID.DIZ?            }
    AutoValACS    : String[20];       { ACS to auto-validate uploads       }
    SeeUnvalid    : String[20];       { ACS to see unvalidated files       }
    DLUnvalid     : String[20];       { ACS to download unvalidated files  }
    SeeFailed     : String[20];       { ACS to see failed files            }
    DLFailed      : String[20];       { ACS to download failed files       }
    TestUploads   : Boolean;          { Test uploaded files?          }
    PassLevel     : Byte;             { Pass errorlevel               }
    TestCmdLine   : String[60];       { Upload processor command line }
    MaxFileDesc   : Byte;             { Max # of File Description Lines  }
    FreeUL        : LongInt;          { Max space required for uploads }
    FreeCDROM     : LongInt;          { Free space required for CD Copy }

    MCompress      : Boolean;          { Compress message area numbers?   }
    QWK_BBSID      : String[8];        { QWK packet display name  }
    QWK_Welcome    : String[8];        { QWK welcome display file }
    QWK_News       : String[8];        { QWK news display file    }
    QWK_Goodbye    : String[8];        { QWK goodbye display file }
    QWK_Archive    : String[3];        { Default QWK archive      }
    QWK_MaxBase    : SmallInt;          { Max # of messages per base (QWK) }
    QWK_MaxPacket  : SmallInt;          { Max # of messages per packet     }
    NetAddr        : Array[1..20] of AddrType;    { Network Addresses   }
    Origin         : String[50];                  { Default origin line }
    MsgColorQuote  : Byte;            { Default quote color       }
    MsgColorText   : Byte;            { Default text color        }
    MsgColorTear   : Byte;            { Default tear line color   }
    MsgColorOrigin : Byte;            { Default origin line color }

    SystemCalls    : LongInt;         { Total calls to the BBS }

    iLoginACS      : String[20];      { Invisible login ACS }

    SysChatLOG     : Boolean;         { Record SysOp chat to CHAT.LOG? }
    StatusType     : Byte;            { 0 = 2 line, 1 = 1 line }
    fListType      : Byte;            { 0 = Normal, 1 = Lightbar, 2 = Ask }
    dispFileHdr    : Boolean;         { Redisplay file header after pause }
    sMacro         : Array[1..4] of String[80];  { Sysop Macros }
    UploadBase     : SmallInt;         { Default upload file base }
    AutoSigLen     : Byte;            { Max Auto-Sig lines }
    FListCol       : Byte;            { File area list columns }
    MListCol       : Byte;            { Message area list columns }
    netCrash       : Boolean;         { NetMail CRASH flag?    }
    netHold        : Boolean;         { NetMail HOLD flag?     }
    netKillSent    : Boolean;         { NetMail KILLSENT flag? }
    UserNameFMT    : Byte;            { user input format }
    DispMsgHdr     : Boolean;         { redisplay message header  }
    DefScreenSize  : Byte;            { default screen length     }
    DupeScan       : Byte;            { dupescan: 0=no,1=yes,2=yes global }
    TimeOut        : Word;            { Seconds before inactivity timeout }
    MReadType      : Byte;            { 0 = normal, 1 = ansi, 2 = ask }
    HotKeys        : Byte;            { 0 = no, 1 = yes, 2 = ask }
    PermPos        : LongInt;         { permanent user # position }
    SeeInvisible   : String[20];      { ACS to see invisible users }
    FeedbackTo     : String[30];      { Feedback to user }
    AllowMulti     : Boolean;         { Allow multiple node logins? }
    Reserved       : Array[1..2] of Byte;
  End;

  UserFlags = (
    LockedOut,
    NoRatio,
    UserDEL,
    NoKill
  );

  UserRec = Record                     { USERS.DAT }
    Flags     : Set of UserFlags;      { Set of User Flags            }
    Handle,                            { Handle                       }
    RealName  : String[30];            { Real Name                    }
    Password  : String[15];            { Password                     }
    Address   : String[30];            { Address                      }
    City      : String[25];            { City                         }
    ZipCode   : String[9];             { Zipcode                      }
    HomePhone : String[15];            { Home Phone                   }
    DataPhone : String[15];            { Data Phone                   }

    BDay      : LongInt;
    Gender    : Char;                  { M> Male  F> Female           }
    Security  : Integer;               { Security Level               }
    AF        : Set of 'A'..'Z';       { User's access flags A-Z      }
    StartMNU  : String[8];             { Start menu for user          }
    FirstOn   : LongInt;               { Date/Time of First Call      }
    LastOn    : LongInt;               { Date/Time of Last Call       }
    Calls     : LongInt;               { Number of calls to BBS       }
    CallsToday: Integer;               { Number of calls today        }
    DLs       : Integer;               { # of downloads               }
    DLsToday  : Integer;               { # of downloads today         }
    DLk       : LongInt;               { # of downloads in K          }
    DLkToday  : LongInt;               { # of downloaded K today      }
    ULs       : LongInt;               { total number of uploads      }
    ULk       : LongInt;               { total number of uploaded K   }
    Posts     : LongInt;               { total number of msg posts    }
    Emails    : LongInt;               { total number of sent email   }
    TimeLeft  : LongInt;               { time left online for today   }
    TimeBank  : Integer;               { number of mins in timebank   }
    Qwk_Arc   : String[3];             { default archive extension    }
    Qwk_List  : Boolean;               { Include new files in QWK?    }
    DateType  : Byte;                  { Date format (see above)      }
    ScrnPause : Byte;                  { user's screen length         }
    Language  : String[8];             { user's language file         }
    LastFBase : Word;                  { Last file base               }
    LastMBase : Word;                  { Last message base            }
    LastMGroup: Word;                  { Last group accessed          }
    LastFGroup: Word;                  { Last file group accessed     }
    Vote      : Array[1..Max_Vote] of Byte;  { Voting booth data      }
    EditType  : Byte;                  { 0 = Line, 1 = Full, 2 = Ask  }
    fListType : Byte;                  { 0 = Normal, 1 = Lightbar     }
    SigUse    : Boolean;               { Use auto-signature?          }
    SigOffset : LongInt;               { offset to sig in AUTOSIG.DAT }
    SigLength : Byte;                  { number of lines in sig       }
    HotKeys   : Boolean;               { does user have hotkeys on?   }
    MReadType : Byte;                  { 0 = line 1 = full 2 = ask    }
    PermIdx   : LongInt;               { permanent user number        }
    Reserved  : Array[1..86] of Byte;  { RESERVED }
  End;

  NodeRec = Record                     { NODEx.DAT }
    Port  : Byte;                      { Modem comport                   }
    Baud  : LongInt;                   { Modem baud rate                 }
    Telnet: Boolean;                   { Is a TELNET node?               }
    RTSFlow,                           { Use RTS/CTS Hardware flow?      }
    XONFlow : Boolean;                 { Use XON/XOFF Software flow?     }
    Init,                              { Modem initialization command    }
    Hangup: String[40];                { Modem hangup command            }
    Offhook,                           { Modem offhook command           }
    rOK,                               { Modem result "OK"               }
    rRING,                             { Modem result "RING"             }
    rATA  : String[20];                { Modem answer call command       }
    rBaud : Array[1..18] of Record     { Modem results                   }
              Rate   : LongInt;        { BAUD RATE                       }
              Result : String[20];     { "CONNECT" string for above baud }
            End;
  End;

  EventRec = Record                    { EVENTS.DAT                        }
    Active    : Boolean;               { Is event active?                  }
    Name      : String[30];            { Event Name                        }
    Forced    : Boolean;               { Is this a forced event            }
    ErrLevel  : Byte;                  { Errorlevel to Exit                }
    ExecTime  : Integer;               { Minutes after midnight            }
    Warning   : Byte;                  { Warn user before the event        }
    Offhook   : Boolean;               { Offhook modem for event?          }
    Node      : Byte;                  { Node number.  0 = all             }
    LastRan   : LongInt;               { Last time event was ran           }
  End;

(* SECURITY.DAT in the data directory holds 255 records, one for each *)
(* possible security level. *)

  SecurityRec = Record                 { SECURITY.DAT                     }
    Desc     : String[30];             { Description of security level    }
    Time     : Integer;                { Time online (mins) per day       }
    MaxCalls : Integer;                { Max calls per day                }
    MaxDLs   : Integer;                { Max downloads per day            }
    MaxDLk   : Integer;                { Max download kilobytes per day   }
    MaxTB    : Integer;                { Max mins allowed in time bank    }
    DLRatio  : Byte;                   { Download ratio (# of DLs per UL) }
    DLKRatio : Integer;                { DL K ratio (# of DLed K per UL K }
    AF       : Set of 'A'..'Z';        { Access flags for this level A-Z  }
    Hard     : Boolean;                { Do a hard AF upgrade?            }
    StartMNU : String[8];              { Start Menu for this level        }
    PCRatio  : Integer;                { Post / Call ratio per 100 calls  }
    Res1     : Byte;                   { reserved for future use }
    Res2     : LongInt;                { reserved for future use }
  End;

  ArcRec = Record                      { ARCHIVE.DAT                      }
    Name   : String[20];               { Archive description              }
    Ext    : String[3];                { Archive extension                }
    Pack   : String[60];               { Pack command line                }
    Unpack : String[60];               { Unpack command line              }
    View   : String[60];               { View command line                }
  End;

  ProtRec = Record                     { PROTOCOL.DAT                     }
    Key    : Char;                     { Hot key                          }
    Desc   : String[25];               { Protocol Description             }
    Batch  : Boolean;                  { Is this a batch protocol?        }
    ULCmd,                             { Upload command line              }
    DLCmd  : String[60];               { Download command line            }
  End;

  MScanRec = Record                    { <Message Base Path> *.SCN       }
    NewScan : Byte;                    { Include this base in new scan?  }
    QwkScan : Byte;                    { Include this base in qwk scan?  }
  End;

  MBaseRec = Record                    { MBASES.DAT                       }
    Name     : String[40];             { Message base name                }
    QWKName  : String[13];             { QWK (short) message base name    }
    FileName : String[8];              { Message base file name           }
    Path     : String[40];             { Path where files are stored      }
    BaseType : Byte;                   { 0 = JAM    1 = SQUISH            }
    NetType  : Byte;                   { 0 = Local  1 = EchoMail          }
                                       { 2 = UseNet 3 = NetMail           }
    PostType : Byte;                   { 0 = Public 1 = Private           }
    ACS,                               { ACS required to see this base    }
    ReadACS,                           { ACS required to read messages    }
    PostACS,                           { ACS required to post messages    }
    SysopACS : String[20];             { ACS required for sysop options   }
    Password : String[15];             { Password for this message base   }
    ColQuote : Byte;                   { Quote text color                 }
    ColText  : Byte;                   { Text color                       }
    ColTear  : Byte;                   { Tear line color                  }
    ColOrigin: Byte;                   { Origin line color                }
    NetAddr  : Byte;                   { Net AKA to use for this base     }
    Origin   : String[50];             { Net origin line for this base    }
    UseReal  : Boolean;                { Use real names?                  }
    DefNScan : Byte;                   { 0 = off, 1 = on, 2 = always      }
    DefQScan : Byte;                   { 0 = off, 1 = on, 2 = always      }
    MaxMsgs  : Word;                   { Max messages to allow            }
    MaxAge   : Word;                   { Max age of messages before purge }
    Header   : String[8];              { Display Header file name         }
    Index    : Integer;                { QWK index - NEVER CHANGE THIS    }
  End;

  FScanRec = Record                    { <Data Path> *.SCN               }
    NewScan : Byte;                    { Include this base in new scan?  }
    LastNew : LongInt;                 { Last file scan (packed datetime)}
  End;

  FBaseRec = Record                    { FBASES.DAT                      }
    Name     : String[40];             { File base name                  }
    Filename : String[8];              { File name                       }
    DispFile : String[8];              { Pre-list display file name      }
    ACS,                               { ACS required to see this base   }
    SysopACS,                          { ACS required for SysOp functions}
    ULACS,                             { ACS required to upload files    }
    DLACS    : String[20];             { ACS required to download files  }
    Path     : String[40];             { Path where files are stored     }
    Password : String[15];             { Password to access this base    }
    ShowUL   : Boolean;                { Show uploader in file lists     }
    DefScan  : Byte;                   { Default New Scan Setting        }
    IsCDROM  : Boolean;                { Is this a CD-ROM base?          }
    IsFREE   : Boolean;                { Files in this base are free?    }
  End;

  FDirFlags = (
    Offline,                           { Is file marked as OFFLINE?       }
    Invalid,                           { Is file marked as INVALID?       }
    Deleted,                           { Is file marked as DELETED?       }
    Failed,                            { Is file marked as FAILED?        }
    Free                               { Is file marked as free download? }
  );

(* The file directory listing are stored as <FBaseRec.FileName>.DIR in    *)
(* the data directory.  Each record stores the info on one file.  File    *)
(* descriptions are stored in <FBaseRec.FileName>.DES in the data         *)
(* directory.  FDirRec.Pointer points to the file position in the .DES    *)
(* file where the file description for the file begins.  FDirRec.Lines is *)
(* the number of lines in the file description.  Each line is stored as a *)
(* Pascal-like string (ie the first byte is the length of the string,     *)
(* followed by text which is the length of the first byte                 *)

  FDirRec = Record                     { *.DIR                              }
    FileName : String[12];             { File name                          }
    Size     : LongInt;                { File size (in bytes)               }
    DateTime : LongInt;                { Date and time of upload            }
    Uploader : String[30];             { User name who uploaded the file    }
    Flags    : Set of FDirFlags;       { Set of FDIRFLAGS (see above)       }
    Pointer  : LongInt;                { Pointer to file description        }
    Lines    : Byte;                   { Number of description lines        }
    DLs      : Integer;                { # of times this file was downloaded}
  End;

  GroupRec = Record                    { GROUP_*.DAT                  }
    Name  : String[30];                { Group name                   }
    ACS   : String[20];                { ACS required to access group }
  End;

(* Mystic BBS stores it's menu files as straight DOS text files.  They    *)
(* have been stored this way to make it possible to edit them with a text *)
(* editor (which is sometimes easier then using the menu editor).  The    *)
(* following records do not need to do used, but provide one way of       *)
(* reading a menu into a record.                                          *)

  MenuRec = Record
    Header,
    Prompt   : String[255];
    DispCols : Byte;
    ACS      : String[20];
    Password : String[15];
    TextFile : String[8];
    Fallback : String[8];
    LightBar : Byte; {0 = no, 1 = yes;}
    DoneX    : Byte;
    DoneY    : Byte;
    Global   : Byte; {0 = no, 1 = yes}
  End;

  MenuCmdRec = Record
    Text    : String[79];
    HotKey  : String[8];
    LongKey : String[8];
    Acs     : string[20];
    Command : String[2];
    Data    : String[79];
    X,
    Y       : Byte;
    LText   : String[79];
    LHText  : String[79];
  End;

  LangRec = Record                      { LANGUAGE.DAT                     }
    FileName  : String[8];              { Language file name               }
    Desc      : String[30];             { Language description             }
    TextPath  : String[40];             { Path where text files are stored }
    MenuPath  : String[40];             { Path where menu files are stored }
    BarYN     : Boolean;                { Use Lightbar Y/N with this lang  }
    YText     : String[60];             { Lightbar Yes highlight text      }
    NText     : String[60];             { Lightbar No highlight text       }
    FieldColor: Byte;                   { Field input color                }
    EchoCh    : Char;                   { Password echo character          }
    QuoteColor: Byte;                   { Color for quote lightbar         }
    InputCh   : Char;                   { Input character                  }
    TagCh     : Char;                   { File Tagged Char }
    okASCII   : Boolean;                { Allow ASCII }
    okANSI    : Boolean;                { Allow ANSI }
    FileHi    : Byte;                   { Color of file search highlight }
    FileLo    : Byte;                   { Non lightbar description color }
    Reserved  : Array[1..87] of Byte;   { RESERVED }
  End;

  BBSListRec = Record
    cType     : Byte;
    Phone     : String[15];
    Telnet    : String[40];
    BBSName   : String[30];
    Location  : String[25];
    SysopName : String[30];
    BaudRate  : String[6];
    Software  : String[10];
    Deleted   : Boolean;
    AddedBy   : String[30];
    Verified  : LongInt;
    Res       : Array[1..6] of Byte;
  End;

(* ONELINERS.DAT found in the data directory.  This file contains all the
   one-liner data.  It can be any number of records in size. *)

  OneLineRec = Record
    Text : String[79];
    From : String[30];
  End;

(* Each record of VOTES.DAT is one question.  Mystic only allows for up *)
(* to 20 questions. *)

  VoteRec = Record                     { VOTES.DAT in DATA directory      }
    Votes   : Integer;                 { Total votes for this question    }
    AnsNum  : Byte;                    { Total # of Answers               }
    User    : String[30];              { User name who added question     }
    ACS     : String[20];              { ACS to see this question         }
    AddACS  : String[20];              { ACS to add an answer             }
    ForceACS: String[20];              { ACS to force voting of question  }
    Question: String[79];              { Question text                    }
    Answer  : Array[1..15] of Record   { Array[1..15] of Answer data      }
                Text  : String[40];    { Answer text                      }
                Votes : Integer;       { Votes for this answer            }
              End;
  End;

(* CHATx.DAT is created upon startup, where X is the node number being    *)
(* loaded.  These files are used to store all the user information for a  *)
(* node.                                                                  *)

  ChatRec = Record                     { CHATx.DAT }
    Active    : Boolean;               { Is there a user on this node?   }
    Name      : String[30];            { User's name on this node        }
    Action    : String[40];            { User's action on this node      }
    Location  : String[30];            { User's City/State on this node  }
    Gender    : Char;                  { User's gender                   }
    Age       : Byte;                  { User's age                      }
    Baud      : String[6];             { User's baud rate                }
    Invisible : Boolean;               { Is node invisible?              }
    Available : Boolean;               { Is node available?              }
    InChat    : Boolean;               { Is user in multi-node chat?     }
    Room      : Byte;                  { Chat room                       }
  End;

(* Chat room record - partially used by the multi node chat functions *)

  RoomRec = Record
    Name     : String[40];             { Channel Name }
    Reserved : Array[1..128] of Byte;  { RESERVED }
  End;

(* CALLERS.DAT holds information on the last ten callers to the BBS. This *)
(* file is always 10 records long with the most recent caller being the   *)
(* 10th record.                                                           *)

  LastOnRec = Record                   { CALLERS.DAT                 }
    Handle   : String[30];             { User's Name                 }
    City     : String[25];             { City/State                  }
    Address  : String[30];             { user's address              }
    Baud     : String[6];              { Baud Rate                   }
    DateTime : LongInt;                { Date & Time (UNIX)          }
    Node     : Byte;                   { Node number of login        }
    CallNum  : LongInt;                { Caller Number               }
  End;
