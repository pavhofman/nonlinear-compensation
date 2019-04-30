% scheduler-enabled function for measuring VD and LPF transfer via regular joint-sides calibration
% Only one-sine (one fundamental) is supported!!
function measureTransferSched(label = 1)
  % init section
  [P1, P2, P3, P4, P5, P6, ERROR] = enum();
  
  persistent AUTO_TIMEOUT = 10;
  % manual calibration timeout - enough time to adjust the level into the range limits
  persistent MANUAL_TIMEOUT = 500;
  
  % right ch goes through LP or VD, left input channel is direct
  % fixed for now!
  persistent analysedChID = 2;
  % ID of output channel used for split calibration
  persistent playChID = 2;
  
  persistent EXTRA_CIRCUIT_VD = 'vd';
  persistent EXTRA_CIRCUIT_LP1 = 'lp1';  
  
  global cmdFileRec;
  global cmdFilePlay;
  global GENERATE;
  global PASS;
  global CALIBRATE;
  global COMPENSATE;
  global CMD_EXTRA_CIRCUIT_PREFIX;
  global CMD_CHANNEL_FUND_PREFIX;
  global CMD_COMP_TYPE_PREFIX;
  global CMD_CALRUNS_PREFIX;
  global CMD_PLAY_AMPLS_PREFIX;
  global COMP_TYPE_JOINT;
  global COMP_TYPE_PLAY_SIDE;
  global COMP_TYPE_REC_SIDE;
  
  global MODE_DUAL;
  
  % current frequency of calibration
  % all set in first P1 branch
  persistent curFreq = NA;
  persistent fs = NA;
  persistent origFreq = NA;
  
  % measured at fixed levels
  persistent PLAY_LEVELS = {0.9, 0.9};
  
  persistent swStruct = initSwitchStruct();
  persistent lpFundAmpl = NA;
  
  while true
    switch(label)
    
      case P1
        
        global playInfo;
        global recInfo;

        % loading current values from analysis
        fs = recInfo.fs;
        % TODO - checks - only one fundament freq!!
        origFreq = recInfo.measuredPeaks{analysedChID}(1, 1);
        

        % starting at last measured freq
        curFreq = origFreq;
        
        swStruct.calibrate = true;
        % for now calibrating right output channel only
        swStruct.inputR = (playChID == 2);
        swStruct.vd = false;
        swStruct.analysedR = (analysedChID == 2);
        showSwitchWindow(sprintf('Set switches for LP calibration/measurement of input channel ', analysedChID), swStruct);

        clearOutBox();
        printStr(sprintf("Joint-device calibrating LP at all harmonic frequencies of %dHz:", curFreq));
        
        % setting pass status on both sides
        cmdIDPlay = writeCmd(PASS, cmdFilePlay);
        cmdIDRec = writeCmd(PASS, cmdFileRec);
        % we have to wait for command acceptance before issuing new commands (the cmd files could be deleted by new commands before they are consumed
        % waiting only for one of the pass commands, both sides run at same speed
        % after AUTO_TIMEOUT secs timeout call ERROR
        waitForCmdDone([cmdIDPlay, cmdIDRec], P2, AUTO_TIMEOUT, ERROR, mfilename());
        return;

      case P2
        
        global SET_MODE;
        global CMD_MODE_PREFIX;
        
        % setting MODE_DUAL on both sides
        cmdStr = [SET_MODE ' ' CMD_MODE_PREFIX num2str(MODE_DUAL)];
        cmdIDPlay = writeCmd(cmdStr, cmdFilePlay);
        cmdIDRec = writeCmd(cmdStr, cmdFileRec);
        waitForCmdDone([cmdIDPlay, cmdIDRec], P3, AUTO_TIMEOUT, ERROR, mfilename());
        return;

      case P3
        % calibrating direct connection at freq harmonics
        while curFreq < fs/2
          printStr(sprintf("Generating %dHz", curFreq));
          cmdIDPlay = sendPlayGeneratorCmd(curFreq, PLAY_LEVELS);

          printStr(sprintf("Joint-device calibrating/measuring LP at %dHz", curFreq));
          % deleting the calib file should it exist - always clean calibration
          calFile = genCalFilename(curFreq, fs, COMP_TYPE_JOINT, playChID, analysedChID, MODE_DUAL, EXTRA_CIRCUIT_LP1);
          deleteFile(calFile);
          
          % safety measure - requesting calibration only at curFreq
          calFreqReqStr = getCalFreqReqStr({[curFreq, NA, NA]});
          calCmd = [CALIBRATE ' ' calFreqReqStr ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_JOINT) ' ' getMatrixCellsToCmdStr(PLAY_LEVELS, CMD_PLAY_AMPLS_PREFIX) ' ' CMD_EXTRA_CIRCUIT_PREFIX EXTRA_CIRCUIT_LP1];
          cmdIDRec = writeCmd(calCmd, cmdFileRec);

          % next frequency
          curFreq += origFreq;
          waitForCmdDone([cmdIDPlay, cmdIDRec], P3, AUTO_TIMEOUT, ERROR, mfilename());
          return;            
        endwhile
        % VD calibration
        swStruct.vd = true;
        showSwitchWindow({'Change switch to VD calibration', sprintf('For first freq. adjust level into the shown range for channel ', analysedChID)}, swStruct);

        % we need to read the filter fund level in order to calibrate fundamental to the same level as close as possible for calculation of the splittting
        lpFundAmpl = loadCalFundAmpl(origFreq, fs, playChID, analysedChID, EXTRA_CIRCUIT_LP1);

        % resetting curFreq to fundament
        curFreq = origFreq;
        clearOutBox();
        printStr(sprintf("Joint-device calibrating VD at all harmonic frequencies of %dHz:", curFreq));

        label = P4;
        % goto label - next loop
        continue;

      case P4
        % calibrating LP connection at freq harmonics
        while curFreq < fs/2
          printStr(sprintf("Generating %dHz", curFreq));
          cmdIDPlay = sendPlayGeneratorCmd(curFreq, PLAY_LEVELS);

          printStr(sprintf("Joint-device calibrating VD at %dHz", curFreq));
          if curFreq == origFreq
            % VD at fundament (origFreq) must be calibrated at exactly the same level as LP so that the distortion characteristics of ADC are same
            
            % amplitude-constrained calibration

            % max. allowed deviation in each direction from midAmpl
            % similar level of VD to LPF provides similar phaseshift of VD to when measured in splitCalibrateSched. Here it is not so critical
            calTolerance = db2mag(0.08);

            calFreqReq = getConstrainedLevelCalFreqReq(lpFundAmpl, origFreq, analysedChID, calTolerance);
            calFreqReqStr = getCalFreqReqStr(calFreqReq);
            % much more time for manual level adjustment
            timeout = MANUAL_TIMEOUT;
            % zooming calibration levels + plotting the range so that user can adjust precisely                
            zoomCalLevels(calFreqReq, getTargetLevelsForAnalysedCh(lpFundAmpl, analysedChID));
          else
            % harmonic freqs, level is not important, only waiting from stable frequency
            calFreqReqStr = getCalFreqReqStr({[curFreq, NA, NA]});
            % regular (= short) timeout
            timeout = AUTO_TIMEOUT;
            closeCalibPlot();
          endif
          % deleting the calib file should it exist - always clean calibration
          calFile = genCalFilename(curFreq, fs, COMP_TYPE_JOINT, playChID, analysedChID, MODE_DUAL, EXTRA_CIRCUIT_VD);
          deleteFile(calFile);

          calCmd = [CALIBRATE ' ' calFreqReqStr  ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_JOINT) ' ' getMatrixCellsToCmdStr(PLAY_LEVELS, CMD_PLAY_AMPLS_PREFIX) ' ' CMD_EXTRA_CIRCUIT_PREFIX EXTRA_CIRCUIT_VD];
          cmdIDRec = writeCmd(calCmd, cmdFileRec);
          % next frequency
          curFreq += origFreq;
          waitForCmdDone([cmdIDPlay, cmdIDRec], P4, timeout, ERROR, mfilename());
          return;
        endwhile
        label = P5;
        % goto label - next loop
        continue;

      case P5
        printStr(sprintf('Generator Off'));
        cmdID = writeCmd([GENERATE ' ' 'off'], cmdFilePlay);
        waitForCmdDone(cmdID, P6, AUTO_TIMEOUT, ERROR, mfilename());
        return;

      case P6
        swStruct.calibrate = false;
        showSwitchWindow('Set switches for measuring DUT', swStruct');
        return;
        
      case ERROR
        printStr('Timeout waiting for command done, exiting callback');
        return;
    endswitch
  endwhile
  printStr('Calibration finished, both sides compensating, measuring');  
endfunction