Renegade
========

[=========================]
[== Renegade BBS vY2Ka2 ==]
[=========================]
[ (c)2000, Jeff Herrings  ]
[                         ]
[ "HotFix" update to      ]
[ resolve RENEGADE's Y2K  ]
[ compliancy issues.      ]
[                         ]
[=========================]

==============================
Copyright Cott Lang, Patrick Spence, Gary Hall and Jeff Herrings<br />
Ported to Win32 by Rick Parrish<br />

<hr />

TODO list:<br />
<ul>
  <li>IFDEF out any ASM code blocks and handle the same as above</li>
  <li>Implement any REETODOs that appear in compiled executables</li>
  <li>WORD in RECORD to SMALLWORD</li>
  <li>INTEGER in RECORD to SMALLINT</li>
  <li>TYPEs of OF WORD to OF SMALLWORD (just in case they're used in a RECORD)</li>
  <li>TYPEs of OF INTEGER to OF SMALLINT (just in case they're used in a RECORD)</li>
  <li>Investigate FILEMODE usage to see if FILEMODEREADWRITE, TEXTMODEREAD or TEXTMODEREADWRITE should be used</li>
  <li>Find/correct any usage of FOR loop variables after the loop (since they are 1 greater in VP than in BP</li>
</ul>

Completed list<br />
<ul>
  <li>IFDEF out anything that doesn't compile and make a WIN32 placeholder that does a "WriteLn('REETODO UNIT FUNCTION'); Halt;" (then you can grep the executables for REETODO to see which REETODOs actually need to be implemented)</li>
</ul>
