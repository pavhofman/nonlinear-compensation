% atomic writing commands to cmd file
function writeCmd(cmd, cmdFilename)
  [tmpfid, tmpFilename] = mkstemp([ tempdir() 'XXXXXX' ], true);
  fprintf(tmpfid,"%s", cmd);
  fclose(tmpfid);
  movefile(tmpFilename, cmdFilename);
  unlink(tmpFilename);
endfunction
