{$I-}
program testfiles;

uses dos;

type
FileStatus=
 (Unvalidated,                  { File not validated yet }
  Offline,                      { File is offline }
  Resume,                       { File being saved for later resume }
  Free,                         { File is free, regardless of base settings }
  NoTime);                      { File download is allowed regardless of time }

DirFileRec=                       { *.DIR File records }
  record
    FileName:string[12];          { Name }
    Deleted:boolean;              { Has it been lazy deleted? }
    Size,                         { File size }
    DateUploaded,                 { Date it was uploaded }
    DateLastDownloaded,           { Date last downloaded }
    Password,                     { Password to download }
    Description:longint;          { Pointer to extended description }
    DescriptionLength,            { Length of extended description }
    Downloaded,                   { Times downloaded }
    Uploader,                     { User # who uploaded it }
    Credits,                      { Credit cost }
    Left,                         { Left node }
    Right:integer;                { Right node }
    UploaderNameCRC:longint;      { User name who uploaded it }
    Flags:set of FileStatus;      { File status }
  end;

var
  AFile:DirFileRec;
  c:char;
  FileName:string[12];
  DirFile:file of DirFileRec;

function SearchFile(FileName:string):integer;
var
  DFO:boolean;
  AFile:DirFileRec;
  Current:integer;
begin
  DFO := (filerec(DirFile).mode<>fmclosed);
  if (not DFO) then
    reset(DirFile);

  Current := 0;
  SearchFile := 0;

  if (filesize(DirFile) > 0) then
    begin
      repeat
        seek(DirFile, Current);
        read(DirFile, AFile);
        if (FileName < AFile.FileName) then
          Current := AFile.Left
        else
          if (FileName > AFile.FileName) then
            Current := AFile.Right
          else
            if not (AFile.Deleted) then
              SearchFile := Current + 1;
      until (Current < 1) or (FileName = AFile.FileName);
    end;

  writeln(AFile.Deleted);

  if (not DFO) then
    close(DirFile);

end;

procedure AddFile(FileToAdd:DirFileRec);
var
  DFO:boolean;
  AFile:DirFileRec;
  Current:integer;
begin
  DFO := (filerec(DirFile).mode <> fmclosed);
  if (not DFO) then
    reset(DirFile);

  Current := 0;
  FileToAdd.Left := -1;
  FileToAdd.Right := -1;

  if (filesize(DirFile) = 0) then
    write(DirFile, FileToAdd)
  else
    begin
      repeat
        seek(DirFile, Current);
        read(DirFile, AFile);
        if (FileToAdd.FileName < AFile.FileName) then
          Current := AFile.Left
        else
          if (FileToAdd.FileName > AFile.FileName) then
            Current := AFile.Right
          else
            Current := 0;
      until (Current < 1);
      if (Current = -1) then
        begin
          if (FileToAdd.FileName < AFile.FileName) then
            AFile.Left := filesize(DirFile)
          else
            AFile.Right := filesize(DirFile);
          seek(DirFile, FilePos(DirFile) - 1);
          write(DirFile, AFile);
          seek(DirFile, filesize(DirFile));
          write(DirFile, FileToAdd);
        end
      else if (Current = 0) then
        begin
          seek(DirFile, filepos(DirFile) - 1);
          write(DirFile, FileToAdd);
        end;
    end;

  if (not DFO) then
    close(DirFile);
end;

procedure DeleteFile(FileName:string);
var
  DFO:boolean;
  AFile:DirFileRec;
  Current:integer;
begin
  DFO := (filerec(DirFile).mode <> fmclosed);
  if (not DFO) then
    reset(DirFile);

  Current := SearchFile(FileName);

  if (Current > 0) then
    begin
      seek(DirFile, Current - 1);
      read(DirFile, AFile);
      AFile.Deleted := TRUE;
      seek(DirFile, Current - 1);
      write(DirFile, AFile);
    end;

  if (not DFO) then
    close(DirFile);
end;

begin
  fillchar(AFile, sizeof(AFile), 0);
  assign(DirFile, 'file.dir');
  reset(DirFile);
  if (ioresult <> 0) then
    rewrite(DirFile);

  repeat
    writeln('Testing program: ');
    writeln;
    writeln('1. Search.');
    writeln('2. Add.');
    writeln('3. Delete.');
    writeln;
    write('Choice: ');
    readln(c);
    case c of
      '1':
          begin
            write('Filename: ');
            readln(FileName);
            writeln(SearchFile(FileName));
          end;
      '2':
          begin
            write('Filename: ');
            readln(FileName);
            AFile.FileName := FileName;
            AddFile(AFile);
          end;
      '3':
          begin
            write('Filename: ');
            readln(FileName);
            DeleteFile(FileName);
          end;
    end;
  until (c = '0');
  close(DirFile);
end.
