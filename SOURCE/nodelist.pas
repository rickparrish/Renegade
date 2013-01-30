{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Nodelist Interface }

unit Nodelist;

interface

uses crt, dos, overlay, common;

function getnewaddr(s:astr; var zone,net,node,point:SmallWord):boolean;
procedure GetNetAddress(var SysOpName:astr; var Zone,Net,Node,Point:SmallWord; var Fee:word; GetFee:boolean);
procedure ChangeFlags(var msgheader:mheaderrec);
function netmail_attr(netattribute:netattribs):string;

implementation

uses mail0;

type
	CompProc	 = function (var ALine, Desire; L : Char) : Integer;
	DATRec = record
			Zone, 											{ Zone of board 							}
			Net,												{ Net Address of board				}
			Node, 											{ Node Address of board 			}
			Point 		: SmallInt;				{ Either point number or 0		}
			CallCost, 									{ Cost to sysop to send 			}
			MsgFee, 										{ Cost to user to send				}
			NodeFlags 	: SmallWord; 				{ Node flags									}
			ModemType,									{ Modem type									}
			PassWord		: String [9];
			Phone 			: String [39];
			BName 			: String [39];
			CName 			: String [39];
			SName 			: String [39];
			BaudRate		: Byte; 				{ Highest Baud Rate 					}
			RecSize 		: Byte; 				{ Size of the node on file		}
	 end;

	IndxRefBlk = record
					IndxOfs 		: SmallWord; 		{ Offset of string into block }
					IndxLen 		: SmallWord; 		{ Length of string						}
					IndxData		: LongInt;	{ Record number of string 		}
					IndxPtr 		: LongInt;	{ Block number of lower index }
			 end;  { IndxRef }
	LeafRefBlk = record
					KeyOfs			: SmallWord; 		{ Offset of string into block }
					KeyLen			: SmallWord; 		{ Length of string						}
					KeyVal			: LongInt;	{ Pointer to data block 			}
			 end; 	{ LeafRef }
	CtlBlk = record
			CtlBlkSize	: SmallWord; 				{ blocksize of Index blocks 	}
			CtlRoot,										{ Block number of Root				}
			CtlHiBlk, 									{ Block number of last block	}
			CtlLoLeaf 	: LongInt;			{ Block number of first leaf	}
			CtlHiLeaf 	: LongInt;			{ Block number of last leaf 	}
			CtlFree 		: LongInt;			{ Head of freelist						}
			CtlLvls 		: SmallWord; 				{ Number of index levels			}
			CtlParity 	: SmallWord; 				{ XOR of above fields 				}
	 end;
	INodeBlk = record
			IndxFirst 	: LongInt;			{ Pointer to next lower level }
			IndxBLink 	: LongInt;			{ Pointer to previous link		}
			IndxFLink 	: LongInt;			{ Pointer to next link				}
			IndxCnt 		: SmallInt;			{ Count of Items in block 		}
			IndxStr 		: SmallWord; 				{ Offset in block of 1st str	}
											{ If IndxFirst is NOT -1, this is INode:	}
			IndxRef 		: array [0..49] of IndxRefBlk;
	 end;
	LNodeBlk = record
			IndxFirst 	: LongInt;			{ Pointer to next lower level }
			IndxBLink 	: LongInt;			{ Pointer to previous link		}
			IndxFLink 	: LongInt;			{ Pointer to next link				}
			IndxCnt 		: SmallInt;			{ Count of Items in block 		}
			IndxStr 		: SmallWord; 				{ Offset in block of 1st str	}
			LeafRef 		: array [0..49] of LeafRefBlk;
	end;

function getnewaddr(s:astr; var zone,net,node,point:SmallWord):boolean;
begin
	getnewaddr:=FALSE;
	prt('Enter '+s+' in Z:N/N.P format: ');
	input(s,30);
	if (s='') or (pos('/',s)=0) then exit;
	if pos(':',s)>0 then begin
		zone:=value(copy(s,1,pos(':',s)));
		s:=copy(s,pos(':',s)+1,length(s));
	end else zone:=1;
	if pos('.',s)>0 then begin
		point:=value(copy(s,pos('.',s)+1,length(s)));
		s:=copy(s,1,pos('.',s)-1);
	end else point:=0;
	net:=value(copy(s,1,pos('/',s)));
	node:=value(copy(s,pos('/',s)+1,length(s)));
	getnewaddr:=TRUE;
end;

function netmail_attr(netattribute:netattribs):string;
var s:string[80];
begin
	s:='';
  if (local in netattribute) then s:='Local ';
  if (private in netattribute) then s:=s+'Private ';
	if (crash in netattribute) then s:=s+'Crash ';
	if (fileattach in netattribute) then s:=s+'FileAttach ';
	if (intransit in netattribute) then s:=s+'Intransit ';
	if (killsent in netattribute) then s:=s+'KillSent ';
	if (hold in netattribute) then s:=s+'Hold ';
	if (FileRequest in netattribute) then s:=s+'File Request ';
	if (FileUpdateRequest in netattribute) then s:=s+'Update Request ';
	netmail_attr:=s;
end;

function CompName (var ALine, Desire; L : Char) : Integer;

var
		Key 		: String[36];
		Desired : String[36];
		Len 		: Byte absolute L;
begin
		Key [0] := L;
		Desired [0] := L;
		Move (ALine, Key [1], Len);
		Move (Desire, Desired [1], Len);
		If Key > Desired then CompName := 1
				else If Key < Desired then CompName := -1
						else CompName := 0;
end;

function Compaddress (var ALine, Desire; L : Char) : Integer;
type
	NodeType = record
		Zone	: SmallWord;
		Net 	: SmallWord;
		Node	: SmallWord;
		Point : SmallWord;
	end;
var
	Key:NodeType absolute ALine;
	Desired:NodeType absolute Desire;
	Count:Byte;
	K:Integer;

begin
	Count := 0;
	repeat
		Inc (Count);
		Case Count of
			1 : Word (K) := Key.Zone - Desired.Zone;
			2 : Word (K) := Key.Net  - Desired.Net;
			3 : Word (K) := Key.Node - Desired.Node;
			4 : begin
						If L = #6 then Key.Point := 0;
						Word (K) := Key.Point - Desired.Point;
					end;
		end;	{ Case }
	until (Count = 4) or (K <> 0);
	Compaddress := K;
end;

procedure GetNetAddress(var SysOpName:astr; var Zone,Net,Node,Point:SmallWord; var Fee:word; GetFee:boolean);
var
	DataFile,NDXFile:file;
	City, BBSName,s:string[36];
	Location:longint;
	DAT:DatRec;
  Internet: boolean;

	function FullNodeStr (NodeStr : astr) : String;
	{ These constants are the defaults if the user does not specify them }
	const
			DefZone = '1';          { Default Zone  }
			DefNet = '1';         { Default Net   }
			DefNode = '1';          { Default Node  }
			DefPoint = '0';         { Default Point }
	begin
		If NodeStr [1] = '.' then NodeStr := DefNode + NodeStr;
		If Pos ('/', NodeStr) = 0 then
				If Pos (':', NodeStr) = 0 then NodeStr := DefZone + ':' +
						DefNet + '/' + NodeStr else
				 else
			begin
				If NodeStr [1] = '/' then NodeStr := DefNet + NodeStr;
				If Pos (':', NodeStr) = 0 then NodeStr := DefZone + ':' + NodeStr;
				If NodeStr [Length (NodeStr)] = '/' then NodeStr := NodeStr + DefNode;
			end;
		If Pos ('.', NodeStr) = 0 then NodeStr := NodeStr + '.' + DefPoint;
		FullNodeStr := NodeStr;
	end;

	function MakeAddress (Z, Nt, N, P : Word) : String;
		type
			NodeType = record 			{ A node address type }
				Len 	: Byte;
				Zone	: SmallWord;
				Net 	: SmallWord;
				Node	: SmallWord;
				Point : SmallWord;
			end;
	var
		Address:NodeType;
		S2:String absolute Address;

	begin
		With Address do
			begin
				Zone := Z;
				Net := Nt;
				Node := N;
				Point := P;
				Len := 8;
			end;
		MakeAddress := S2;
	end;

	function MakeName (Name : astr):String;
	var
		Temp	: String[36];
		Comma : String [2];

	begin
		Temp := Caps(Name);
		If (Pos(' ', Name) > 0) then
			Comma := ', '
		else
			Comma := '';
		MakeName := Copy(Temp, Pos(' ',Temp) + 1, Length(Temp) - Pos(' ',Temp))
							+ Comma + Copy(Temp,1,Pos(' ',Temp) - 1) + #0;
	end;

	procedure UnPk (S1:String; var S2:String; Count:Byte);
	const
		UnWrk:array [0..38] of Char = ' EANROSTILCHBDMUGPKYWFVJXZQ-''0123456789';

	type
		CharType = record
			C1, C2 : Byte;
		end;

	var
		U:CharType;
		W1:Word absolute U;
		I,J:Integer;
		OBuf:array [0..2] of Char;
		Loc1,Loc2:Byte;

	begin
		S2 := '';
		Loc1 := 1;
		Loc2 := 1;
		While (Count > 0) do
			begin
				U.C1 := Ord (S1 [Loc1]);
				Inc (Loc1);
				U.C2 := Ord (S1 [Loc1]);
				Inc (Loc1);
				Count := Count - 2;
				for J := 2 downto 0 do
          begin
						I := W1 MOD 40;
						W1 := W1 DIV 40;
						OBuf [J] := UnWrk [I];
					end;
				Move (OBuf, S2 [Loc2], 3);
				Inc (Loc2, 3);
			end;
		S2 [0] := Chr (Loc2);
	end;

function GetData (var F1 : File; SL : LongInt; var DAT : DATRec) : Boolean;

type
		RealDATRec = record
				Zone, 											{ Zone of board 							}
				Net,												{ Net Address of board				}
				Node, 											{ Node Address of board 			}
				Point 		: SmallInt;				{ Either point number or 0		}
				CallCost, 									{ Cost to sysop to send 			}
				MsgFee, 										{ Cost to user to send				}
				NodeFlags 	: SmallWord; 				{ Node flags									}
				ModemType,									{ Modem type									}
				PhoneLen, 									{ Length of Phone Number			}
				PassWordLen,								{ Length of Password					}
				BNameLen, 									{ Length of Board Name				}
				SNameLen, 									{ Length of Sysop Name				}
				CNameLen, 									{ Length of City/State Name 	}
				PackLen,										{ Length of Packed String 		}
				Baud				: Byte; 				{ Highest Baud Rate 					}
				Pack				: array [1..160]
												of Char;		{ The Packed String 					}
		 end;

var
		DATA		: RealDATRec;
		error 	: Boolean;
		UnPack	: String[160];

begin
		Seek (F1, SL);

{ Read everything at once to keep disk access to a minimum }

		BlockRead (F1, DATA, SizeOf (DATA));
		error := IOResult <> 0;

		If Not error then
				With DAT, DATA do
					begin
						Move (DATA, DAT, 15);
						Phone := Copy (Pack, 1, PhoneLen);
						PassWord	:= Copy (Pack, PhoneLen + 1, PasswordLen);
						Move (Pack [PhoneLen + PasswordLen + 1], Pack [1], PackLen);
						UnPk (Pack, UnPack, PackLen);
						BName := Caps(Copy(UnPack, 1, BNameLen));
						SName := Caps(Copy(Unpack, BNameLen + 1, SNameLen));
						CName := Caps(Copy(UnPack, BNameLen + SNameLen + 1, CNameLen));
						BaudRate := Baud;
						RecSize := (PhoneLen + PassWordLen + PackLen) + 22;
					end;
end;

procedure Get7Node (var F 				: File;
												SL				: LongInt;
										var Buf);
begin
	Seek (F, SL);
	BlockRead (F, Buf, 512);
	If IOResult <> 0 then Halt (1);
end;


function BTree (var F1 : File; Desired : astr; Compare : CompProc) : LongInt;

label Return;

var
		Buf 		: array [0..511] of Char; 	{ These four variables all occupy 	}
		CTL 		: CTLBlk absolute Buf;			{ the same memory location.  Total	}
		INode 	: INodeBlk absolute Buf;		{ of 512 bytes. 										}
		LNode 	: LNodeBlk absolute Buf;		{ --------------------------------- }

		NodeCTL : CTLBlk; 									{ Store the CTL block seperately		}
		J, K, L : Integer;									{ Temp integers 										}
		Count 	: Integer;									{ The counter for the index in node }
		ALine 	: String[160];							{ Address from NDX file 						}
		TP			: Word; 										{ Pointer to location in BUF				}
		Rec 		: LongInt;									{ A temp record in the file 				}
		FRec		: LongInt;									{ The record when found or not			}

begin
		FRec := -1;

		Get7Node (F1, 0, Buf);
		If CTL.CTLBlkSize = 0 then goto Return;

		Move (Buf, NodeCTL, SizeOf (CTL));

		Get7Node (F1, NodeCTL.CtlRoot * NodeCTL.CtlBlkSize, Buf);

		While (INode.IndxFirst <> -1) and (FRec = -1) do
				begin
						Count := INode.IndxCnt;
						If Count = 0 then goto Return;

						J := 0;
						K := -1;
						While (J < Count) and (K < 0) do
								begin

										TP := INode.IndxRef [J].IndxOfs;
										L := INode.IndxRef [J].IndxLen;
{ 									 ALine [0] := Chr (L); }
										Move (Buf [TP], ALine [1], L);

										K := Compare (ALine [1], Desired [1], Chr (L));
										If K = 0 then FRec := INode.IndxRef [J].IndxData
												else If K < 0 then Inc (J);
								 end;

								 If (FRec = -1) then
										begin
												If J = 0 then Rec := INode.IndxFirst
														else Rec := INode.IndxRef [J - 1].IndxPtr;
												Get7Node (F1, Rec * NodeCTL.CtlBlkSize, Buf);
										 end;
						 end;

		If (FRec = -1) then
				begin
						Count := LNode.IndxCnt;
						If (Count <> 0) then
								begin
										J := 0;
										While (J < Count) and (FRec = -1) do
												begin
														TP := LNode.LeafRef [J].KeyOfs;
														L := LNode.LeafRef [J].KeyLen;
{ 													 ALine [0] := Chr (L);}
														Move (Buf [TP], ALine [1], L);

														K := Compare (ALine [1], Desired [1], Chr (L));
														If K = 0 then
															FRec := LNode.LeafRef [J].KeyVal;
														Inc (J);
												 end;  { While }
										end;	{ If }
						end;	{ If }
Return :

		BTree := FRec;
end;

function Pull(var S:String; C:Char) : String;
var
	I:Byte;
begin
	I := Pos(C, S);
	Pull := Copy(S, 1, I - 1);
	Delete(S, 1, I);
end;

begin
	nl;
  Internet := FALSE;
	if not exist(General.NodePath + 'NODEX.DAT') or
		 not exist(General.NodePath + 'SYSOP.NDX') or
		 not exist(General.NodePath + 'NODEX.NDX') then
		begin
      if (GetFee) then
        begin
          Fee := 0;
          exit;
        end;
			print('Enter name of intended receiver.');
			prt(':');
      inputdefault(SysOpName,SysOpName, 36, 'P', TRUE);
			if (SysOpName = '') then exit;
      if (pos('@', SysOpName) > 0) then
        if (pynq('Is this an Internet message? ')) then
          begin
            Internet := TRUE;
            Zone := General.Aka[20].Zone;
            Net := General.Aka[20].Net;
            Node := General.Aka[20].Node;
            Point := General.Aka[20].Point;
            Fee := 0;
            exit;
          end
        else
          nl;
      if not getnewaddr('Address',zone,net,node,point) then exit;
			exit;
		end;

    assign(DataFile,General.NodePath + 'NODEX.DAT');

    if (GetFee) then
      begin
        s := cstr(Net) + '/' + cstr(Node);
        if (Zone > 0) then s := cstr(Zone) + ':' + s;
        if (Point > 0) then s := s + '.' + cstr(Point);
        s := FullNodeStr(s);
        assign(NDXFile,General.NodePath + 'NODEX.NDX');
        reset(NDXFile,1);
        Location := BTree (NDXFile, MakeAddress (Value(Pull (S, ':')),
                     Value(Pull (S, '/')), Value(Pull (S, '.')),
                     Value(S)), Compaddress);
        close(NDXFile);
        if (Location <> -1) then
          begin
            reset(DataFile,1);
            GetData (DataFile, Location, DAT);
            close(DataFile);
            Fee := DAT.MsgFee;
          end
        else
          Fee := 0;
        exit;
      end;

	s := SysOpName; SysOpName := ''; Fee := 0;

	repeat
    print('Enter a name, a Fidonet address, or an Internet address.');
		prt(':');
    inputdefault(s,s,36,'',TRUE);
		if (s = '') then break;
		if (pos('/',s) > 0) then
			begin
				s := FullNodeStr(s);
				assign(NDXFile,General.NodePath + 'NODEX.NDX');
				reset(NDXFile,1);
				Location := BTree (NDXFile, MakeAddress (Value(Pull (S, ':')),
										 Value(Pull (S, '/')), Value(Pull (S, '.')),
										 Value(S)), Compaddress);
				close(NDXFile);
			end
		else
			begin
				assign(NDXFile,General.NodePath + 'SYSOP.NDX');
				reset(NDXFile,1);
				Location := BTree (NDXFile, MakeName(S), CompName);
				close(NDXFile);
			end;
		if (Location <> -1) then
			begin
				reset(DataFile,1);
				GetData (DataFile, Location, DAT);
				close(DataFile);
				with DAT do
					begin
						print('^1System: ' + BName + ' ('+cstr(Zone)+':'+cstr(Net)+
									'/'+cstr(Node)+')');
						print('SysOp : ' + SName);
						print('Phone : ' + Phone);
						print('Where : ' + CName);
						print('Cost  : ' + cstr(MsgFee) + ' credits');
					end;
				nl;
				if (DAT.MsgFee > (thisuser.credit - thisuser.debit)) then
					begin
						print('You do not have enough credit to netmail this node!');
						s := '';
					end
				else
					if pynq('Is this correct? ') then
						begin
							SysOpName := DAT.Sname;
							Zone := DAT.Zone; Net := DAT.Net;
							Node := DAT.Node; Point := 0;
							Fee := DAT.MsgFee;
						end
					else
						s := '';
			end
		else
      if (pos('@', s) > 0) then
        if (not pynq('Is this an Internet message? ')) then
          begin
            print('That name is not in the nodelist!'^M^J);
            S := '';
          end
        else
          begin
            Internet := TRUE;
            SysOpName := s;
            Zone := General.Aka[20].Zone;
            Net := General.Aka[20].Net;
            Node := General.Aka[20].Node;
            Point := General.Aka[20].Point;
            Fee := 0;
          end
        else
          begin
            print('That name is not in the nodelist!'^M^J);
            S := '';
          end

	 until (SysOpName <> '') or (hangup);

   if (not Internet) and (pos('/',s) = 0) and (s <> '') then
		 begin
			 print(^M^J'Enter name of intended receiver.');
			 prt(':'); inputdefault(SysOpName,SysOpName,36,'P',FALSE);
			 if (SysOpName = '') then exit;
		 end;

	Lasterror := IOResult;
end;

procedure ChangeFlags(var msgheader:mheaderrec);
var
	c:char;
begin
	if (CoSysOp) and (pynq('Change default netmail flags? ')) then
		begin
			abort := FALSE; c := #0;
			nl;
			repeat
				if (c <> '?') then
					print('^4Current flags: ^5' + netmail_attr(msgheader.netattribute) + ^M^J);
				prt('Flag to change: ');
				onek(c,'PCAIKHRLUQ?'^M);
				nl;
				with msgheader do
					case c of
						'?':begin
									lcmds3(15,3,'Private', 'Crash', 'Attached File');
									lcmds3(15,3,'Intransit', 'KillSent', 'Hold');
									lcmds3(15,3,'Req File', 'Update Req', 'Local');
									nl;
								end;
						'L':if (Local) in Netattribute then
									Netattribute := Netattribute - [Local]
								else
									Netattribute := Netattribute + [Local];
						'U':if (FileUpdateRequest) in Netattribute then
									Netattribute := Netattribute - [FileUpdateRequest]
								else
									Netattribute := Netattribute + [FileUpdateRequest];
						'R':if (FileRequest) in Netattribute then
									Netattribute := Netattribute - [FileRequest]
								else
									Netattribute := Netattribute + [FileRequest];
						'H':if (Hold) in Netattribute then
									Netattribute := Netattribute - [Hold]
								else
									Netattribute := Netattribute + [Hold];
						'K':if (KillSent) in Netattribute then
									Netattribute := Netattribute - [KillSent]
								else
									Netattribute := Netattribute + [KillSent];
						'I':if (Intransit) in Netattribute then
									Netattribute := Netattribute - [Intransit]
								else
									Netattribute := Netattribute + [Intransit];
						'A':if (FileAttach in Netattribute) then
									Netattribute := Netattribute - [FileAttach]
								else
									Netattribute := Netattribute + [FileAttach];
						'C':if (Crash) in Netattribute then
									Netattribute := Netattribute - [Crash]
								else
									Netattribute := Netattribute + [Crash];
						'P':if (Private) in Netattribute then
									Netattribute := Netattribute - [Private]
								else
									Netattribute := Netattribute + [Private];
					end;
			until (Hangup) or (c in ['Q',^M]);
		end;
	nl;
end;
end.
