function clbkSplitCompen()
  % fixed for now
  global freq;
  global fs;
  
  clearOutBox();
  printStr(sprintf("Split-compensating for freq %dHz:", freq));;

  global cmdFileRec;
  global cmdFilePlay;

  writeCmd("pass", cmdFileRec);
  writeCmd("pass", cmdFilePlay);
  pause(1);
  
  printStr(sprintf("Generating %dHz", freq));    
  writeCmd(sprintf ("gen %d", freq), cmdFilePlay);
  
  % long pause to let samples propagate through all the buffers
  pause(2);
  global outputDeviceName;
  global inputDeviceName;

  printStr(sprintf("Split-compensating rec side at %dHz", freq));
  writeCmd(sprintf("comp %s", inputDeviceName), cmdFileRec);
  
  printStr(sprintf("Split-compensating play side at %dHz", freq));
  writeCmd(sprintf("comp %s", outputDeviceName), cmdFilePlay);
  printStr(sprintf("Finished, play side generating %dHz, both sides split-compensating.", freq));
  printStr("Now switch arbitrarily between VD and LPF");
endfunction