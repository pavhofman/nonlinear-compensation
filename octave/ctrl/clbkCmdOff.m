% sending "CMD off" command
function clbkCmdOff(src, data, cmd, cmdFile)
  wholeCommand = [cmd ' ' 'off'];
  writeCmd(wholeCommand, cmdFile, true);
endfunction
