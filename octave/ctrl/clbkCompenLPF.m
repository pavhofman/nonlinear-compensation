function clbkCompenLPF()
  % fixed for now
  global freq;
  global fs;

  infoDlg('Switch to LP filter now!');
  clearOutBox();
  printStr(sprintf("Joint-device compensating LPF for freq %dHz:", freq));;
  global cmdFileRec;
  global cmdFilePlay;

  printStr(sprintf("Generating %dHz", freq));    
  writeCmd(sprintf ("gen %d", freq), cmdFilePlay);
  % long pause to let samples propagate through all the buffers
  pause(2);
  printStr(sprintf("Joint-device compensating VD at %dHz", freq));
  global jointDeviceName;
  writeCmd(sprintf("comp %s filter", jointDeviceName), cmdFileRec); 
  printStr('Finished, play side generating, rec side joint-device compensating filter');
endfunction