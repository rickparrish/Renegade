uses timefunc;

begin
  writeln('begin');
  writeln(date2pd('01/01/68'));
  writeln(date2pd('12/31/67'));
  writeln('done');
  writeln(date2pd('01/01/68') - date2pd('12/31/67'));
end.
