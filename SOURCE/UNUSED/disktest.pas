Program DiskTest;
uses
  dffix;

begin

  Writeln('Disk free (0) is: ', diskkbfree(0));
  Writeln('Disk free (3) is: ', diskkbfree(3));
  Writeln('Disk free (4) is: ', diskkbfree(4));

  Writeln('Disk free in KB (0) is: ', diskfreeinkb(0));
  Writeln('Disk free in KB (3) is: ', diskfreeinkb(3));
  Writeln('Disk free in KB (4) is: ', diskfreeinkb(4));

end.
