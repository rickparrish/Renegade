{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit msgpack;

interface

uses crt, dos, overlay,  common;

procedure packbase(fn : astr; maxm : longint);

implementation

uses mail0;

procedure packbase(fn : astr; maxm : longint);

var
    brdf1,brdf2 : file;
    buffer : array[1..4096] of char;
    msghdrf1,msghdrf2 : file of mheaderrec;
    mheader : mheaderrec;
    numm,i,idx,totload,buffered : word;
    needpack : boolean;

  procedure ohshit;
  begin
    sysoplog('error renaming temp files while packing.');
  end;

begin
  needpack := FALSE;
  fn := allcaps(fn);
  fn := general.msgpath + fn;

  assign(brdf1,fn+'.DAT');
  reset(brdf1,1);
  if (ioresult <> 0) then
    exit;

  assign(msghdrf1,fn+'.HDR');
  reset(msghdrf1);

  if ioresult<>0 then
     begin
       close(brdf1);
       exit
     end;

  if (maxm <> 0) and (filesize(msghdrf1) > maxm) then begin
    numm := 0;
    idx := filesize(msghdrf1);
    while (idx > 0) do
      begin
        seek(msghdrf1,idx - 1);
        read(msghdrf1,mheader);
        if not (mdeleted in mheader.status) then inc(numm);

        if (numm>maxm) and not (permanent in mheader.status) then
           begin
             mheader.status := [mdeleted];
             seek(msghdrf1,idx - 1);
             write(msghdrf1,mheader);
           end;

        dec(idx);
      end;
  end else
    begin

      while (filepos(msghdrf1) < filesize(msghdrf1)) and (not needpack) do
        begin
           read(msghdrf1,mheader);
           if mdeleted in mheader.status then needpack:=TRUE;
        end;

      if not needpack then
        begin
          close(msghdrf1);
          close(brdf1);
          exit;
        end;
    end;

  Lasterror := IOResult;

  assign(brdf2,fn+'.DA1');
  rewrite(brdf2,1);

  assign(msghdrf2,fn+'.HD2');
  rewrite(msghdrf2);

  kill(fn+'.HD3');
  kill(fn+'.DA3');

  Lasterror := IOResult;

  i := 0;
  idx := 1;

  while (i <= filesize(msghdrf1) - 1) do
    begin
      seek(msghdrf1,i);
      read(msghdrf1,mheader);

      if (mheader.pointer - 1 + mheader.textsize > filesize(brdf1)) or
         (mheader.pointer < 1) then mheader.status := [mdeleted];

      if not (mdeleted in mheader.status) then
        begin
          inc(idx);
          seek(brdf1,mheader.pointer - 1);
          mheader.pointer := filesize(brdf2) + 1;

          write(msghdrf2,mheader);

          totload := 0;
          if mheader.textsize > 0 then
            while (mheader.textsize>0) do
              begin
                buffered := mheader.textsize;
                if buffered > 4096 then buffered := 4096;
                dec(mheader.textsize,buffered);
                blockread(brdf1,buffer[1],buffered);
                blockwrite(brdf2,buffer[1],buffered);
                Lasterror := IOResult;
              end;
        end;
        inc(i);
    end;

  Lasterror := IOResult;
  close(brdf1);
  close(brdf2);
  close(msghdrf1);
  close(msghdrf2);

  rename(brdf1,fn+'.DA3');                     { rename .DAT to .DA3 }

  If (IOResult <> 0) then                      { Didn't work, abort  }
    begin
      ohshit;
      exit;
    end;

  rename(brdf2,fn+'.DAT');                     { Rename .DA2 to .DAT }

  If (IOResult <> 0) then                      { Didn't work, abort  }
    begin
      ohshit;
      rename(brdf1,fn+'.DAT');                 { Rename .DA3 to .DAT }
      exit;
    end;

  rename(msghdrf1,fn+'.HD3');                  { Rename .HDR to .HD3 }

  If (IOResult <> 0) then                      { Didn't work, abort  }
    begin
      ohshit;
      erase(brdf2);                            { Erase .DA2          }
      rename(brdf1,fn+'.DAT');                 { Rename .DA3 to .DAT }
      exit;
    end;

  rename(msghdrf2,fn+'.HDR');                  { Rename .HD2 to .HDR }

  If (IOResult <> 0) then                      { Didn't work, abort  }
    begin
      ohshit;
      erase(brdf2);                            { Erase .DAT (new)    }
      erase(msghdrf2);                         { Erase .HD2 (new)    }
      rename(brdf1,fn+'.DAT');                 { Rename .DA3 to .DAT }
      rename(msghdrf1,fn+'.HDR');              { Rename .HD3 to .HDR }
      exit;
    end;

  erase(msghdrf1);
  erase(brdf1);
  Lasterror := IOResult;
end;

end.
