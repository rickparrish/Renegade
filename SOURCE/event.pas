{$IFDEF WIN32}
{$I DEFINES.INC}
{$ENDIF}
{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Event related functions }

unit Event;

interface

uses crt, dos, overlay, common;

function checkeventday(i:integer; t:longint):boolean;
function checkpreeventtime(i:integer; t:longint):boolean;
function checkeventtime(i:integer; t:longint):boolean;
function checkevents(t:longint):integer;
function sysopavailable:boolean;

implementation

{$IFDEF WIN32}
uses Windows;
{$ENDIF}
function sysopavailable:boolean;
var
{$IFDEF MSDOS}
  a:byte absolute $0000:$0417;
{$ENDIF}
  i:integer;
begin
{$IFDEF MSDOS}
  sysopavailable:=((a and 16)=0);
{$ENDIF}
{$IFDEF WIN32}
  // Availability is togged with scroll lock key
  sysopavailable := (GetKeyState($91) and $ffff) <> 0;
{$ENDIF}  

  if (not intime(timer,general.lowtime,general.hitime)) then
    sysopavailable:=FALSE;

  if (rchat in thisuser.flags) then
    sysopavailable:=FALSE;

  for i:=1 to numevents do
    with events[i]^ do
      if (etype='C') and (active) and (checkeventtime(i,0)) then
        if value(events[i]^.execdata)=1 then
          sysopavailable:=TRUE
        else
          sysopavailable:=FALSE;
end;

function checkeventday(i:integer; t:longint):boolean;
var
  year,month,day,dayofweek:word;
  e:integer;
begin
  e:=0;
  checkeventday:=FALSE;
  if not events[i]^.active then exit;
  with events[i]^ do begin
    getdate(year,month,day,dayofweek);
    if (timer+t>=86400.0) then begin
      inc(dayofweek); e:=1;
      if (dayofweek>6) then dayofweek:=0;
    end;
    if (monthly) then begin
      if (value(copy(date,4,2))+e=execdays) then
        checkeventday:=TRUE;
    end else begin
      e := 1 shl (dayofweek + 1);
      if (execdays and e = e) then
        checkeventday:=TRUE;
    end;
  end;
end;

function checkpreeventtime(i:integer; t:longint):boolean;
begin
  with events[i]^ do
    if (offhooktime = 0) or
       (durationorlastday=daynum(date)) or
       ((Enode > 0) and (Enode <> node)) or
       (not events[i]^.active) or not
       (checkeventday(i,t)) then
      checkpreeventtime:=FALSE
    else
      checkpreeventtime:=intime(timer+t,exectime-offhooktime,exectime);
end;

function checkeventtime(i:integer; t:longint):boolean;
begin
  with events[i]^ do
    if (durationorlastday=daynum(date)) or
       ((Enode > 0) and (Enode <> node)) or
       (not events[i]^.active) or not
       (checkeventday(i,t)) then
      checkeventtime:=FALSE
    else
      if (etype in ['A','C']) then
        checkeventtime:=intime(timer+t,exectime,exectime+durationorlastday)
      else
        if (missed) then
          checkeventtime := (((timer + t) div 60) > exectime)
        else
          checkeventtime := (((timer + t) div 60) = exectime);
end;

function checkevents(t:longint):integer;
var i:integer;
begin
  for i := 1 to numevents do
    with events[i]^ do
      if (active) and ((Enode = 0) or (Enode = node)) then
        if (checkeventday(i,t)) then begin
           if (softevent) and (not inwfcmenu) then
             checkevents:=0
           else
             checkevents:=i;
           if (checkpreeventtime(i,t)) or (checkeventtime(i,t)) then begin
             if (etype in ['D','E','P']) then exit;
             if ((etype='A') and (not aacs(execdata)) and (useron)) then exit;
           end;
        end;
  checkevents:=0;
end;

end.
