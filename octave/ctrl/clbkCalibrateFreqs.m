function clbkCalibrateFreqs()
  clearOutBox();
  printStr('Calibrating frequencies:');
  global cmdFileRec;
  global cmdFilePlay;

  % fixed for now
  freq = 3000;
  fs = 48000;

  writeCmd("pass", cmdFilePlay);
  writeCmd("pass", cmdFileRec);
  pause(1);

  % calibrating direct connection at freq harmonics
  for f = (freq:freq:fs/2 - 1)
    printStr(sprintf("Generating %dHz", f));    
    writeCmd(sprintf ("gen %d", f), cmdFilePlay);
    % long pause to let samples propagate through all the buffers
    pause(2);
    printStr(sprintf("Calibrating at %dHz", f));
    writeCmd("cal", cmdFileRec);
    pause(1);  
  endfor
  writeCmd("pass", cmdFilePlay);
  writeCmd("pass", cmdFileRec);
  printStr('Finished');
endfunction