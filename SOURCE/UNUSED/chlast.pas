

{$I records.pas}


var
general:file of generalrec;
onegeneral:generalrec;

begin

assign (general, 'C:\CA\RENEGADE.DAT');
reset (general);
seek (general, 0);
read (general, onegeneral);
onegeneral.lcallinlogon:=false;
seek (general, 0);
write (general, onegeneral);
close (general);
end.

