% scheduler-enabled function for calibrating joint-device freqs
function calibrateFreqsSched(label = 1)
  % init section
  [P1, P2, P3, P4] = enum();
  
  % fixed for now
  global freq;
  global fs;
  global cmdFileRec;
  global cmdFilePlay;
  
  % current frequency of calibration
  persistent curFreq = freq;

  switch(label)
    case P1
      curFreq = freq;
      %infoDlg(sprintf("Switch to voltage divider now.\nMake sure the level is same (up to 0.1dB)\nas LPF level at %d.\nInterpolation of distortion at various \nfundamental levels is not implemented yet.", freq));
      clearOutBox();
      printStr(sprintf("Joint-device calibrating VD at all harmonic frequencies of %dHz:", freq));;


      writeCmd("pass", cmdFilePlay);
      writeCmd("pass", cmdFileRec);
      schedPause(1, P2, mfilename());
      return;
    case {P2 P3}
      % calibrating direct connection at freq harmonics
      while curFreq < fs/2
        switch(label)
          case P2            
            printStr(sprintf("Generating %dHz", curFreq));    
            writeCmd(sprintf ("gen %d", curFreq), cmdFilePlay);
            % long pause to let samples propagate through all the buffers
            schedPause(2, P3, mfilename());
            return;
          case P3
            printStr(sprintf("Joint-device calibrating VD at %dHz", curFreq));
            writeCmd("cal", cmdFileRec);
            % next frequency
            curFreq += freq;
            schedPause(1, P2, mfilename());
            return;
          endswitch
      endwhile
  endswitch
  % final section
  writeCmd("pass", cmdFilePlay);
  writeCmd("pass", cmdFileRec);
  printStr('Finished, both sides passing');  
endfunction