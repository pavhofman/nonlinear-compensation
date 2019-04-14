% scheduler-enabled function for calibrating joint-device freqs
function calibrateFreqsSched(label = 1)
  % init section
  [P1, P2, P3, P4, ERROR] = enum();
  
  persistent TIMEOUT = 500;
  
  % fixed for now
  global freq;
  global fs;
  global cmdFileRec;
  global cmdFilePlay;
  global GENERATE;
  global PASS;
  global CALIBRATE;
  global CMD_CHANNEL_FUND_PREFIX;
  
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
            % only one channel, will be duplicated in run_generator.m
            genFund = {[curFreq, db2mag(-3)]};

            cmdID = writeCmd(getGeneratorCmdStr(genFund), cmdFilePlay);
            waitForCmdDone(cmdID, P3, TIMEOUT, ERROR, mfilename());
            return;
          case P3
            printStr(sprintf("Joint-device calibrating VD at %dHz", curFreq));
            % safety measure - requesting calibration only at curFreq
            % no amplitude specification (NAs)
            calFreqReq = {[curFreq, NA, NA], [curFreq, db2mag(-12.50), db2mag(-12.40)]}
            calFreqReqStr = getCalFreqReqStr(calFreqReq);
            cmdID = writeCmd([CALIBRATE ' ' calFreqReqStr], cmdFileRec);
            
            targetLevels = [NA, db2mag(-12.45)];
            zoomCalLevels(calFreqReq, targetLevels)
            
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
  % generator OFF
  writeCmd([GENERATE ' off'], cmdFilePlay);
  writeCmd(PASS, cmdFileRec);
  printStr('Finished, both sides passing');  
endfunction