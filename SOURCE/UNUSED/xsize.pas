uses crt, dos;

type
string10=String[10];
string8=String[8];
string50=string[50];
string12=string[12];
string20=string[20];
string30=string[30];
string40=string[40];



begin
writeln ('Boolean...... ',SizeOf(Boolean));
writeln ('Byte......... ',SizeOf(Byte));
writeln ('Char......... ',SizeOf(Char));
writeln ('Word......... ',SizeOf(Word));
writeln ('String[10]... ',SizeOf(String10));
writeln ('String[40]... ',SizeOf(String40));
writeln ('String[12]... ',SizeOf(String12));
writeln ('String[08]... ',SizeOf(String8));
writeln ('String[20]... ',SizeOf(String20));
writeln ('String[30]... ',SizeOf(String30));
writeln ('String[50]... ',SizeOf(String50));
end.

