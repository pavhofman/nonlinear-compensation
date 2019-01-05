function clbkCompenVD()
  % fixed for now
  global freq;
  global fs;

  infoDlg('Switch to voltage divider now!');
  clearOutBox();
  printStr(sprintf("Joint-device compensating VD for freq %dHz:", freq));;

  global cmdFileRec;
  global cmdFilePlay;

  printStr(sprintf("Generating %dHz", freq));    
  writeCmd(sprintf ("gen %d", freq), cmdFilePlay);
  % long pause to let samples propagate through all the buffers
  pause(2);
  printStr(sprintf("Joint-device compensating VD at %dHz", freq));
  writeCmd("comp", cmdFileRec); 
  printStr('Finished, play side generating, rec side joint-device compensating VD');
endfunction