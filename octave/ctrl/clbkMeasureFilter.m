function clbkMeasureFilter()  
  infoDlg('Switch to LP filter now!');
  
  clearOutBox();
  printStr('Measuring the filter trasfer:');

  global cmdFileRec;
  global cmdFilePlay;

  freq = 3000;
  fs = 48000;

  
  writeCmd("pass", cmdFilePlay);
  writeCmd("pass", cmdFileRec);
  pause(1);

  % measuring LP filter at freq harmonics
  for f = (freq:freq:fs/2 - 1)
    printStr(sprintf("Generating %dHz", f));
    writeCmd(sprintf ("gen %d", f), cmdFilePlay);
    % long pause to let samples propagate through all the buffers
    pause(2);
    printStr(sprintf("Measuring filter at %dHz", f));
    writeCmd(sprintf ("meas %d 2", f), cmdFileRec);
    pause(1);  
  endfor

  writeCmd("pass", cmdFilePlay);
  writeCmd("pass", cmdFileRec);
  printStr('Finished, both sides passing');
endfunction
