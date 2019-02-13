% atomic writing commands to cmd file
% clear - clear outbox before printStr, default false
function cmdID = writeCmd(cmd, cmdFilename, clear = false)  
  persistent intCmdID = 1;
  global CMD_ID_PREFIX;
  
  % ID5
  cmdID = [CMD_ID_PREFIX int2str(intCmdID)];
  
  [tmpfid, tmpFilename] = mkstemp([ tempdir() 'XXXXXX' ], true);
  fprintf(tmpfid,"%s %s", cmdID, cmd);
  fclose(tmpfid);
  movefile(tmpFilename, cmdFilename);
  unlink(tmpFilename);
  if clear
    clearOutBox();
  endif
  printStr(['Sent CMD: "' cmd '" to ' cmdFilename]);
  % incrementing integer part of command ID for next call
  ++intCmdID;
endfunction
