{ M 65520,0,655360}
{$M 35500,0,131072}
(*
  Experimenting with more memory
*)
{ M 35500,0,86000}      { Memory Allocation Sizes }
                        { Heap is tight, stack is ?? }
{                             R E N E G A D E                                  }
{                             ===============                                  }

{ A+,B-,D-,E-,F+,I-,L+,N-,O-,R-,S+,V-}
{$A+ Align Data for faster execution}
{$B- Shortcut boolean eval}
{$D- No Debug Info}
{$E- No Math-Co library}
{$F+ Force Far Calls}
{$G+ Enable 286+ processing }
{$I- Disable brain dead I/O check}
{$L+ Local Symbols, Ignored if D-}
{$N- No Math-Co use}
{ O- Use Overlays?}
{$O+ Use Overlays?}
{$P+ Allow OpenString }
{$Q- No overflow check }
{$R- No Brain-Dead range check}
{$S+ Check stack usage}
{$V- Variable String length allowed}
{$X+ Allow extended syntax}

Program Renegade;
Uses
  is286,
  Crt,      Dos,      OverLay,  Boot,    Sysop1,   Sysop2,   Sysop3,
  Sysop4,   Sysop6,   Sysop7,   Sysop8,   Sysop9,   Sysop10,
  Sysop11,  Mail0,    Mail1,    Email,    Mail5,    Nodelist, SysChat,
  Mail6,    Mail7,    Arcview,  File0,    File1,    File2,    BBSList,
  File5,    File6,    File8,    File9,    File10,   File11,   Multnode,
  File12,   File13,   File14,   Archive1, Archive2, Archive3, TimeBank,
  Bulletin, User,     ShortMsg, CUser,    Doors,    Menus2,
  Menus3,   Menus4,   MyIO,     Logon,    Maint,    NewUsers, WfcMenu,
  Menus,    Timefunc, MsgPack,  Common,   Common1,  Common2,  offline,
  Common3,  Spawno,   vote,     Script,   Event;

{$O MsgPack   } {$O Common1   } {$O Common2   } {$O Common3   } {$O Boot      }
{$O WfcMenu   } {$O Timefunc  } {$O Sysop1    } {$O Sysop2    } {$O Offline   }
{$O Sysop21   } {$O Sysop2a   } {$O Sysop2b   } {$O Sysop2c   } {$O Sysop2d   }
{$O Sysop2e   } {$O Sysop2f   } {$O Sysop2l   } {$O Sysop2g   } {$O sysop2i   }
{$O Sysop2h   } {$O Sysop2j   } {$O Sysop2k   } {$O Sysop3    } {$O Sysop4    }
{$O Sysop6    } {$O Sysop7    } {$O Sysop7m   } {$O Sysop8    } {$O Sysop2m   }
{$O Sysop9    } {$O Sysop10   } {$O Sysop11   } {$O Mail0     } {$O Mail1     }
{$O Email     } {$O Mail5     } {$O Mail6     } {$O vote      } {$O Nodelist  }
{$O Mail7     } {$O Arcview   } {$O File0     } {$O File1     } {$O File2     }
{$O File5     } {$O File6     } {$O File8     } {$O multnode  } {$O Script    }
{$O File9     } {$O File10    } {$O File11    } {$O File12    } {$O File13    }
{$O File14    } {$O Archive1  } {$O Archive2  } {$O Archive3  } {$O Logon     }
{$O Maint     } {$O NewUsers  } {$O TimeBank  } {$O Bulletin  } {$O User      }
{$O ShortMsg  } {$O CUser     } {$O Doors     } {$O ExecBat   } {$O Automsg   }
{$O myio      } {$O Menus2    } {$O Menus3    } {$O Menus4    } {$O SysChat   }
{$O Event     } {$O BBSList   }

Procedure OvrInitXMS; External;
{$L OVERXMS.OBJ }

Const
  OvrMaxSize=65536;

Var ExitSave:Pointer;
    ExecFirst:Boolean;
    NewMenuCmd:Astr;

Procedure errorHandle;
Var
  t:text;
  s:string[50];

Begin
  ExitProc:=ExitSave;
  If (errorAddr<>Nil) then begin
    chdir(start_dir);
    if general.multinode and (node>0) then
      assign(sysopf,tempdir+'templog.'+cstr(node))
    else
      assign(sysopf,general.logspath+'sysop.log');
    append(sysopf);
    s := '^8*>>^7 Runtime error '+cstr(exitcode)+
            ' at '+date+' '+time+'^8 <<*^5'+
            ' (Check error.LOG)';
    writeln(sysopf,s);
    flush(sysopf); close(sysopf);
    if (textrec(trapfile).mode=fmoutput) then begin
      writeln(trapfile,s);
      flush(trapfile); close(trapfile);
    end;

    assign(t,'error.log');
    append(t);
    if (ioresult<>0) then rewrite(t);
    writeln(t,'อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');
    writeln(t,'Critical error Log file - Contains screen images at instant of error.');
    writeln(t,'The "ฒ" character shows the cursor position at time of error.');
    writeln(t,'อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ');
    writeln(t);
    writeln(t);
    Writeln(t,'ฏ>ฏ error #'+cstr(exitcode)+' at '+date+' '+time+' version: '+ver);
    if (useron) then begin
      write(t,'ฏ>ฏ User "'+allcaps(thisuser.name)+' #'+cstr(usernum)+'" was on ');
      if (Speed > 0) then
        writeln(t,'at ' + cstr(ActualSpeed) + ' baud')
      else
        writeln(t,'Locally');
    end;
    close(t);

    screendump('error.log');

    assign(t,'critical.err'); rewrite(t); close(t); setfattr(t,dos.hidden);

    print('^8System malfunction.');

    com_flush_tx;
    dtr(FALSE);
    com_deinstall;

    loadnode(node);
    noder.status:=[];
    noder.user:=0;
    savenode(node);

    halt(exiterrors);
  end;
end;

Procedure MenuExec;
Var cmd:Astr;
    i:Integer;
    done:Boolean;

Begin
  if (ExecFirst) then begin
    ExecFirst:=FALSE;
    Cmd:=NewMenuCmd;
    NewMenuCmd:='';
  end else MainMenuHandle(Cmd);

  if ((copy(cmd,1,2)='\\') and (so)) then begin
    domenucommand(done,copy(cmd,3,length(cmd)-2),newmenucmd);
    if (newmenucmd<>'') then cmd:=newmenucmd else cmd:='';
  end;

  newmenucmd:='';
  repeat domenuexec(cmd,newmenucmd) until (newmenucmd='');
end;

const
  NeedToHangUp:boolean = FALSE;

Var
  OvrPath:Astr;
  i:Integer;
  generalf:File of generalrec;
  f:file of byte;
  s:astr;
  t:text;
  x:byte;

Begin
  GetIntVec($14,Interrupt14);
  filemode:=66;
  exitsave:=exitproc;
  exitproc:=@errorhandle;

  directvideo:=FALSE;
  checksnow:=FALSE;

  useron:=FALSE; usernum:=0;

  getdir(0,start_dir);

  DatFilePath := getenv('RENEGADE');
  if (DatFilePath <> '') and (DatFilePath[length(DatFilePath)] <> '\') then
    DatFilePath := DatFilePath + '\';
  assign(f,DatFilePath + 'renegade.dat');
  reset(f);

  if (IOResult <> 0) then
    begin
      writeln('error reading RENEGADE.DAT.');
      halt;
    end;

  x:=0;

  seek(f,filesize(f));

  while filesize(f)<sizeof(general) do
    write(f,x);

  close(f);

  assign(generalf, DatFilePath + 'renegade.dat');
  reset(generalf);
  read(generalf,general);
  close(generalf);

  ovrfilemode:=66;
  ovrinit('RENEGADE.OVR');
  if (ovrresult<>ovrok) then
    ovrinit(general.multpath + 'RENEGADE.OVR');   { ram drive! }
  if (ovrresult<>ovrok) then
    begin
      clrscr;
      writeln('Overlay error.');
      halt;
  end;

  if (general.useems) then
    begin
      OvrInitXMS;
      If OvrResult <> OvrOk Then
        begin
          OvrInitEMS;
          if (ovrresult=ovrok) then OverlayLocation := 1;
        end
      else
        OverlayLocation := 2;
    end;

  ovrsetbuf(ovrmaxsize);
  ovrsetretry(ovrmaxsize div 3);

  init;

  MaxDisplayRows := hi(WindMax) + 1;
  MaxDisplayCols := lo(WindMax) + 1;
  ScreenSize := 2 * MaxDisplayRows * MaxDisplayCols;
  if (ScreenSize > 8000) then
    ScreenSize := 8000;

  if (packbasesonly) or (sortfilesonly) or
     (makeqwkfor > 0) or (upqwkfor > 0) then
    begin
      wfcmdefine;
      TempPause := FALSE;
      if (makeqwkfor > 0) then
        begin
          usernum := makeqwkfor;
          loadurec(thisuser,makeqwkfor);
          newdate:=pd2date(thisuser.laston);
          downloadpacket;
          saveurec(thisuser,makeqwkfor);
        end;
      if (upqwkfor > 0) then
        begin
          usernum := upqwkfor;
          loadurec(thisuser,upqwkfor);
          uploadpacket(TRUE);
          saveurec(thisuser,upqwkfor);
        end;
      if packbasesonly then
        begin
          doshowpackbases;
          print(^M^J'^5Message bases packed.');
        end;
      if sortfilesonly then
        sort;
      halt(0);
    end;

  smread:=FALSE;

  getmem (MenuCommand, maxmenucmds * sizeof(CommandRec));

  repeat
    if (NeedToHangUp) then
      begin
        NeedToHangUp := FALSE;
        DoPhoneHangUp(FALSE);
      end;

    wfcmenus;

    GlobalMenuCommands := 0;

    useron:=FALSE; usernum:=0;
    if (not doneday) then begin
      status_screen(100,'User logging in.',FALSE,s);
      LastScreenSwap := 0;
      if (getuser) then newuser;
      if (not hangup) then begin
        if (not hangup) then LogonMaint;
        if (not hangup) then begin
          with thisuser do begin
            newdate:=pd2date(laston);
            board:=lastmbase; fileboard:=lastfbase;
          end;
          batchtime:=0; numbatchfiles:=0; numubatchfiles:=0; hiubatchv:=0;
          newcomptables;

          menustackptr:=0;
          for i:=1 to 8 do menustack[i]:='';

         curmenu := general.menupath + 'global.mnu';
          if exist(curmenu) then
            begin
              readin;
              GlobalMenuCommands := noc;
            end;

          if thisuser.userstartmenu = '' then
            curmenu:=general.allstartmenu+'.MNU'
          else
            curmenu:=thisuser.userstartmenu+'.MNU';

          if (not exist(general.menupath+curmenu)) then begin
            sysoplog(general.menupath+curmenu+' is MISSING.  Loaded MAIN.MNU instead.');
            curmenu:='main.mnu';
          end;

          curmenu:=general.menupath+curmenu; readin;

          if (novice in thisuser.flags) then chelplevel:=2 else chelplevel:=1;
        end;

        newmenucmd:=''; i:=1;
        while ((i<=noc) and (newmenucmd='')) do begin
          if (MenuCommand^[i].ckeys='FIRSTCMD') then
            if (aacs(MenuCommand^[i].acs)) then newmenucmd:='FIRSTCMD';
          inc(i);
        end;
        execfirst:=(newmenucmd='FIRSTCMD');
        while (not hangup) do menuexec;     {This is the main loop!}
      end;

      if (quitafterdone) then
        begin
          if (ExiterrorLevel = 0) then
            ExiterrorLevel:=exitnormal;
          hangup:=TRUE;
          doneday:=TRUE;
          needtohangup:=TRUE;
        end;

      LogoffMaint;

      if (not doneday) then sl1('^3Logoff^5 '+'['+dat+']');

      if general.multinode then begin
         assign(t,general.logspath+'sysop.log');
         append(t);
         if (ioresult = 2) then
           rewrite(t);
         reset(sysopf);
         while not eof(sysopf) do begin
           readln(sysopf,s);
           writeln(t,s);
         end;
         close(sysopf); close(t);
         rewrite(sysopf); close(sysopf);
         Lasterror := IOResult;
      end;

      if (com_carrier) and (not doneday) then
        if (incom) then
          needtohangup:=TRUE;

    end;
  until (doneday);

  {freemem (MenuCommand, maxmenucmds * sizeof(CommandRec));}

  if needtohangup then dophonehangup(FALSE);
  com_deinstall;

  if general.multinode then
    kill(tempdir+'templog.'+cstr(node));

  window(1,1,MaxDisplayCols, MaxDisplayRows);
  textcolor(7); clrscr; textcolor(14);
  if newechomail and (ExiterrorLevel=0) then ExiterrorLevel:=2;

  loadnode(node);
  noder.status:=[];
  savenode(node);
  WriteLn('Exiting with errorlevel ',ExiterrorLevel);
  halt(ExiterrorLevel);
end.
