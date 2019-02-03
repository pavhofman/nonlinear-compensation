% atomic writing commands to cmd file
function cmdID = writeCmd(cmd, cmdFilename)  
  persistent intCmdID = 1;
  global CMD_ID_PREFIX;
  
  % ID5
  cmdID = [CMD_ID_PREFIX int2str(intCmdID)];
  
  [tmpfid, tmpFilename] = mkstemp([ tempdir() 'XXXXXX' ], true);
  fprintf(tmpfid,"%s %s", cmdID, cmd);
  fclose(tmpfid);
  movefile(tmpFilename, cmdFilename);
  unlink(tmpFilename);
  
  % incrementing integer part of command ID for next call
  ++intCmdID;
endfunction
