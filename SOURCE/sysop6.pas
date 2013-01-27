{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Event Editor }

unit sysop6;

interface

uses crt, dos, overlay, common;

procedure eventedit;

implementation

uses sysop1;

procedure eventedit;
var evf:file of eventrec;
    i1,i2,ii:integer;
    c:char;
    s:astr;

  function dactiv(l:boolean; days:byte; b:boolean):astr;
  const dayss:string[7]='SMTWTFS';
  var s:astr;
      i,j:integer;
  begin
    if b then begin
      s:=cstr(days);
      if l then s:=s+' (monthly)' else s:=s+' mthly';
    end else begin
      s:='';
      for i:=1 to 7 do
        begin
          j := 1 shl i;
          if (days and j = j) then
            s:=s+dayss[i] else s:=s+'-';
        end;
    end;
    if not l then s:=mln(s,7);
    dactiv:=s;
  end;

  function schedt(l:boolean; c:char):astr;
  begin
    case c of
      'A':if (l) then schedt:='ACS restrict' else schedt:='ACS';
      'C':if (l) then schedt:='Chat event' else schedt:='Cht';
      'D':if (l) then schedt:='DOS shell' else schedt:='DOS';
      'E':if (l) then schedt:='External' else schedt:='Ext';
      'P':if (l) then schedt:='Pack msgs' else schedt:='Pak';
      'S':if (l) then schedt:='Sort files' else schedt:='Srt';
    end;
  end;

  procedure eed(i:integer);
  var x:integer;
  begin
    if (i>=1) and (i<=numevents) then begin
      dec(numevents);
      for x:=i to numevents do events[x]^:=events[x+1]^;
      rewrite(evf);
      for x:=1 to numevents do write(evf,events[x]^);
      close(evf);
      dispose(events[numevents+1]);   (* DISPOSE OF DYNAMIC MEMORY! *)
    end;
    Lasterror := IOResult;
  end;

  procedure eei(i:integer);
  var x:integer;
  begin
    if (i>=1) and (i<=numevents+1) and (numevents<maxevents) then begin
      inc(numevents);
      new(events[numevents]);         (* DEFINE DYNAMIC MEMORY! *)
      for x:=numevents downto i do events[x]^:=events[x-1]^;
      with events[i]^ do begin
        active:=FALSE;
        description:='<< Not Defined >>';
        etype:='D';
        execdata:='event.bat';
        offhooktime:=5;
        softevent:=TRUE;
        exectime:=0;
        busyduring:=TRUE;
        durationorlastday:=1;
        execdays:=0;
        missed:=TRUE;
        Enode:=0;
        monthly:=FALSE;
      end;
      rewrite(evf);
      for x:=1 to numevents do write(evf,events[x]^);
      close(evf);
    end;
    Lasterror := IOResult;
  end;

  procedure eem;
  var ii,i,j:integer;
      c:char;
      s:astr;
      bb:byte;
      changed:boolean;
  begin
    prt('Begin editing at which? (1-'+cstr(numevents)+') : '); inu(ii);
    c:=' ';
    if (ii>=1) and (ii<=numevents) then begin
      while (c<>'Q') and (not hangup) do begin
        with events[ii]^ do
          repeat
            if (c<>'?') then begin
              cls;
              abort:=FALSE; next:=FALSE;
              printacr('^5Event #'+cstr(ii)+' of '+cstr(numevents) + ^M^J);
              printacr('^1!. Active       : ^5' + syn(active));
              printacr('^11. Description  : ^5' + description);
              printacr('^12. Sched. type  : ^5' + schedt(TRUE,etype));
              printacr('^13. Event data   : ^5' + execdata);
              printacr('^14. Off hook time: ^5' +
                    aonoff((offhooktime<>0),cstr(offhooktime)+' minutes','None.'));
              printacr('^15. Exec. time   : ^5' + copy(ctim(exectime),4,5));
              printacr('^16. Busy during  : ^5' + syn(busyduring));
              printacr('^17. Soft event   : ^5' + syn(softevent));
              printacr('^18. Run if missed: ^5' + syn(missed));
              if (etype in ['A','C']) then printacr('^19. Duration     : ^5' + cstr(durationorlastday))
                 else begin
                    if daynum(date)-durationorlastday=0 then s:='Today'
                       else s:=cstr(daynum(date)-durationorlastday)+' day(s) ago';
                    printacr('^19. Last day exec: ^5' + s);
                 end;
              printacr('^1A. Days active  : ^5' + dactiv(TRUE,execdays,monthly));
              printacr('^1B. Node number  : ^5' + cstr(Enode));
            end;
            prt(^M^J'Edit menu (?=help) : ');
            onek(c,'Q!123456789AB[]FJL?'^M);
            nl;
            case c of
              'B':begin
                    prt('Node number to execute event from (0=All) : ');
                    inu(i);
                    if not badini then Enode:=i;
                  end;
              '!':active:=not active;
              '1':begin
                    prt('New description: ');
                    mpl(30); inputwn(description,30,changed);
                  end;
              '2':begin
                    prt('New schedule type? [ACDEPS] : ');
                    onek(c,'QACDEPS'^M);
                    if (pos(c,'ACDEPS')<>0) then etype:=c;
                  end;
              '3':begin
                    case etype of
                        'A':print('^5ACS event: ACS string required of callers');
                        'C':print('^5Chat call: 0=Off, 1=On');
                        'D':print('^5DOS event: Dos commandline');
                        'E':print('^5External: errorlevel to exit with');
                        'P':print('^5Pack message bases. No options.');
                        'S':print('^5Sort file bases. No options.');
                    end;
                    prt(^M^J'New data: ');
                    mpl(20); inputwn(execdata,20,changed);
                  end;
              '4':begin
                    prt('New busy time (0 for none) : ');
                    inu(i);
                    if not badini then offhooktime:=i;
                  end;
              '5':begin
                    print('^5All entries in 24 hour time.  Hour: (0-23), Minute: (0-59)'^M^J);

                    prompt('New event time:');
                    prt('  Hour   : '); mpl(5); inu(i);
                    if not badini then begin
                      if (i<0) or (i>23) then i:=0;
                      prt('                 Minute : '); mpl(5); inu(j);
                      if not badini then begin
                        if (j<0) or (j>59) then j:=0;
                        exectime:=i*60+j;
                      end;
                    end;
                  end;
              '6':begin
                    nl;
                    busyduring:=pynq('Take the phone off the hook for this event? ');
                  end;
              '7':begin
                    nl;
                    softevent:=not pynq('Would you like this event to disconnect the user and run immediately? ');
                  end;
              '8':begin
                    nl;
                    missed:=pynq('Run this event later if the event time is missed? ');
                  end;
              '9':begin
                    if (etype in ['A','C']) then prt('New duration: ')
                       else prt('Number of days since last execution: ');
                    mpl(5); inu(i);
                    if not badini then begin
                       if (etype in ['A','C']) then durationorlastday:=i
                          else durationorlastday:=daynum(date)-i;
                    end;
                  end;
              'A':begin
                    if monthly then c:='M' else c:='W';
                    prt('[W]eekly or [M]onthly? ['+c+'] : ');
                    onek(c,'QWM'^M);
                    if c in ['M','W'] then monthly:=(c='M');
                    if c='M' then execdays:=1;
                    if monthly then begin
                      prt(^M^J'What day of the month? (1-31) ['+cstr(execdays)+'] : ');
                      mpl(3); ini(bb);
                      if not badini then
                        if bb in [1..31] then execdays:=bb;
                    end else begin
                      print(^M^J'^5Current: '+dactiv(TRUE,execdays,FALSE) + ^M^J);
                      print('Modify by entering an "X" under days active.');
                      prt('[SMTWTFS]');
                      prt(^M^J':'); mpl(7); input(s,7);
                      if s<>'' then begin
                        bb:=0;
                        for i:=1 to length(s) do
                          if s[i]='X' then
                            inc(bb,1 shl i);
                        execdays:=bb;
                      end;
                    end;
                  end;
              '[':if (ii>1) then dec(ii) else c:=' ';
              ']':if (ii<numevents) then inc(ii) else c:=' ';
              'F':if (ii<>1) then ii:=1 else c:=' ';
              'J':begin
                    prt('Jump to entry: ');
                    input(s,3);
                    if (value(s)>=1) and (value(s)<=numevents) then ii:=value(s) else c:=' ';
                  end;
              'L':if (ii<>numevents) then ii:=numevents else c:=' ';
              '?':ee_help;
            end;
          until ((c in ['Q','[',']','F','J','L']) or (hangup));
      end;
      reset(evf);
      for ii:=1 to numevents do write(evf,events[ii]^);
      close(evf);
    end;
    Lasterror := IOResult;
  end;

  procedure eep;
  var i,j,k:integer;
  begin
    prt('Move which event? (1-'+cstr(numevents)+') : '); inu(i);
    if ((not badini) and (i>=1) and (i<=numevents)) then begin
      prt('Move before which event? (1-'+cstr(numevents+1)+') : '); inu(j);
      if ((not badini) and (j>=1) and (j<=numevents+1) and
          (j<>i) and (j<>i+1)) then begin
        eei(j);
        if (j>i) then k:=i else k:=i+1;
        events[j]^:=events[k]^;
        if (j>i) then eed(i) else eed(i+1);
      end;
    end;
  end;

begin
  assign(evf,general.datapath+'events.dat');
  c:=#0;
  repeat
    if c<>'?' then begin
      cls; abort:=FALSE;
      printacr('^3 NN'+seperator+'Description                   '+
               seperator+'Typ'+seperator+'Bsy'+seperator+'Time '+seperator+'Len'+seperator+'Days   '+
               seperator+'Execinfo');
      printacr('^4 ==:==============================:===:===:=====:===:=======:============');
      ii:=1;
      while (ii<=numevents) and (not abort) do
        with events[ii]^ do begin
          if (active) then
            s := '^5+'
          else
            s := '^1-';
          s:=s + '^0' + mn(ii,2)+' ^3'+mln(description,30)+' '+
              schedt(FALSE,etype)+' ^5'+
              mn(offhooktime,3)+' '+copy(ctim(exectime),4,5)+' '+
              mn(durationorlastday,3)+' '+dactiv(FALSE,execdays,monthly)+' ^3'+
              mln(execdata,9);
          printacr(s);
          inc(ii);
        end;
    end;
    prt(^M^J'Event editor (?=help) : ');
    onek(c,'QDIMP?'^M);
    case c of
      '?':begin
            print(^M^J'<^3CR^1>Redisplay screen');
            lcmds(13,3,'Delete event','Insert event');
            lcmds(13,3,'Modify event','Position event');
            lcmds(13,3,'Quit','');
          end;
      'D':begin
            prt('Event to delete? (1-'+cstr(numevents)+') : '); inu(ii);
            if (ii>=1) and (ii<=numevents) then begin
              print(^M^J'Event: ^4' + events[ii]^.description);
              if pynq('Delete this? ') then begin
                sysoplog('* Deleted event: '+events[ii]^.description);
                eed(ii);
              end;
            end;
          end;
      'I':if (numevents >= maxevents) then
            print('You already have the maximum number of events.')
          else
            begin
              prt('Event to insert before? (1-'+cstr(numevents+1)+') : '); inu(ii);
              if (ii>=1) and (ii<=numevents+1) then begin
                sysoplog('* Created event');
                eei(ii);
              end;
          end;
      'M':eem;
      'P':eep;
    end;
  until (c='Q') or (hangup);
  Lasterror := IOResult;
end;

end.
