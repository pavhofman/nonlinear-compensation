% sending generate off command to play side
function cmdID = sendStopGeneratorCmd()
  global cmdFilePlay;
  global GENERATE;
  
  printStr(sprintf('Generator Off'));
  cmdID = writeCmd([GENERATE ' ' 'off'], cmdFilePlay);

endfunction