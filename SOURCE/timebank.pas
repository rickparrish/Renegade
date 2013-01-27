{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Various miscellaneous functions used by the BBS. }

unit TimeBank;

interface

uses crt, dos, overlay, common;

procedure deposit(const s:astr);
procedure withdraw(const s:astr);

implementation

procedure deposit(const s:astr);
const
  MaxEver:word = 0;
  MaxPerDay:word = 0;
  Deposit:integer = 0;
begin
  if (s <> '') then
    MaxPerDay := value(s);
  if (pos(';',s)<>0) then
    MaxEver := value(copy(s,pos(';',s)+1,length(s)));
  nl;
  if ((thisuser.timebankadd>=maxperday) and (maxperday<>0)) or
     ((thisuser.timebank>=maxever) and (maxever<>0)) then
    begin
      print('You cannot deposit any more time.'^M^J);
      exit;
    end;
  print('^5In your account : ^3' + FormattedTime(longint(thisuser.timebank) * 60));
  print('^5Time left online: ^3' + FormattedTime(nsl));
  if (MaxEver > 0) then
    print('^5Max account size: ^3' + FormattedTime(MaxEver * 60));
  if (MaxPerDay > 0) then
    print('^5Max deposit/day : ^3' + FormattedTime(MaxPerDay * 60));
  if (thisuser.timebankadd <> 0) then
    print('^5Deposited today : ^3' + FormattedTime(thisuser.timebankadd * 60));
  prt(^M^J'Deposit how many minutes? '); inu(Deposit);
  nl;
  if (not badini) then
    if (Deposit>0) then
      if (Deposit * 60 > nsl) then
        print('^7You don''t have that much time left to deposit!')
      else
        if (Deposit + thisuser.timebankadd > maxperday) and (maxperday<>0) then
          print('^7You can only add '+cstr(maxperday)+' minutes to your account per day!')
        else
          if (Deposit+thisuser.timebank>maxever) and (maxever<>0) then
            print('^7Your account deposit limit is '+cstr(maxever)+' minutes!')
          else begin
            inc(thisuser.timebankadd,Deposit);
            inc(thisuser.timebank,Deposit);
            dec(thisuser.tltoday,Deposit);
            sysoplog('TimeBank: Deposited '+cstr(Deposit)+' minutes.');
          end;
end;

procedure withdraw(const s:astr);
var
  MaxWith:word;
  Withdrawal:integer;
begin
  MaxWith := value(s);
  nl;
  if (choptime <> 0) or ((thisuser.timebankwith >= MaxWith) and (MaxWith > 0)) then
    begin
      print('^7You cannot withdraw any more time during this call.');
      exit;
    end;

  print('^5In your account : ^3' + FormattedTime(longint(thisuser.timebank) * 60));
  print('^5Time left online: ^3' + FormattedTime(nsl));
  if (MaxWith > 0) then
    print('^5Max withdrawal  : ^3' + FormattedTime(MaxWith * 60));
  if (Thisuser.timebankwith > 0) then
    print('^5Withdrawn today : ^3' + FormattedTime(thisuser.timebankwith * 60));

  prt(^M^J'Withdraw how many minutes? '); inu(Withdrawal);
  nl;
  if (not badini) then
     if (Withdrawal > thisuser.timebank) then
         print('^7You don''t have that much time left in your account!')
     else
       if (Withdrawal + thisuser.timebankwith > maxwith) and (maxwith > 0) then
         print('^7You cannot withdraw that amount of time.')
       else
       if (Withdrawal > 0) then
         begin
           inc(thisuser.timebankwith,Withdrawal);
           if (thisuser.timebankadd >= Withdrawal) then
             dec(thisuser.timebankadd,Withdrawal)
           else
             thisuser.timebankadd:=0;
           dec(thisuser.timebank,Withdrawal);
           inc(thisuser.tltoday,Withdrawal);
           if timewarn and (nsl > 180) then
             timewarn := FALSE;
           sysoplog('TimeBank: Withdrew '+cstr(Withdrawal)+' minutes.');
         end;
end;
end.
