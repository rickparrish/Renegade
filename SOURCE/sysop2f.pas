{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ System Configuration - File Setup }

unit sysop2f;

interface

uses crt, dos, overlay, common;

procedure pofilesconfig;

implementation

procedure pofilesconfig;
var s:string[80];
    i:integer;
    c:char;
    b:byte;
    done:boolean;
begin
  done:=FALSE;
  repeat
    with general do begin
      cls;
      print('^5File section configuration'^M^J);

      abort:=FALSE;
      printacr('^1A. Upload/download ratio system    :^5'+onoff(uldlratio));
      printacr('^1B. File credit system              :^5'+onoff(filecreditratio));
      printacr('^1C. Daily download limits           :^5'+onoff(dailylimits));
      printacr('^1D. Test and convert uploads        :^5'+onoff(testuploads));
      printacr('^1E. Credit rewarding system         :^5'+onoff(rewardsystem));
      printacr('^1F. Search for/Use FILE_ID.DIZ      :^5'+onoff(filediz));
      printacr('^1G. Recompress like archives        :^5'+onoff(recompress));
      printacr('^1H. Credit reward compensation ratio:^5'+cstr(rewardratio)+'%');
      printacr('^1I. File credit compensation ratio  :^5'+cstr(filecreditcomp)+' to 1');
      printacr('^1J. Base file size per 1 file credit:^5'+cstr(filecreditcompbasesize)+'k');
      printacr('^1K. Upload time refund percent      :^5'+cstr(ulrefund)+'%');
            s:='^1L. "To-SysOp" file base            :^5';
      if (tosysopdir=255) then s:=s+'*None*' else s:=s+cstr(tosysopdir);
      printacr(s);
      printacr('^1M. Auto-validate ALL files ULed?   :^5'+syn(validateallfiles));
      printacr('^1N. Max k-bytes allowed in temp dir :^5'+cstr(general.maxintemp));
      printacr('^1O. Min k-bytes to save for resume  :^5'+cstr(general.minresume));
      prt(^M^J'Enter selection (A-O) [Q]uit : '); onek(c,'QABCDEFGHIJKLMNO'^M);
      nl;
      case c of
        'Q':done:=TRUE;
        'A':uldlratio:=not uldlratio;
        'B':filecreditratio:=not filecreditratio;
        'C':dailylimits:=not dailylimits;
        'D':testuploads:=not testuploads;
        'E':rewardsystem:=not rewardsystem;
        'F':filediz:=not filediz;
        'G':recompress:=not recompress;
        'H':begin
              prt('Percentage of file credits to reward: '); inu(i);
              if (not badini) then general.rewardratio:=i;
            end;
        'I'..'L':begin
              if (c<>'L') then prt('Range (0-255)') else
                prt('Range (1-'+cstr(MaxFBases)+')  (255 to disable)');
              prt(^M^J'New value: '); mpl(3); ini(b);
              if (not badini) then
                case c of
                  'I':filecreditcomp:=b;
                  'J':filecreditcompbasesize:=b;
                  'K':ulrefund:=b;
                  'L':if ((b>0) and (b<=MaxFBases)) or (b=255) then
                        tosysopdir:=b;
                end;
            end;
        'M':validateallfiles:=not validateallfiles;
        'N':begin
              prt('New max k-bytes: '); inu(i);
              if (not badini) then general.maxintemp:=i;
            end;
        'O':begin
              prt('New min resume k-bytes: '); inu(i);
              if (not badini) then general.minresume:=i;
            end;
      end;
    end;
  until (done) or (hangup);
end;

end.
