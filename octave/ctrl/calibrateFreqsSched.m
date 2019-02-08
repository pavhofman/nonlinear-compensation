% scheduler-enabled function for calibrating joint-device freqs
function calibrateFreqsSched(label = 1)
  % init section
  [P1, P2, P3, P4, ERROR] = enum();
  
  persistent TIMEOUT = 5;
  
  % fixed for now
  global freq;
  global fs;
  global cmdFileRec;
  global cmdFilePlay;
  global GENERATE;
  global PASS;
  global CALIBRATE;
  global CMD_FREQ_PREFIX;
  global CMD_AMPL_PREFIX;
  
  % current frequency of calibration
  persistent curFreq = freq;

  switch(label)
    case P1
      curFreq = freq;
      %infoDlg(sprintf("Switch to voltage divider now.\nMake sure the level is same (up to 0.1dB)\nas LPF level at %d.\nInterpolation of distortion at various \nfundamental levels is not implemented yet.", freq));
      clearOutBox();
      printStr(sprintf("Joint-device calibrating VD at all harmonic frequencies of %dHz:", freq));;

      writeCmd(PASS, cmdFilePlay);
      cmdID = writeCmd(PASS, cmdFileRec);
      % we have to wait for command acceptance before issuing new commands (the cmd files could be deleted by new commands before they are consumed
      % waiting only for one of the pass commands, both sides run at same speed
      % after TIMEOUT secs timeout call ERROR
      waitForCmdDone(cmdID, P2, TIMEOUT, ERROR, mfilename());
      return;
    case {P2 P3}
      % calibrating direct connection at freq harmonics
      while curFreq < fs/2
        switch(label)
          case P2            
            printStr(sprintf("Generating %dHz", curFreq));    
            cmdID = writeCmd([GENERATE " " CMD_FREQ_PREFIX num2str(curFreq) " " CMD_AMPL_PREFIX num2str(db2mag(-3))], cmdFilePlay);
            waitForCmdDone(cmdID, P3, TIMEOUT, ERROR, mfilename());
            return;
          case P3
            printStr(sprintf("Joint-device calibrating VD at %dHz", curFreq));
            % safety measure - requesting calibration only at curFreq
            cmdID = writeCmd([CALIBRATE " " CMD_FREQ_PREFIX num2str(curFreq)], cmdFileRec);
            % next frequency
            curFreq += freq;
            waitForCmdDone(cmdID, P2, TIMEOUT, ERROR, mfilename());
            return;            
          endswitch
      endwhile
      case ERROR
        printStr('Timeout waiting for command done, exiting callback');
        return;
  endswitch
  % final section
  writeCmd(PASS, cmdFilePlay);
  writeCmd(PASS, cmdFileRec);
  printStr('Finished, both sides passing');  
endfunction