function clbkSplitCalibrate()
  global freq;
  clearOutBox();
  
  printStr(sprintf("Calculating split calibration for %dHz", freq));
  global cmdFileRec;
  global cmdFilePlay;

  % splitting calibration
  writeCmd("split", cmdFileRec);

  writeCmd("pass", cmdFilePlay);

  % waiting till rec side finishes splitting
  % TODO - implement notification about completion from slave processes
  pause(1);
  writeCmd("pass", cmdFileRec);
  printStr('Finished splitting, both sides passing');
endfunction