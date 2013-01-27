{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

unit timefunc;

interface

{$IFDEF MSDOS}
  uses dos,overlay;
{$ELSE}
  uses dos;
{$ENDIF}

CONST
  SecondsPerYear        : ARRAY[FALSE..TRUE] OF LONGINT = (31536000,31622400);

  M31                   = 86400 * 31;
  M30                   = 86400 * 30;
  M28                   = 86400 * 28;

  SecondsPerMonth   : Array[1..12] of longint = (M31,M28,M31,M30,
                                            M31,M30,M31,M31,
                                            M30,M31,M30,M31);

  DayString:array[0..6] of string[9] =
              ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');

  MonthString:array [1..12] of string[9] =
              ('January','February','March','April','May','June',
               'July','August','September','October','November','December');

procedure packtodate(var t:datetime; s:longint);
function DatetoPack(var t:datetime):longint;
procedure getdatetime(var dt:datetime);
procedure getdayofweek(var dow:byte);
function getpackdatetime:longint;
function  ToDate8(Const SDate:String):String;
function pdt2dat(var pdt:longint; dow:byte):string;
function pd2date(pd:longint):string;
function date2pd(const sdate:string):longint;

implementation

procedure february(var year:word);
begin
  if (year mod 4 = 0) then SecondsPerMonth[2]:=29*86400
     else SecondsPerMonth[2]:=28*86400;
end;

procedure PacktoDate(var t:datetime; s:longint);
begin
  t.year:=1970;

  while (s < 0) do
    begin
      dec(t.year);
      inc(s, SecondsPerYear[(t.year mod 4 = 0)]);
    end;

  while (s >= SecondsPerYear[(t.year mod 4 = 0)]) do
    begin
      dec(s, SecondsPerYear[(t.year mod 4 = 0)]);
      inc(t.year);
    end;

  t.month := 1;
  february(t.year);
  while (s>=SecondsPerMonth[t.month]) do begin
    dec(s, SecondsPerMonth[t.month]);
    inc(t.month);
  end;
  t.day:=word(s div 86400)+1;
  s:=s mod 86400;
  t.hour:=word(s div 3600);
  s:=s mod 3600;
  t.min:=word(s div 60);
  t.sec:=word(s mod 60);
end;

function DatetoPack(var t:datetime):longint;
var n:word;
    s:longint;
begin
  s := 0;
  inc(s,longint(t.day-1)*86400);
  inc(s,longint(t.hour)*3600);
  inc(s,longint(t.min)*60);
  inc(s,longint(t.sec));

  february(t.year);

  for n := 1 to t.month - 1 do
    inc(s, SecondsPerMonth[n]);

  n := t.year;
  while (n <> 1970) do
    begin
      if (t.year > 1970) then
        begin
          dec(n);
          inc(s, SecondsPerYear[(n mod 4 = 0)]);
        end
      else
        begin
          inc(n);
          dec(s, SecondsPerYear[((n - 1) mod 4 = 0)]);
        end;
    end;

  DateToPack := s;
end;

procedure getdatetime(var dt:datetime);
var dow,hund:word;
begin
  getdate(dt.year,dt.month,dt.day,dow);
  gettime(dt.hour,dt.min,dt.sec,hund);
end;

function getpackdatetime:longint;
var
  dt:datetime;
begin
  getdatetime(dt);
  getpackdatetime := datetopack(dt);
end;

procedure getdayofweek(var dow:byte);
var y,m,d,dd:word;
begin
  getdate(y,m,d,dd);
  dow:=dd;
end;

function pd2date(pd:longint):string;
var
  dt:datetime;
  s:string[8];
  s2:string[4];
begin
  packtodate(dt,pd);
  str(dt.month,s2);
  if (length(s2) < 2) then
    s2 := '0' + s2;
  s := s2;
  str(dt.day,s2);
  if (length(s2) < 2) then
    s2 := '0' + s2;
  s := s + '-' + s2;
  str(dt.year,s2);
  pd2date := s + '-' + s2;
end;

function date2pd(const sdate:string):longint;
var
  dt:datetime;
  Junk:integer;
begin
  fillchar(dt,sizeof(dt),0);
  dt.sec := 1;
  val(copy(sdate,7,4),dt.year,Junk);
  val(copy(sdate,4,2),dt.day,Junk);
  val(copy(sdate,1,2),dt.month,Junk);
  if (dt.year = 0) then
    dt.year := 1;
  if (dt.month = 0) then
    dt.month := 1;
  if (dt.day = 0) then
    dt.day := 1;
  date2pd := datetopack(dt);
end;


function todate8(const sdate:string):string;
begin
  if (length(sdate) = 8) then
    todate8 := sdate
  else
    todate8 := copy(sdate,1,6)+copy(sdate,9,2);
end;


function pdt2dat(var pdt:longint; dow:byte):string;
var s,x:string[40];
    dt:datetime;
    i:integer;
    ispm:boolean;
begin
  packtodate(dt,pdt);
  with dt do begin
    i:=hour; ispm:=(i>=12);
    if (ispm) then
      if (i>12) then dec(i,12);
    if (not ispm) then
      if (i=0) then i:=12;
    str(i,x); s:=x+':';
    str(min,x); if (min<10) then x:='0'+x; s:=s+x+' ';
    if (ispm) then s:=s+'p' else s:=s+'a';
    s:=s+'m  '+
    copy(DayString[dow],1,3)+' '+
    copy(MonthString[month],1,3)+' ';
    str(day,x); s:=s+x+', ';
    str(year,x); s:=s+x;
  end;
  pdt2dat:=s;
end;

end.
