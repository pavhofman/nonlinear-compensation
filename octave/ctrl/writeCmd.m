% atomic writing commands to cmd file
% clear - clear outbox before printStr, default false
function lastCmdID = writeCmd(cmd, cmdFilename, clear = false)
  persistent cmdID = 0;
  global CMD_ID_PREFIX;
  
  % new call - incrementing cmdID
  ++cmdID;
  
  % ID5
  cmdIDStr = [CMD_ID_PREFIX int2str(cmdID)];
  
  [tmpfid, tmpFilename] = mkstemp([ tempdir() 'XXXXXX' ], true);
  fprintf(tmpfid,"%s %s", cmdIDStr, cmd);
  fclose(tmpfid);
  movefile(tmpFilename, cmdFilename);
  unlink(tmpFilename);
  if clear
    clearOutBox();
  endif
  infoMsg = ['Sent CMD: "' cmd '" to ' cmdFilename];
  printStr(infoMsg);
  writeLog('DEBUG', infoMsg);
  lastCmdID = cmdID;
endfunction
