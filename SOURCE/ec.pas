uses crt;

var verline:array [0..3] of string;
    s3:string;
    f:text;
    i:byte;
    loop:integer;

function encrypt(s:string):string;
var b:byte;
   s2:string;
    t:byte;
begin
  s2:='';
  s2[0] := s[0]; t := 0;
  for b:=1 to length(s) do
    begin
      s2[b] := chr(ord(s[b]) + ord(s2[b-1]));
      inc(t, ord(s2[b]));
    end;
  writeln('Total: ',t);
  encrypt:=s2;
end;

function decrypt(s:string):string;
var b:byte;
   s2:string;
begin
  s2:='';
  for b:=1 to length(s) do
    s2:=s2+chr(ord(s[b]) - ord(s[b-1]));
  decrypt:=s2;
end;

begin
  clrscr;
   {verline[0]:='|03The |11Renegade Bulletin Board System|03 Version ';
   verline[1]:='|03Copyright (C)MCMXCI-MCMXCVI by |11Cott Lang|03. All Rights Reserved.';
   verline[2]:='|03Copyright (C)MCMXCVII-MCMXCIX by |11Patrick Spence |03and |11Gary Hall|03. All Rights Reserved.';}
   verline[3]:='|09Copyright (C)MM by Jeff Herrings. All Rights Reserved.';
  {verline:='--- Renegade v';}
  assign(f,'ec.txt');
  s3:='';
  rewrite(f);
{   for loop := 0 to 3 do
     begin}
       writeln(verline[3]);
       writeln(f,verline[3]);
       s3:=encrypt(verline[3]);
       writeln(s3);
       writeln(f,s3);
{     end;}
  close(f);
end.

