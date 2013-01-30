{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit arcview;

interface

uses crt, dos, overlay, common;

function getbyte(var fp:file):char;
procedure abend;
procedure details;
procedure lfi(fn:astr);
procedure lfin(rn:integer);
procedure lfii;


implementation

uses file0, file14;

const
  L_SIG=$04034b50;   {* ZIP local file header signature *}
  C_SIG=$02014b50;   {* ZIP central dir file header signature *}
  E_SIG=$06054b50;   {* ZIP end of central dir signature *}
  Z_TAG=$fdc4a7dc;   {* ZOO entry identifier *}

  EXTS=7;     {* number of default extensions *}

  filext:array[0..EXTS-1] of string[4] = (
    '.ZIP',   {* ZIP format archive *}
    '.ARC',   {* ARC format archive *}
    '.PAK',   {* ARC format archive (PAK.EXE) *}
    '.ZOO',   {* ZOO format archive *}
    '.LZH',   {* LZH format archive *}
    '.ARK',   {* ARC format archive (CP/M ARK.COM) *}
    '.ARJ');  {* ARJ format archive *}


  method:array[0..21] of string[9] = (
    'Directory',  {* Directory marker *}
    'Unknown! ',  {* Unknown compression type *}
    'Stored   ',  {* No compression *}
    'Packed   ',  {* Repeat-byte compression *}
    'Squeezed ',  {* Huffman with repeat-byte compression *}
    'crunched ',  {* Obsolete LZW compression *}
    'Crunched ',  {* LZW 9-12 bit with repeat-byte compression *}
    'Squashed ',  {* LZW 9-13 bit compression *}
    'Crushed  ',  {* LZW 2-13 bit compression *}
    'Shrunk   ',  {* LZW 9-13 bit compression *}
    'Reduced 1',  {* Probabilistic factor 1 compression *}
    'Reduced 2',  {* Probabilistic factor 2 compression *}
    'Reduced 3',  {* Probabilistic factor 3 compression *}
    'Reduced 4',  {* Probabilistic factor 4 compression *}
    'Frozen   ',  {* Modified LZW/Huffman compression *}
    'Imploded ',  {* Shannon-Fano tree compression *}
    'Compressed',
    'Method 1 ',
    'Method 2 ',
    'Method 3 ',
    'Method 4 ',
    'Deflated ');

type
  arcfilerec=record   {* structure of ARC archive file header *}
               filename:array[0..12] of char; {* filename *}
               c_size:longint;     {* compressed size *}
               mod_date:SmallInt;   {* last mod file date *}
               mod_time:SmallInt;   {* last mod file time *}
               crc:SmallInt;        {* CRC *}
               u_size:longint;     {* uncompressed size *}
             end;


  zipfilerec=record   {* structure of ZIP archive file header *}
               version:SmallInt;    {* version needed to extract *}
               bit_flag:SmallInt;   {* general purpose bit flag *}
               method:SmallInt;     {* compression method *}
               mod_time:SmallInt;   {* last mod file time *}
               mod_date:SmallInt;   {* last mod file date *}
               crc:longint;        {* CRC-32 *}
               c_size:longint;     {* compressed size *}
               u_size:longint;     {* uncompressed size *}
               f_length:SmallInt;   {* filename length *}
               e_length:SmallInt;   {* extra field length *}
             end;

  zoofilerec=record   {* structure of ZOO archive file header *}
               tag:longint;     {* tag -- redundancy check *}
               typ:byte;        {* type of directory entry (always 1 for now) *}
               method:byte;     {* 0 = Stored, 1 = Crunched *}
               next:longint;    {* position of next directory entry *}
               offset:longint;  {* position of this file *}
               mod_date:SmallWord;   {* modification date (DOS format) *}
               mod_time:SmallWord;   {* modification time (DOS format) *}
               crc:SmallWord;        {* CRC *}
               u_size:longint;  {* uncompressed size *}
               c_size:longint;  {* compressed size *}
               major_v:char;    {* major version number *}
               minor_v:char;    {* minor version number *}
               deleted:byte;    {* 0 = active, 1 = deleted *}
               struc:char;      {* file structure if any *}
               comment:longint; {* location of file comment (0 = none) *}
               cmt_size:SmallWord;   {* length of comment (0 = none) *}
               fname:array[0..12] of char; {* filename *}
               var_dirlen:SmallInt; {* length of variable part of dir entry *}
               tz:char;         {* timezone where file was archived *}
               dir_crc:SmallWord;    {* CRC of directory entry *}
             end;

  lzhfilerec=record   {* structure of LZH archive file header *}
               h_length:byte;   {* length of header *}
               h_cksum:byte;    {* checksum of header bytes *}
               method:array[1..5] of char; {* compression type "-lh#-" *}
               c_size:longint;  {* compressed size *}
               u_size:longint;  {* uncompressed size *}
               mod_time:SmallInt;{* last mod file time *}
               mod_date:SmallInt;{* last mod file date *}
               attrib:SmallInt;  {* file attributes *}
               f_length:byte;   {* length of filename *}
               crc:SmallInt;     {* crc *}
             end;

   arjfilerec = Record
      FirstHdrSize : Byte;
      ARJversion   : Byte;
      ARJrequired  : Byte;
      HostOS       : Byte;
      Flags        : Byte;
      Method       : Byte;
      FileType     : Byte;
      GarbleMod    : Byte;
      Time,
      Date         : SmallInt;
      CompSize     : LongInt;
      OrigSize     : LongInt;
      OrigCRC      : Array[1..4] of Byte;
      EntryName    : SmallWord;
      AccessMode   : SmallWord;
      HostData     : SmallWord;
    end;

  outrec=record   {* output information structure *}
           filename:astr;                    {* output filename *}
           date:SmallInt;                     {* output date *}
           time:SmallInt;                     {* output time *}
           typ:SmallInt;                      {* output storage type *}
           csize:longint;                    {* output compressed size *}
           usize:longint;                    {* output uncompressed size *}
         end;

var
  accum_csize:longint;    {* compressed size accumulator *}
  accum_usize:longint;    {* uncompressed size accumulator *}
  files:integer;          {* number of files *}
  level:integer;          {* output directory level *}
  filetype:integer;       {* file type (1=ARC,2=ZIP,3=ZOO,4=LZH,5=ARJ) *}
  out:outrec;
  aborted:boolean;

function mnz(l:longint; w:integer):astr;
var s:astr;
begin
  s:=cstr(l);
  while length(s)<w do s:='0'+s;
  mnz:=s;
end;

function mnr(l:longint; w:integer):astr;
begin
  mnr:=mrn(cstr(l),w);
end;

{*------------------------------------------------------------------------*}

procedure abend;
begin
  print(^M^J'^7** ^5error processing archive^7 **');
  aborted:=TRUE;
  abort:=TRUE;
  next:=TRUE;
end;

{*------------------------------------------------------------------------*}

procedure details;
var i,month,day,year,hour,minute,typ:integer;
    ampm:char;
    ratio:longint;
    outp:astr;
begin
  typ:=out.typ;
  for i:=1 to length(out.filename) do
    out.filename[i]:=upcase(out.filename[i]);
  day:=out.date and $1f;                {* day = bits 4-0 *}
  month:=(out.date shr 5) and $0f;      {* month = bits 8-5 *}
  year:=((out.date shr 9) and $7f)+80;  {* year = bits 15-9 *}
  minute:=(out.time shr 5) and $3f;     {* minute = bits 10-5 *}
  hour:=(out.time shr 11) and $1f;      {* hour = bits 15-11 *}

  if (month>12) then dec(month,12);     {* adjust for month > 12 *}
  if (year>99) then dec(year,100);      {* adjust for year > 1999 *}
  if (hour>23) then dec(hour,24);       {* adjust for hour > 23 *}
  if (minute>59) then dec(minute,60);   {* adjust for minute > 59 *}

  if (hour<12) then ampm:='a' else ampm:='p';  {* determine AM/PM *}
  if (hour=0) then hour:=12;                   {* convert 24-hour to 12-hour *}
  if (hour>12) then dec(hour,12);

  if (out.usize=0) then ratio:=0 else   {* ratio is 0% for null-length file *}
    ratio:=100-((out.csize*100) div out.usize);
  if ratio>99 then ratio:=99;

  outp:='^4'+mnr(out.usize,8)+' '+mnr(out.csize,8)+' '+mnr(ratio,2)+'% ^9'+
        mrn(method[typ],9)+' ^7'+mnr(month,2)+'-'+mnz(day,2)+'-'+
        mnz(year,2)+' '+mnr(hour,2)+':'+mnz(minute,2)+ampm+' ^5';

  if (level>0) then outp:=outp+mrn('',level); {* spaces for dirs (ARC only)*}

  outp:=outp+out.filename;
  printacr(outp);

  if (typ=0) then inc(level)    {* bump dir level (ARC only) *}
  else begin
    inc(accum_csize,out.csize);  {* adjust accumulators and counter *}
    inc(accum_usize,out.usize);
    inc(files);
  end;
end;

{*------------------------------------------------------------------------*}

procedure final;
var outp:string[100];
    ratio:longint;
begin
  {*  final - Display final totals and information.
   *}

  if accum_usize=0 then ratio:=0    {* ratio is 0% if null total length *}
  else
    ratio:=100-((accum_csize*100) div accum_usize);
  if ratio>99 then ratio:=99;

  outp:='^4'+mnr(accum_usize,8)+' '+mnr(accum_csize,8)+' '+mnr(ratio,2)+
        '%                           ^5'+cstr(files)+' file';
  if files<>1 then outp:=outp+'s';
  printacr('^4-------- -------- ---                           ------------');
  printacr(outp);
end;

{*------------------------------------------------------------------------*}

function getbyte(var fp:file):char;
var
  numread:word;
  c:char;
begin
  if (not aborted) then begin
    blockread(fp,c,1,numread);
    if numread=0 then begin
      close(fp);
      abend;
    end;
    getbyte:=c;
  end;
end;

{*------------------------------------------------------------------------*}

procedure zip_proc(var fp:file);
var zip:zipfilerec;
    signature:longint;
    numread:word;
    i:integer;
    c:char;
begin
  while (not aborted) do begin
    blockread(fp,signature,4,numread);
    if (signature=C_SIG) or (signature=E_SIG) then exit;
    if (numread<>4) or (signature<>L_SIG) then begin abend; exit; end;
    blockread(fp,zip,26,numread);
    if (numread<>26) then begin abend; exit; end;
    for i:=1 to zip.f_length do
      out.filename[i]:=getbyte(fp);
    out.filename[0]:=chr(zip.f_length);
    for i:=1 to zip.e_length do
      c:=getbyte(fp);
    out.date:=zip.mod_date;
    out.time:=zip.mod_time;
    out.csize:=zip.c_size;
    out.usize:=zip.u_size;
    case zip.method of
      0:out.typ:=2;
      1:out.typ:=9;
      2,3,4,5:
        out.typ:=zip.method+8;
      6:out.typ:=15;
      8:out.typ:=21;
      else out.typ:=1;
    end;
    details;
    if abort then exit;
    seek(fp,filepos(fp)+zip.c_size);  {* seek to next entry *}
    if (ioresult<>0) then abend;
    if (abort) then exit;
  end;
end;

procedure arj_proc(var arjfile:file);
Type ARJsignature = Record
      MagicNumber : SmallWord;
      BasicHdrSiz : SmallWord;
   end;

var Hdr       : arjfilerec;
   Sig       : ARJsignature;
   HeaderCrc,topdate,settime: Longint;
   FileName,filetitle: astr;
   JunkByte  : Byte;
   BytesRead,extsize: Word;
   I,filecount: Integer;
   TimeStamp : DateTime;
   DirInfo   : SearchRec;

begin
      BlockRead (ArjFile, Sig, SizeOf(Sig));
      if (IOResult <> 0) or (Sig.MagicNumber <> $EA60) then exit
      else begin
         BlockRead (ArjFile, Hdr, SizeOf(Hdr), BytesRead);
         i:=0;
         repeat
            inc(i);
            BlockRead(ArjFile, FileName[I], 1);
            Until FileName[I] = #0;
         fileName[0]:=Chr(I-1);

         { Wipe a comment from the file }
         Repeat
            BlockRead(ArjFile, JunkByte, 1);
         Until JunkByte=0;

         { Read in parts of the header information as wee need them }
         BlockRead (ArjFile, HeaderCRC, 4);    { Discard... }
         BlockRead (ArjFile, ExtSize, 2);      { Extended headers, not used }
         if ExtSize > 0 then
         Seek(ArjFile, FilePos(ArjFile) + ExtSize + 4);

         { Get the file signature }
         BlockRead (ArjFile, Sig, SizeOf(Sig));

         While (Sig.BasicHdrSiz>0) and (not abort) and (ioresult=0) do Begin
            { Read the next file header }
            BlockRead (ArjFile, Hdr, SizeOf(Hdr), BytesRead);

            { Convert from ASCIIZ to Pascal string }
            I:=0;
            Repeat
               Inc (I);
               BlockRead (ArjFile,FileName[I],1);
               Until FileName[I] = #0;
               FileName[0] := Chr(I-1);

           out.filename:=filename;
           out.date:=hdr.date;
           out.time:=hdr.time;
           if hdr.method=0 then out.typ:=2 else out.typ:=hdr.method+16;
           out.csize:=hdr.compsize;
           out.usize:=hdr.origsize;
           details;
           if abort then exit;

            { Remove a single file comment }
            Repeat
               BlockRead(ArjFile, JunkByte, 1);
            Until JunkByte=0;

            { Discard the rest of the header, and the actual file data }
            BlockRead(ArjFile,HeaderCRC,4);
            BlockRead(ArjFile,ExtSize,2);
            Seek(ArjFile,FilePos(ArjFile)+Hdr.CompSize);
            BlockRead(ArjFile,Sig,SizeOf(Sig));
         end;
      end;
end;

procedure arc_proc(var fp:file);
var arc:arcfilerec;
    numread:word;
    i,typ:integer;
    c:char;
begin
  repeat
    c:=getbyte(fp);
    typ:=ord(getbyte(fp));
    case typ of
      0:exit;
      1,2:out.typ:=2;
      3,4,5,6,7:out.typ:=typ;
      8,9,10:out.typ:=typ-2;
      30:out.typ:=0;
      31:dec(level);
    else out.typ:=1;
    end;
    if typ<>31 then begin    {* get data from header *}
      blockread(fp,arc,23,numread);
      if numread<>23 then begin abend; exit; end;
      if typ=1 then          {* type 1 didn't have c_size field *}
        arc.u_size:=arc.c_size
      else begin
        blockread(fp,arc.u_size,4,numread);
        if numread<>4 then begin abend; exit; end;
      end;
      i:=0;
      repeat
        inc(i);
        out.filename[i]:=arc.filename[i-1];
      until (arc.filename[i]=#0) or (i=13);
      out.filename[0]:=chr(i);
      out.date:=arc.mod_date;
      out.time:=arc.mod_time;
      if typ=30 then begin
        arc.c_size:=0;            {* set file size entries *}
        arc.u_size:=0;            {* to 0 for directories *}
      end;
      out.csize:=arc.c_size;   {* set file size entries *}
      out.usize:=arc.u_size;   {* for normal files *}
      details;
      if abort then exit;
      if typ<>30 then begin
        seek(fp,filepos(fp)+arc.c_size); {* seek to next entry *}
        if ioresult<>0 then begin abend; exit; end;
      end;
    end;
  until (c<>#$1a) or (aborted);
  if not aborted then abend;
end;

{*------------------------------------------------------------------------*}

procedure zoo_proc(var fp:file);
var zoo:zoofilerec;
    zoo_longname,zoo_dirname:astr;
    numread:word;
    i,method:integer;
    namlen,dirlen:byte;
begin
  while (not aborted) do begin
    blockread(fp,zoo,56,numread);
    if numread<>56 then begin abend; exit; end;
    if zoo.tag<>Z_TAG then abend;
    if (abort) or (zoo.next=0) then exit;

    namlen:=ord(getbyte(fp));
    dirlen:=ord(getbyte(fp));
    zoo_longname:='';
    zoo_dirname:='';

    if namlen>0 then
      for i:=1 to namlen do
        zoo_longname:=zoo_longname+getbyte(fp);
    if dirlen>0 then begin
      for i:=1 to dirlen do
        zoo_dirname:=zoo_dirname+getbyte(fp);
      if zoo_dirname[length(zoo_dirname)] <> '/' then
        zoo_dirname := zoo_dirname + '/';
    end;
    if zoo_longname<>'' then out.filename:=zoo_longname
    else begin
      i:=0;
      repeat
        inc(i);
        out.filename[i]:=zoo.fname[i-1];
      until (zoo.fname[i]=#0) or (i=13);
      out.filename[0]:=chr(i);
      out.filename:=zoo_dirname+out.filename;
    end;
    out.date:=zoo.mod_date;
    out.time:=zoo.mod_time;
    out.csize:=zoo.c_size;
    out.usize:=zoo.u_size;
    method:=zoo.method;
    case method of
      0:out.typ:=2;      {* Stored *}
      1:out.typ:=6;      {* Crunched *}
    else
        out.typ:=1;      {* Unknown! *}
    end;
    if not (zoo.deleted=1) then details;
    if abort then exit;

    seek(fp,zoo.next);  {* seek to next entry *}
    if ioresult<>0 then begin abend; exit; end;
  end;
end;

{*------------------------------------------------------------------------*}

procedure lzh_proc(var fp:file);
var lzh:lzhfilerec;
    numread:word;
    i:integer;
    c:char;
begin
  while (not aborted) do begin
    c:=getbyte(fp);
    if (c=#0) then exit else lzh.h_length:=ord(c);
    c:=getbyte(fp);
    lzh.h_cksum:=ord(c);
    blockread(fp,lzh.method,5,numread);
    if (numread<>5) then begin abend; exit; end;
    if ((lzh.method[1]<>'-') or
        (lzh.method[2]<>'l') or
        (lzh.method[3]<>'h')) then begin abend; exit; end;
    blockread(fp,lzh.c_size,15,numread);
    if (numread<>15) then begin abend; exit; end;
    for i:=1 to lzh.f_length do out.filename[i]:=getbyte(fp);
    out.filename[0]:=chr(lzh.f_length);
    if (lzh.h_length-lzh.f_length=22) then begin
      blockread(fp,lzh.crc,2,numread);
      if (numread<>2) then begin abend; exit; end;
    end;
    out.date:=lzh.mod_date;
    out.time:=lzh.mod_time;
    out.csize:=lzh.c_size;
    out.usize:=lzh.u_size;
    write('>',c,'<');
    c:=lzh.method[4];
    case c of
      '0':out.typ:=2;
      '1':out.typ:=14;
    else out.typ:=1;
    end;
    details;

    seek(fp,filepos(fp)+lzh.c_size); {* seek to next entry *}
    if (ioresult<>0) then abend;
    if (abort) then exit;
  end;
end;

procedure lfi(fn:astr);
var fp:file;
    dirinfo1:searchrec;
    lzh:lzhfilerec;
    temp,infile,filename,showfn:astr;
    zoo_temp,zoo_tag:longint;
    numread:word;
    p,i,arctype,rcode:byte;
    c:char;
begin
  fn:=sqoutsp(fn);
  if (pos('*',fn)<>0) or (pos('?',fn)<>0) then begin
    findfirst(fn,anyfile-directory-volumeid,dirinfo1);
    if (doserror=0) then fn:=dirinfo1.name;
  end;
  if ((exist(fn)) and (not abort)) then begin
    arctype:=1;
    while (general.filearcinfo[arctype].ext<>'') and
          (general.filearcinfo[arctype].ext<>copy(fn,length(fn)-2,3)) and
          (arctype<maxarcs+1) do
      inc(arctype);
    if not ((general.filearcinfo[arctype].ext='') or (arctype=7)) then begin
      temp:=general.filearcinfo[arctype].listline;
      if (temp[1]='/') and (temp[2] in ['1'..'5']) and (length(temp)=2) then begin
        aborted:=FALSE;
        showfn:=stripname(fn);
        printacr('^3'+showfn+':'^M^J);
        if (not abort) then begin
          infile:=fn;
          assign(fp,infile);
          reset(fp,1);

          c:=getbyte(fp);  {* determine type of archive *}
          case c of
            #$1a:filetype:=1;
            'P':begin
                  if getbyte(fp)<>'K' then abend;
                  filetype:=2;
                end;
            'Z':begin
                  for i:=0 to 1 do
                    if getbyte(fp)<>'O' then abend;
                  filetype:=3;
                end;
            #96:begin
                  if getbyte(fp)<>#234 then abend;
                  filetype:=5;
                end;
          else
                begin       {* assume LZH format *}
                  lzh.h_length:=ord(c);
                  c:=getbyte(fp);
                  for i:=1 to 5 do lzh.method[i]:=getbyte(fp);
                  if ((lzh.method[1]='-') and
                      (lzh.method[2]='l') and
                      (lzh.method[3]='h')) then
                    filetype:=4
                  else
                    abend;
                end;
          end;

          reset(fp,1);                      {* back to start of file *}

          p:=0;                             {* drop drive and pathname *}
          for i:=1 to length(infile) do
            if infile[i] in [':','\'] then p:=i;
          filename:=copy(infile,p+1,length(infile)-p);

          accum_csize:=0; accum_usize:=0;   {* set accumulators to 0 *}
          level:=0; files:=0;               {* ditto with counters *}

          if filetype=3 then begin    {* process initial ZOO file header *}
            for i:=0 to 19 do      {* skip header text *}
              c:=getbyte(fp);
             {* get tag value *}
            blockread(fp,zoo_tag,4,numread);
            if numread<>4 then abend;
            if zoo_tag<>Z_TAG then abend;
             {* get data start *}
            blockread(fp,zoo_temp,4,numread);
            if numread<>4 then abend;
            seek(fp,zoo_temp);
            if ioresult<>0 then abend;
          end;

           {* print headings *}
          AllowContinue := TRUE;
          printacr('^3 Length  Size Now  %   Method     Date    Time  Filename');
          printacr('^4-------- -------- --- --------- -------- ------ ------------');
          case filetype of
            1:arc_proc(fp);  {* process ARC entry *}
            2:zip_proc(fp);  {* process ZIP entry *}
            3:zoo_proc(fp);  {* process ZOO entry *}
            4:lzh_proc(fp);  {* process LZH entry *}
            5:arj_proc(fp);  {* processs ARJ entry *}
          end;
          final;      {* clean things up *}
          close(fp);              {* close file *}
        end;
      end else begin
        prompt(^M^J'^3Archive '+fn+':  ^4Please wait....');
        temp:=FunctionalMCI(general.filearcinfo[arctype].listline,fn,'')+' >shell.$$$';
        shelldos(FALSE,temp,rcode);
        BackErase(15);
        pfl('shell.$$$');
        kill('shell.$$$');
      end;
    end;
  end;
end;

procedure lfin(rn:integer);
var f:ulfrec;
begin
  seek(DirFile,rn); read(DirFile,f);
  if exist(memuboard.dlpath+f.filename) then
    lfi(memuboard.dlpath+f.filename)
  else
    lfi(memuboard.ulpath+f.filename)
end;

procedure lfii;
var f:ulfrec;
    fn:astr;
    rn:integer;
    lastarc,lastgif,isgif:boolean;
begin
  print(^M^J + fstring.viewline + ^M^J);
  prt('Filename: ');
  mpl(12);
  input(fn, 12);
  if (fn<>'') and (pos('.',fn)=0) then fn:=fn+'*.*';
  abort:=FALSE; next:=FALSE; AllowContinue := TRUE;
  recno(fn,rn);
  if (baddlpath) then exit;
  abort:=FALSE; next:=FALSE; lastarc:=fALSE; lastgif:=FALSE;
  while ((rn<>-1) and (not abort)) do begin
    seek(DirFile,rn); read(DirFile,f);
    isgif:=isgifext(f.filename);
    if (isgif) then begin
      lastarc:=FALSE;
      if (not lastgif) then begin
        lastgif:=TRUE;
        printacr(^M^J^M^J'^3Filename.Ext '+seperator+' Resolution '+seperator+
                 ' Num Colors '+seperator+' Signat.');
        printacr('^4=============:============:============:=========');
      end;
      if exist(memuboard.dlpath+f.filename) then
        dogifspecs(sqoutsp(memuboard.dlpath+f.filename))
      else
        dogifspecs(sqoutsp(memuboard.ulpath+f.filename))
    end else begin
      lastgif:=FALSE;
      if (not lastarc) then begin
        lastarc:=TRUE;
        nl;
      end;
      lfin(rn);
    end;
    nrecno(fn,rn);
    if (next) then abort:=FALSE;
    next:=FALSE;
  end;
  close(DirFile);
end;

end.
