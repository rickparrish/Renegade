{$A+,B-,D-,E-,F+,I-,L-,N-,O+,R-,S+,V-}

{ Door procedures }

unit doors;

interface

uses crt, dos, overlay, common, timefunc;

procedure dodoorfunc(kind:char; cline:astr);

implementation

uses execbat, event;

procedure write_pcboard_sys(rname:boolean);
var fp:file;
    s:string[50];
    un:string[50];
    i:integer;

procedure dump(x:string);
begin
  blockwrite(fp,x[1],length(x));
end;

procedure write_boolean(x:boolean);
begin
  if x then s:='-1' else s:=' 0';
  dump(s);
end;

begin
  if rname then un:=thisuser.realname else un:=thisuser.name;
  assign(fp,liner.doorpath+'pcboard.sys');
  rewrite(fp,1);
  write_boolean(wantout);
  write_boolean((general.slogtype in [1,2]));
  write_boolean(sysopavailable);
  dump(' 0 ');
  write_boolean(Reliable);
  if (okansi or okavatar) then dump('Y') else dump('N');
  dump('A');
  s := cstr(speed);
  s:=mln(s,5);
  dump(s);
  if (Speed = 0) then
    dump('Local')
  else
    dump(mn(Speed,5));
  blockwrite(fp,usernum,2);
  dump(mln(copy(un,1,pos(' ',un)-1),15));
  dump(mln('PASSWORD', 12));
  i:=0;
  blockwrite(fp,i,2);
  blockwrite(fp,i,2);
  s:='00:00';
  blockwrite(fp,s[1],5);
  i:=general.timeallow[thisuser.sl];
  blockwrite(fp,i,2);
  i:=general.dlkoneday[thisuser.sl];
  blockwrite(fp,i,2);
  s:=#0#0#0#0#0#0;
  dump(s);
  dump(copy(s,1,5));
  i:=0;
  blockwrite(fp,i,2);
  blockwrite(fp,i,2);
  dump('    ');
  dump(mln(un,25));
  i:=nsl div 60;
  blockwrite(fp,i,2);
  dump(chr(node)+'00:00');
  write_boolean(FALSE);
  write_boolean(FALSE);
  dump(#0#0#0#0);
  if (Speed = 0) then
    s := '0'
  else
    s := cstr(liner.comport);
  s:=s[1]+#0#0;
  if (okansi or okavatar) then s:=s+#1 else s:=s+#0;
  dump(s);
  dump(date);
  i:=0;
  blockwrite(fp,i,2);
  dump(#0#0#0#0#0#0#0#0#0#0);
  close(fp);
  Lasterror := IOResult;
end;

procedure write_dorinfo1_def(rname:boolean);  (* RBBS-PC's DORINFO1.DEF *)
var fp:text;
    first,last:astr;
    s:astr;
begin
  assign(fp,liner.doorpath+'dorinfo1.def');
  rewrite(fp);
  writeln(fp,stripcolor(general.bbsname));
  first:=copy(general.sysopname,1,pos(' ',general.sysopname)-1);
  last:=sqoutsp(copy(general.sysopname,length(first)+1,length(general.sysopname)));
  writeln(fp,first);
  writeln(fp,last);
  if (Speed = 0) then
    writeln(fp, 'COM0')
  else
    writeln(fp, 'COM', liner.comport);
  s := cstr(Speed);
  writeln(fp,s+' BAUD,N,8,1');
  writeln(fp,'0');
  if (rname) then begin
    if pos(' ',thisuser.realname)=0 then begin
      first:=thisuser.realname;
      last:='';
    end else begin
      first:=copy(thisuser.realname,1,pos(' ',thisuser.realname)-1);
      last:=copy(thisuser.realname,length(first)+2,length(thisuser.realname));
    end;
  end else begin
    if pos(' ',thisuser.name)=0 then begin
      first:=thisuser.name;
      last:='';
    end else begin
      first:=copy(thisuser.name,1,pos(' ',thisuser.name)-1);
      last:=copy(thisuser.name,length(first)+2,length(thisuser.name));
    end;
  end;
  writeln(fp,allcaps(first));
  writeln(fp,allcaps(last));
  writeln(fp,thisuser.citystate);
  if (okansi or okavatar) then writeln(fp,'1') else writeln(fp,'0');
  writeln(fp,thisuser.sl);
  writeln(fp, nsl div 60);
  writeln(fp,'0');
  close(fp);
  Lasterror := IOResult;
end;

procedure write_door_sys(rname:boolean);    (* GAP's DOOR.SYS *)
var fp:text;
    i:integer;
    s:astr;
begin
  assign(fp,liner.doorpath+'door.sys');
  rewrite(fp);
  if (Speed > 0) then
    writeln(fp, 'COM', liner.comport,':')
  else
    writeln(fp, 'COM0:');
  writeln(fp, ActualSpeed);
  writeln(fp,'8');
  writeln(fp,node);
  writeln(fp, Speed);
  if wantout then writeln(fp,'Y') else writeln(fp,'N');
  writeln(fp,'N');
  if (sysopavailable) then
    writeln(fp,'Y')
  else
    writeln(fp,'N');
  if alert in thisuser.flags then
    writeln(fp,'Y')
  else
    writeln(fp,'N');
  if (rname) then writeln(fp,thisuser.realname) else writeln(fp,thisuser.name);
  writeln(fp,thisuser.citystate);
  writeln(fp,copy(thisuser.ph,1,3)+' '+copy(thisuser.ph,5,8));
  writeln(fp,copy(thisuser.ph,1,3)+' '+copy(thisuser.ph,5,8));
  writeln(fp,'PASSWORD');
  writeln(fp,thisuser.sl);
  writeln(fp,thisuser.loggedon);
  writeln(fp, todate8(pd2date(thisuser.laston)));
  writeln(fp,nsl);
  writeln(fp,nsl div 60);
  if (okRip) then writeln(fp, 'RIP')
    else
      if (okansi or okavatar) then writeln(fp,'GR') else writeln(fp,'NG');
  writeln(fp,thisuser.pagelen);
  if novice in thisuser.flags then writeln(fp,'N') else writeln(fp,'Y');
  s:='';
  for i:=1 to 7 do
    if chr(i+64) in thisuser.ar then s:=s+cstr(i);
  writeln(fp,s);
  writeln(fp,'7');
	writeln(fp,'12/31/99');
  writeln(fp,usernum);
  writeln(fp,'Z');
  writeln(fp,thisuser.uploads);
  writeln(fp,thisuser.downloads);
  writeln(fp,thisuser.dlktoday);
  writeln(fp,'999999');
  writeln(fp, todate8(pd2date(thisuser.birthdate)));
  writeln(fp, '\');
  writeln(fp, '\');
  writeln(fp, general.sysopname);
  writeln(fp, thisuser.name);
  writeln(fp, '00:00');
  writeln(fp, copy(syn(Reliable),1,1));
  writeln(fp, 'N');
  writeln(fp, copy(syn(general.multinode),1,1));
  writeln(fp, '3');
  writeln(fp, '0');
  writeln(fp, newdate);
  writeln(fp, time);
  writeln(fp, '00:00');
  writeln(fp, general.dloneday[thisuser.sl]);
  writeln(fp, thisuser.dltoday);
  writeln(fp, thisuser.uk);
  writeln(fp, thisuser.dk);
  writeln(fp, thisuser.note);
  writeln(fp, '0');
  writeln(fp, '10');
  close(fp);
  Lasterror := IOResult;
end;

procedure write_chain_txt;
var fp:text;
    tused:longint;
    s:string[20];

  function bo(b:boolean):astr;
  begin
    if b then bo:='1' else bo:='0';
  end;

begin
  assign(fp,liner.doorpath+'chain.txt');
  rewrite(fp);
  with thisuser do begin
    writeln(fp,usernum);                      { user number        }
    writeln(fp,name);                         { user name          }
    writeln(fp,realname);                     { real name          }
    writeln(fp,'');                           { "call sign" ?      }
    writeln(fp,ageuser(Birthdate));           { age                }
    writeln(fp,sex);                          { sex                }
    writeln(fp,'00.00');                      { credit             }
    writeln(fp, todate8(pd2date(laston)));    { laston date        }
    writeln(fp,linelen);                      { # screen columns   }
    writeln(fp,pagelen);                      { # screen rows      }
    writeln(fp,sl);                           { SL                 }
    writeln(fp,bo(so));                       { is he a SysOp?     }
    writeln(fp,bo(CoSysOp));                  { is he a CoSysOp?   }
    writeln(fp,bo(okansi or okavatar));       { is graphics on?    }
    writeln(fp,bo(incom));                    { is remote?         }
    str(nsl:10,s); writeln(fp,s);             { time left (sec)    }
    writeln(fp,general.datapath);             { gfiles path        }
    writeln(fp,general.datapath);             { data path          }
    writeln(fp,'SYSOP.LOG');                  { SysOp log filespec }
    s := cstr(speed);
    writeln(fp,s);
    writeln(fp,liner.comport);                { COM port           }
    writeln(fp,stripcolor(general.bbsname));  { system name        }
    writeln(fp,general.sysopname);            { SysOp's name       }
    writeln(fp,getpackdatetime - timeon);     { secs on f/midnight }
    writeln(fp,tused);                        { time used (sec)    }
    writeln(fp,uk);                           { upload K           }
    writeln(fp,uploads);                      { uploads            }
    writeln(fp,dk);                           { download K         }
    writeln(fp,downloads);                    { downloads          }
    writeln(fp,'8N1');                        { COM parameters     }
  end;
  close(fp);
  Lasterror := IOResult;
end;

procedure write_callinfo_bbs(rname:boolean);
var fp:text;
		s:astr;

  function bo(b:boolean):astr;
  begin
    if b then bo:='1' else bo:='0';
  end;

begin
  assign(fp,liner.doorpath+'callinfo.bbs');
  rewrite(fp);
  with thisuser do begin
    if (rname) then writeln(fp,allcaps(thisuser.realname)) else writeln(fp,allcaps(thisuser.name));
    if (Speed = 300) then
      s := '1'
    else
      if (Speed = 1200) then
        s := '2'
      else if (Speed = 2400) then
        s := '0'
      else if (Speed = 9600) then
        s := '3'
      else if (Speed = 0) then
        s := '5' else
      s := '4';
    writeln(fp,s);
    writeln(fp,allcaps(thisuser.citystate));
    writeln(fp,thisuser.sl);
    writeln(fp, nsl div 60);
    if (okansi or okavatar) then writeln(fp,'COLOR') else writeln(fp,'MONO');
    writeln(fp, 'PASSWORD');
    writeln(fp,usernum);
    writeln(fp,'0');
    writeln(fp,copy(time,1,5));
    writeln(fp,copy(time,1,5)+' '+date);
    writeln(fp,'A');
    writeln(fp,'0');
    writeln(fp,'999999');
    writeln(fp,'0');
    writeln(fp,'999999');
    writeln(fp,thisuser.ph);
    writeln(fp, todate8(pd2date(thisuser.laston))+' 00:00');
    if (novice in thisuser.flags) then writeln(fp,'NOVICE') else writeln(fp,'EXPERT');
    writeln(fp,'All');
    writeln(fp,'01/01/80');
    writeln(fp,thisuser.loggedon);
    writeln(fp,thisuser.pagelen);
    writeln(fp,'0');
    writeln(fp,thisuser.uploads);
    writeln(fp,thisuser.downloads);
    writeln(fp,'8  { Databits }');
    if ((incom) or (outcom)) then writeln(fp,'REMOTE') else writeln(fp,'LOCAL');
    if ((incom) or (outcom)) then writeln(fp,'COM',liner.comport) else writeln(fp,'COM0');
    writeln(fp, (pd2date(thisuser.birthdate)));
    writeln(fp, Speed);
    if ((incom) or (outcom)) then writeln(fp,'TRUE') else writeln(fp,'FALSE');
    if (Reliable) then write(fp,'MNP/ARQ') else write(fp,'Normal');
    writeln(fp,' Connection');
    writeln(fp,'12/31/99 23:59');
    writeln(fp, Node);
    writeln(fp,'1');
  end;
  close(fp);
  Lasterror := IOResult;
end;

procedure write_sfdoors_dat(rname:boolean);   { Spitfire SFDOORS.DAT }
var fp:text;
    s:astr;
begin
  assign(fp,liner.doorpath+'SFDOORS.DAT');
  rewrite(fp);
  writeln(fp,usernum);
  if (rname) then
    writeln(fp,allcaps(thisuser.realname))
  else
    writeln(fp,allcaps(thisuser.name));
  writeln(fp, 'PASSWORD');
  if (rname) then begin
    if (pos(' ',thisuser.realname)=0) then s:=thisuser.realname
    else s:=copy(thisuser.realname,1,pos(' ',thisuser.realname)-1);
  end else begin
    if (pos(' ',thisuser.name)=0) then s:=thisuser.name
    else s:=copy(thisuser.name,1,pos(' ',thisuser.name)-1);
  end;
  writeln(fp,s);
  writeln(fp, Speed);
  if (Speed = 0) then
    writeln(fp,'0')
  else
    writeln(fp,liner.comport);
  writeln(fp, nsl div 60);
  writeln(fp,timer);   { seconds since midnight }
  writeln(fp,start_dir);
  if (okansi or okavatar) then writeln(fp,'TRUE') else writeln(fp,'FALSE');
  writeln(fp,thisuser.sl);
  writeln(fp,thisuser.uploads);
  writeln(fp,thisuser.downloads);
  writeln(fp,general.timeallow[thisuser.sl]);
  writeln(fp,'0');   { time on (seconds) }
  writeln(fp,'0');   { extra time (seconds) }
  writeln(fp,'FALSE');
  writeln(fp,'FALSE');
  writeln(fp,'FALSE');
  writeln(fp,liner.InitBaud);
  if Reliable then
    writeln(fp,'TRUE')
  else
    writeln(fp,'FALSE');
  writeln(fp,'A');
  writeln(fp,'A');
  writeln(fp,node);
  writeln(fp,general.dloneday[thisuser.sl]);
  writeln(fp,thisuser.dltoday);
  writeln(fp,general.dlkoneday[thisuser.sl]);
  writeln(fp,thisuser.dlktoday);
  writeln(fp,thisuser.uk);
  writeln(fp,thisuser.dk);
  writeln(fp,thisuser.ph);
  writeln(fp,thisuser.citystate);
  writeln(fp,general.timeallow[thisuser.sl]);
  close(fp);
  Lasterror := IOResult;
end;

procedure dodoorfunc(kind:char; cline:astr);
var
    DoorTime:longint;
    s:astr;
    OldActivity,retcode:byte;
    oldavailable,realname:boolean;
    u:userrec;
begin
  realname:=FALSE;
  if (cline = '') and (incom) then exit;

  saveurec(thisuser, usernum);

  if copy(allcaps(cline),1,2)='R;' then begin
    realname:=TRUE;
    cline:=copy(cline,3,length(cline)-2);
  end;
  s:=FunctionalMCI(cline,'','');
  case kind of
    'P':begin
          status_screen(100,'Outputting PCBOARD.SYS ...',FALSE,s);
          write_pcboard_sys(realname);
        end;
    'C':begin
          status_screen(100,'Outputting CHAIN.TXT ...',FALSE,s);
          write_chain_txt;
        end;
    'D':begin
          status_screen(100,'Outputting DORINFO1.DEF ...',FALSE,s);
          write_dorinfo1_def(realname);
        end;
    'G':begin
          status_screen(100,'Outputting DOOR.SYS ...',FALSE,s);
          write_door_sys(realname);
        end;
    'S':begin
          status_screen(100,'Outputting SFDOORS.DAT ...',FALSE,s);
          write_sfdoors_dat(realname);
        end;
    'W':begin
          status_screen(100,'Outputting CALLINFO.BBS ...',FALSE,s);
          write_callinfo_bbs(realname);
        end;
  end;
  if (s = '') then exit;
  shel('Running "'+s+'"');
  sysoplog('Opened door ' + s + ' on '+date+' at '+time);

  loadnode(node);
  OldActivity := noder.activity;
  OldAvailable := Navail in noder.status;
  noder.status := noder.status - [NAvail];
  if (noder.activity < 255) then
    noder.activity := 2;
  savenode(node);

  DoorTime := getpackdatetime;
  shelldos(FALSE,s,retcode);
  DoorTime := getpackdatetime - DoorTime;
  shel2(FALSE);
  loadnode(node);
  noder.activity := OldActivity;
  if OldAvailable then
    noder.status := noder.status + [NAvail];
  savenode(node);
  reset(uf);
  seek(uf,usernum);
  read(uf,thisuser);
  newcomptables;
  close(uf);

  chdir(start_dir);

  com_flush_rx;

  sysoplog('Returned on '+date+' at '+time+'. Spent ' + FormattedTime(DoorTime));
end;

end.
