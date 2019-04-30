% scheduler-enabled function for complete split calibration
% Only one-sine (one fundamental) is supported!!
% calibrating at current freq, requires pre-measured VD and LPF!
function splitCalibrateSched(label = 1)
  % init section
  [P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, ERROR] = enum();
  
  persistent AUTO_TIMEOUT = 10;
  % manual calibration timeout - enough time to adjust the level into the range limits
  persistent MANUAL_TIMEOUT = 500;
  
  % number of averaging calibration runs for calibrations yielding only fundamentals for transfer measuring
  % keeping same as regular full count for now
  persistent REDUCED_CALIB_RUNS = 10;
  
  % step above and below exact calibration level to also calibrate for interpolation
  persistent CAL_LEVEL_STEP = db2mag(0.05);
  
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
  
  persistent lpFundAmpl = NA;
  
  % current frequency of calibration
  % all set in first P1 branch
  persistent curFreq = NA;
  persistent fs = NA;
  persistent origFreq = NA;
  persistent origRecLevel = NA;
  persistent origPlayLevels = NA;
  persistent playEqualizer = NA;
  
  persistent swStruct = initSwitchStruct();

  while true
    switch(label)
    
      case P1
        
        global playInfo;
        global recInfo;

        % loading current values from analysis
        fs = recInfo.fs;
        % TODO - checks - only one fundament freq!!
        origFreq = recInfo.measuredPeaks{analysedChID}(1, 1);
        origRecLevel = recInfo.measuredPeaks{analysedChID}(:, 2);
        % two channels, only first fundament freqs (the only freq!)
        origPlayLevels = {playInfo.measuredPeaks{1}(1, 2), playInfo.measuredPeaks{2}(1, 2)};
        
        % playLevels are measured BEHIND equalizer in play process. When generating, one must take the equalizer into account to reach identical play levels
        % only values for first two channels to fit origPlayLevels
        playEqualizer = playInfo.equalizer(1:2);

        swStruct.calibrate = true;
        % for now calibrating right output channel only
        swStruct.inputR = (playChID == 2);
        swStruct.vd = false;
        swStruct.analysedR = (analysedChID == 2);
        showSwitchWindow(sprintf('Set switches for LP calibration/measurement of input channel ', analysedChID), swStruct);

        clearOutBox();
        printStr(sprintf("Joint-device calibrating LP at current frequency %dHz:", origFreq));
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
        % calibrating LPF at origFreq
        printStr(sprintf("Generating %dHz", origFreq));
        cmdIDPlay = sendPlayGeneratorCmd(origFreq, origPlayLevels, playEqualizer);
        
        printStr(sprintf("Joint-device calibrating/measuring LP at %dHz", origFreq));
        % deleting the calib file should it exist - always clean calibration
        calFile = genCalFilename(origFreq, fs, COMP_TYPE_JOINT, playChID, analysedChID, MODE_DUAL, EXTRA_CIRCUIT_LP1);
        deleteFile(calFile);
        
        % safety measure - requesting calibration only at curFreq
        calFreqReqStr = getCalFreqReqStr({[origFreq, NA, NA]});
        calCmd = [CALIBRATE ' ' calFreqReqStr ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_JOINT) ' ' getMatrixCellsToCmdStr(origPlayLevels, CMD_PLAY_AMPLS_PREFIX) ' ' CMD_EXTRA_CIRCUIT_PREFIX EXTRA_CIRCUIT_LP1];
        cmdIDRec = writeCmd(calCmd, cmdFileRec);
        % next frequency
        waitForCmdDone([cmdIDPlay, cmdIDRec], P4, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case P4
        % VD calibration
        swStruct.vd = true;
        showSwitchWindow({'Change switch to VD calibration', sprintf('For first freq. adjust level into the shown range for channel ', analysedChID)}, swStruct);

        % we need to read the filter fund level in order to calibrate fundamental to the same level as close as possible for calculation of the splittting
        lpFundAmpl = loadCalFundAmpl(origFreq, fs, playChID, analysedChID, EXTRA_CIRCUIT_LP1);

        clearOutBox();
        
        printStr(sprintf("Generating %dHz", origFreq));
        cmdIDPlay = sendPlayGeneratorCmd(origFreq, origPlayLevels, playEqualizer);
        
        printStr(sprintf("Joint-device calibrating VD at frequency %dHz:", origFreq));
        % VD at fundament (origFreq) must be calibrated at exactly the same level as LP so that the distortion characteristics of ADC are same
        % amplitude-constrained calibration
        % we need same ADC distortion profile for LP and VD => the level must be VERY similar
        calTolerance = db2mag(0.03);
        calFreqReq = getConstrainedLevelCalFreqReq(lpFundAmpl, origFreq, analysedChID, calTolerance);
        calFreqReqStr = getCalFreqReqStr(calFreqReq);
        % much more time for manual level adjustment
        timeout = MANUAL_TIMEOUT;
        % zooming calibration levels + plotting the range so that user can adjust precisely                
        zoomCalLevels(calFreqReq, getTargetLevelsForAnalysedCh(lpFundAmpl, analysedChID));
        % deleting the calib file should it exist - always clean calibration
        calFile = genCalFilename(origFreq, fs, COMP_TYPE_JOINT, playChID, analysedChID, MODE_DUAL, EXTRA_CIRCUIT_VD);
        deleteFile(calFile);

        calCmd = [CALIBRATE ' ' calFreqReqStr  ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_JOINT) ' ' getMatrixCellsToCmdStr(origPlayLevels, CMD_PLAY_AMPLS_PREFIX) ' ' CMD_EXTRA_CIRCUIT_PREFIX EXTRA_CIRCUIT_VD];
              
        cmdIDRec = writeCmd(calCmd, cmdFileRec);
        % long waiting - manual level adjustment
        waitForCmdDone([cmdIDPlay, cmdIDRec], P5, MANUAL_TIMEOUT, ERROR, mfilename());
        return;

      case P5
        % range calibrations finished, closing the zoomed calib plot
        closeCalibPlot();

        clearOutBox();
        printStr(sprintf('Calculating split calibration'));
        calculateSplitCal(origFreq, fs, playChID, analysedChID, MODE_DUAL, EXTRA_CIRCUIT_VD, EXTRA_CIRCUIT_LP1);
        
        printStr(sprintf("Generating orig %dHz for split REC side calibration", origFreq));
        cmdIDPlay = sendPlayGeneratorCmd(origFreq, origPlayLevels, playEqualizer);

        printStr(sprintf('Compensating PLAY side first'));
        cmdIDRec = writeCmd([COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_PLAY_SIDE)], cmdFilePlay);
        waitForCmdDone([cmdIDPlay, cmdIDRec], P6, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case {P6, P7, P8}
        switch label
          case P6
            % deleting the calib file for direct channel should it exist - always clean calibration
            calFile = genCalFilename(origFreq, fs, COMP_TYPE_REC_SIDE, NA, getTheOtherChannelID(analysedChID), MODE_DUAL, '');
            deleteFile(calFile);

            % the newly created calfile for analysedChID contains calculated data, not deleting
            calFile = genCalFilename(origFreq, fs, COMP_TYPE_REC_SIDE, NA, analysedChID, MODE_DUAL, '');
            deleteFile(calFile);
            
            expl = 'upper limit';
            adjustment = CAL_LEVEL_STEP;
            
          case P7
            expl = 'lower limit';
            adjustment = 1/CAL_LEVEL_STEP;
            
          case P8
            % last run at exact value - for now
            expl = 'exact value';
            adjustment = 1;
            
        endswitch
        
        printStr(sprintf('Calibrating REC side at original recLevel of channel %d - %s', analysedChID, expl));
        
        % amplitude-constrained calibration
        % TODO - for now using lpFundAmpl instead of origRecLevel to allow easy switching between LP and VD for result checking
        % calFreqReq = getConstrainedLevelCalFreqReq(origRecLevel * adjustment, origFreq, analysedChID);
        
        % max. allowed deviation in each direction from midAmpl
        % the tolerance really does not matter much here
        calTolerance = db2mag(0.05);

        calFreqReq = getConstrainedLevelCalFreqReq(lpFundAmpl * adjustment, origFreq, analysedChID, calTolerance);
        calFreqReqStr = getCalFreqReqStr(calFreqReq);
        % zooming calibration levels + plotting the range so that user can adjust precisely
        % target level = orig Rec level (not the increased range)
        % zoomCalLevels(calFreqReq, getTargetLevelsForAnalysedCh(origRecLevel, analysedChID));
        zoomCalLevels(calFreqReq, getTargetLevelsForAnalysedCh(lpFundAmpl, analysedChID));
        
        cmdID = writeCmd([CALIBRATE ' ' calFreqReqStr ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_REC_SIDE)], cmdFileRec);
        waitForCmdDone(cmdID, label + 1, MANUAL_TIMEOUT, ERROR, mfilename());
        return;
        
      case P9
        clearOutBox();
        
        % all calibrations finished, closing the zoomed calib plot
        closeCalibPlot();
        
        printStr(sprintf('Compensating SPLIT REC side'));
        cmdID = writeCmd([COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_REC_SIDE)], cmdFileRec);
        waitForCmdDone(cmdID, P10, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case P10
        printStr(sprintf('Generator Off'));
        cmdID = writeCmd([GENERATE ' ' 'off'], cmdFilePlay);
        waitForCmdDone(cmdID, P11, AUTO_TIMEOUT, ERROR, mfilename());
        return;

      case P11
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