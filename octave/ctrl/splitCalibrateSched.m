% scheduler-enabled function for complete split calibration
% Only one-sine (one fundamental) is supported!!
% calibrating at current freq, requires pre-measured VD and LPF!
function result = splitCalibrateSched(label = 1)
  result = NA;
  % init section
  [CHECKING_LABEL, PASSING_LABEL, MODE_LABEL, WAIT_FOR_LP_LABEL, CAL_LP_LABEL, WAIT_FOR_VD_LABEL, CAL_VD_LABEL, SPLIT_CAL_LABEL, COMP_PLAY_LABEL, ...
      CAL_REC_UP_LABEL, CAL_REC_DOWN_LABEL, CAL_REC_EX_LABEL, COMP_REC_LABEL, GEN_OFF_LABEL, DONE_LABEL, ERROR] = enum();
  
  persistent NAME = 'Split-Calibrating PLAY Side';
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
  
  global EXTRA_CIRCUIT_VD;
  global EXTRA_CIRCUIT_LP1;
  
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
    
      case CHECKING_LABEL
        
        global playInfo;
        global recInfo;
        
        addTaskName(NAME);

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

        waitForTaskFinish('measureTransferSched', PASSING_LABEL, ERROR, mfilename());
        return;
        
      case PASSING_LABEL        
        swStruct.calibrate = true;
        % for now calibrating right output channel only
        swStruct.inputR = (playChID == 2);
        swStruct.vd = false;
        swStruct.analysedR = (analysedChID == 2);
        figResult = showSwitchWindow(sprintf('Set switches for LP calibration', analysedChID), swStruct);
        if ~figResult
          label = ERROR;
          continue;
        endif

        clearOutBox();
        printStr(sprintf("Joint-device calibrating LP at current frequency %dHz:", origFreq));
        cmdIDPlay = writeCmd(PASS, cmdFilePlay);
        cmdIDRec = writeCmd(PASS, cmdFileRec);
        % we have to wait for command acceptance before issuing new commands (the cmd files could be deleted by new commands before they are consumed
        % waiting only for one of the pass commands, both sides run at same speed
        % after AUTO_TIMEOUT secs timeout call ERROR
        waitForCmdDone([cmdIDPlay, cmdIDRec], MODE_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case MODE_LABEL
        
        global SET_MODE;
        global CMD_MODE_PREFIX;
        
        % setting MODE_DUAL on both sides
        cmdStr = [SET_MODE ' ' CMD_MODE_PREFIX num2str(MODE_DUAL)];
        cmdIDPlay = writeCmd(cmdStr, cmdFilePlay);
        cmdIDRec = writeCmd(cmdStr, cmdFileRec);
        waitForCmdDone([cmdIDPlay, cmdIDRec], WAIT_FOR_LP_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case WAIT_FOR_LP_LABEL
        % after switching to LPF + mode we have to wait for the new distortions to propagate through the chain. 1 sec should be enough
        schedPause(1, CAL_LP_LABEL, mfilename());
        return;
        

      case CAL_LP_LABEL
        % calibrating LPF at origFreq
        % generator is not strictly required since it generates same signal as currently incoming. But for safety of calibration it is safer to generate our own stable signal
        printStr(sprintf("Generating %dHz", origFreq));
        cmdIDPlay = sendPlayGeneratorCmd(origFreq, origPlayLevels, playEqualizer);
        
        printStr(sprintf("Joint-device calibrating/measuring LP at %dHz", origFreq));
        % deleting the calib file should it exist - always clean calibration
        calFile = genCalFilename(origFreq, fs, COMP_TYPE_JOINT, playChID, analysedChID, MODE_DUAL, EXTRA_CIRCUIT_LP1);
        deleteFile(calFile);
        calFile = genCalFilename(origFreq, fs, COMP_TYPE_JOINT, playChID, getTheOtherChannelID(analysedChID), MODE_DUAL, EXTRA_CIRCUIT_LP1);
        deleteFile(calFile);
        
        % safety measure - requesting calibration only at curFreq
        calFreqReqStr = getCalFreqReqStr({[origFreq, NA, NA]});
        calCmd = [CALIBRATE ' ' calFreqReqStr ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_JOINT) ' ' getMatrixCellsToCmdStr(origPlayLevels, CMD_PLAY_AMPLS_PREFIX) ' ' CMD_EXTRA_CIRCUIT_PREFIX EXTRA_CIRCUIT_LP1];
        cmdIDRec = writeCmd(calCmd, cmdFileRec);
        % next frequency
        waitForCmdDone([cmdIDPlay, cmdIDRec], WAIT_FOR_VD_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case WAIT_FOR_VD_LABEL
        swStruct.vd = true;
        figResult = showSwitchWindow({'Change switch to VD calibration', sprintf('For first freq. adjust level into the shown range for channel ', analysedChID)}, swStruct);
        if ~figResult
          label = ERROR;
          continue;
        endif

        % after switching LPF -> VD we have to wait for the new distortions to propagate through the chain. 1 sec should be enough
        schedPause(1, CAL_VD_LABEL, mfilename());
        return;
        
      case CAL_VD_LABEL
        % VD calibration        
        % we need to read the filter fund level in order to calibrate fundamental to the same level as close as possible for calculation of the splittting
        lpFundAmpl = loadCalFundAmpl(origFreq, fs, playChID, analysedChID, EXTRA_CIRCUIT_LP1);

        clearOutBox();
        
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
        calFile = genCalFilename(origFreq, fs, COMP_TYPE_JOINT, playChID, getTheOtherChannelID(analysedChID), MODE_DUAL, EXTRA_CIRCUIT_VD);
        deleteFile(calFile);

        calCmd = [CALIBRATE ' ' calFreqReqStr  ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_JOINT) ' ' getMatrixCellsToCmdStr(origPlayLevels, CMD_PLAY_AMPLS_PREFIX) ' ' CMD_EXTRA_CIRCUIT_PREFIX EXTRA_CIRCUIT_VD];
              
        cmdIDRec = writeCmd(calCmd, cmdFileRec);
        % long waiting - manual level adjustment
        waitForCmdDone(cmdIDRec, SPLIT_CAL_LABEL, MANUAL_TIMEOUT, ERROR, mfilename());
        return;

      case SPLIT_CAL_LABEL
        % range calibrations finished, closing the zoomed calib plot
        closeCalibPlot();

        clearOutBox();
        printStr(sprintf('Calculating split calibration'));
        calculateSplitCal(origFreq, fs, playChID, analysedChID, MODE_DUAL, EXTRA_CIRCUIT_VD, EXTRA_CIRCUIT_LP1);

        % going to the next label. This could be processed in one label, but separating split calibration from play-side compensation makes the code cleaner
        label = COMP_PLAY_LABEL;
        continue;
        

      case COMP_PLAY_LABEL
        printStr(sprintf('Compensating PLAY side first'));
        cmdIDPlay = writeCmd([COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_PLAY_SIDE)], cmdFilePlay);
        %waitForCmdDone(cmdIDPlay, CAL_REC_UP_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        waitForCmdDone(cmdIDPlay, GEN_OFF_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case {CAL_REC_UP_LABEL, CAL_REC_DOWN_LABEL, CAL_REC_EX_LABEL}
        switch label
          case CAL_REC_UP_LABEL           
            expl = 'upper limit';
            adjustment = CAL_LEVEL_STEP;
            
          case CAL_REC_DOWN_LABEL
            expl = 'lower limit';
            adjustment = 1/CAL_LEVEL_STEP;
            
          case CAL_REC_EX_LABEL
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
        
      case COMP_REC_LABEL
        clearOutBox();
        
        % all calibrations finished, closing the zoomed calib plot
        closeCalibPlot();
        
        printStr(sprintf('Compensating SPLIT REC side'));
        cmdID = writeCmd([COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_REC_SIDE)], cmdFileRec);
        waitForCmdDone(cmdID, GEN_OFF_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case GEN_OFF_LABEL
        cmdID = sendStopGeneratorCmd();
        waitForCmdDone(cmdID, DONE_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;

      case DONE_LABEL
        swStruct.calibrate = false;
        showSwitchWindow('Set switches for measuring DUT', swStruct');
        break;
        
      case ERROR
        msg = 'Timeout waiting for command done or function aborted, exiting splitting calibration';
        printStr(msg);
        writeLog('INFO', msg);
        sendStopGeneratorCmd();
        result = false;
        removeTaskName(NAME);        
        return;
    endswitch
  endwhile
  printStr('Calibration finished, both sides compensating, measuring');  
  result = true;
  removeTaskName(NAME);
endfunction