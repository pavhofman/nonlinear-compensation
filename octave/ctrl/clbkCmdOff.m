% sending "CMD off" command
function cmdID = clbkCmdOff(src, data, cmd, cmdFile)
  wholeCommand = [cmd ' ' 'off'];
  cmdID = writeCmd(wholeCommand, cmdFile, true);
endfunction
