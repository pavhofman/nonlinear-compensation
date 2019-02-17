% sending "distortion off" command
function clbkDistortOff(src, data, cmdFile)
  global DISTORT;
  cmd = [DISTORT ' ' 'off'];
  writeCmd(cmd, cmdFile, false);
endfunction
