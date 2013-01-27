{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}
Unit X;
INTERFACE
uses
  dos, overlay, common;

IMPLEMENTATION

begin
end.

{
컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
Offline Mail Object 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴

Offline Mail
  Offline mail will use its own configuration info.

  If a user has not used offline mail, there will be no record for him, and
  he will have to configure one as it will use the defaults.

  This will save space since it will not have to have a scan pointer set for
  all the users, just the ones in the database.
}

CONST
  OLM_QWK   = 0;
  OLM_BWAVE = 1;
  OLM_TEXT  = 2;


{
  First record is the free record pointer.
  If UserNumber is 0, there are no free pointers
  If UserNumber is 1, then there are free pointers
  If PointerPos points to the first free pointer,  0 if UserNumber is 0
  If PointerPos is 0, add to the end of the file
}

TYPE
  OfflineRecord=RECORD
    UserNumber:word;                { Number of user in users.dat }
    PointerPos:Word;                { Which record is users newscan pointers }
    MailType:Byte;                  { See Offline Mail Types }

    DefArcType:Byte;                { Default Archiver type }
    LastPacket:LongInt;             { Date of last packet }
    GetOwn:Boolean;                 { Get your own messages? }
    GetNewFilesList:Boolean;        { Get new files listing? }
    GetEmail:Boolean;               { Get from EMAIL bases? }
    MaxMsgsInPacket:word;           { Max messages to take, <= Global Max }
    MaxMsgsInBase:Word;             { Max messages in base, <= Global Max }
    LocalPath:str40;                { Where to if local download }
    Blah:array[1..6] of byte;       { Extra stuffer = 64 bytes }
  end; { 58 }

TYPE
  OfflineMailObject=Object(RgObject)
    Data:OfflineRecord;

    Constructor Init(WhichUser:Word);
    Destructor  Done;

    Procedure ToggleScan(Idx:Word);
              { Toggles Newscan of specified base for offline mail }
    Procedure SetScan;
              { Sets scan areas for offline mail }
    Procedure SetPointerDate(Dte:LongInt);
              { Set date/time of message pointers (UNIX Date) }

    Procedure DownloadMail; virtual;
              { Downloads the mail }
    Procedure UploadMail; virtual;
              { Uploads Mail }
    Procedure ConfigureOptions; Virtual;
              { Configure the options for the setup }

    Procedure CollectNewFileList;
  end;



TYPE
  QwkMailObject=Object(OfflineMailObject)
    Constructor Init(WhichUser:Word);
    Destructor  Done;

    Procedure DownloadMail; virtual;
              { Downloads the mail }
    Procedure UploadMail; virtual;
              { Uploads Mail }
    Procedure ConfigureOptions; Virtual;
              { Configure the options for the setup }
  end;
{
컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
Offline Mail Object 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
}

