function clbkCalibrateLPF()
  % fixed for now
  freq = 3000;
  fs = 48000;

  infoDlg(sprintf("Switch to LP filter now.\nMake sure the level is same (up to 0.1dB)\nas VD level at %d.\nInterpolation of distortion at various \nfundamental levels is not implemented yet.", freq));
  clearOutBox();
  printStr(sprintf("Joint-device calibrating LP filter at %dHz", freq));
  global cmdFileRec;
  global cmdFilePlay;

  writeCmd("pass", cmdFilePlay);
  writeCmd("pass", cmdFileRec);
  pause(1);

  % joint-device calibrating filter at freq
  printStr(sprintf("Generating %dHz", freq));    
  writeCmd(sprintf ("gen %d", freq), cmdFilePlay);
  % long pause to let samples propagate through all the buffers
  pause(2);
  printStr(sprintf("Joint-device calibrating at %dHz", freq));
  writeCmd("cal filter", cmdFileRec);
  pause(1);  

  writeCmd("pass", cmdFilePlay);
  writeCmd("pass", cmdFileRec);
  printStr('Finished, both sides passing');
endfunction