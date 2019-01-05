function clbkSplitCal()
  global freq;
  clearOutBox();
  
  printStr(sprintf("Calculating split calibration for %dHz", freq));
  global cmdFileRec;
  global cmdFilePlay;

  % splitting calibration
  writeCmd("split", cmdFileRec);

  writeCmd("pass", cmdFilePlay);
  writeCmd("pass", cmdFileRec);
  printStr('Finished splitting, both sides passing');
endfunction