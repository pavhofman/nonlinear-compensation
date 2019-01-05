function clbkCalibrateFreqs()
  % fixed for now
  global freq;
  global fs;

  infoDlg(sprintf("Switch to voltage divider now.\nMake sure the level is same (up to 0.1dB) as LPF level at %d.\nInterpolation of distortion at various fundamental levels is not implemented yet.", freq));
  clearOutBox();
  printStr(sprintf("Joint-device calibrating VD at all harmonic frequencies of %dHz:", freq));;
  global cmdFileRec;
  global cmdFilePlay;


  writeCmd("pass", cmdFilePlay);
  writeCmd("pass", cmdFileRec);
  pause(1);

  % calibrating direct connection at freq harmonics
  for f = (freq:freq:fs/2 - 1)
    printStr(sprintf("Generating %dHz", f));    
    writeCmd(sprintf ("gen %d", f), cmdFilePlay);
    % long pause to let samples propagate through all the buffers
    pause(2);
    printStr(sprintf("Joint-device calibrating VD at %dHz", f));
    writeCmd("cal", cmdFileRec);
    pause(1);  
  endfor
  writeCmd("pass", cmdFilePlay);
  writeCmd("pass", cmdFileRec);
  printStr('Finished, both sides passing');
endfunction