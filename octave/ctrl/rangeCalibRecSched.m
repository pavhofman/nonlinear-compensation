% scheduler-enabled function for range-calibration of REC side
% Range calibration calibrates at higher, lower, and exact level of the original signal to provide lines in calFile for interpolation
% result: NA = not finished yet, false = error/failed, true = finished OK
function result = rangeCalibRecSched(label = 1)
  result = NA;
  % init section
  [CHECKING_LABEL, START_LABEL, MODE_LABEL, COMP_PLAY_LABEL, ...
      CAL_REC_UP_LABEL, CAL_REC_DOWN_LABEL, CAL_REC_EX_LABEL, COMP_REC_LABEL, ALL_OFF_LABEL, DONE_LABEL, ERROR] = enum();
  
  persistent NAME = 'Range-Calibrating REC Side';
  persistent AUTO_TIMEOUT = 10;
  % manual calibration timeout - enough time to adjust the level into the range limits
  persistent MANUAL_TIMEOUT = 500;
  
  % step above and below exact calibration level to also calibrate for interpolation
  persistent CAL_LEVEL_STEP = db2mag(0.05);
  
  % analysed input ch goes through LP or VD, the other input channel is direct
  global ANALYSED_CH_ID;

  % ID of output channel used for split calibration
  global PLAY_CH_ID;
  
  global cmdFileRec;
  global cmdFilePlay;
  global GENERATE;
  global PASS;
  global CALIBRATE;
  global COMPENSATE;
  global CMD_CHANNEL_FUND_PREFIX;
  global CMD_COMP_TYPE_PREFIX;
  global CMD_PLAY_AMPLS_PREFIX;
  global COMP_TYPE_JOINT;
  global COMP_TYPE_PLAY_SIDE;
  global COMP_TYPE_REC_SIDE;
  
  global MODE_DUAL;
  global ABORT;
  
 
  % current frequency of calibration
  % all set in first P1 branch
  persistent curFreq = NA;
  persistent fs = NA;
  persistent origFreq = NA;
  persistent origRecLevel = NA;
  persistent origPlayLevels = NA;
  persistent playEqualizer = NA;
  
  persistent swStruct = initSwitchStruct();
  persistent wasAborted = false;

  while true
    switch(label)
    
      case CHECKING_LABEL
        
        global playInfo;
        global recInfo;
        
        addTask(mfilename(), NAME);
        % init value
        wasAborted = false;
        
        % loading current values from analysis
        fs = recInfo.fs;
        origFreq = recInfo.measuredPeaks{ANALYSED_CH_ID}(1, 1);
        origRecLevel = recInfo.measuredPeaks{ANALYSED_CH_ID}(:, 2);
        % two channels, any freqs
        origPlayLevels = {playInfo.measuredPeaks{1}(:, 2), playInfo.measuredPeaks{2}(:, 2)};
        
        % playLevels are measured BEHIND equalizer in play process. When generating, one must take the equalizer into account to reach identical play levels
        % only values for first two channels to fit origPlayLevels
        playEqualizer = playInfo.equalizer(1:2);
        label = START_LABEL;
        continue;
        
      case START_LABEL
        swStruct.calibrate = true;
        % for now calibrating right output channel only
        swStruct.inputR = (PLAY_CH_ID == 2);
        swStruct.vd = true;
        swStruct.analysedR = (ANALYSED_CH_ID == 2);
        figResult = showSwitchWindow(sprintf('Set switches for calibration through VD', ANALYSED_CH_ID), swStruct);
        if ~figResult
          label = ABORT;
          continue;
        endif
        label = MODE_LABEL;
        continue;
        
      case MODE_LABEL
        
        global SET_MODE;
        global CMD_MODE_PREFIX;
        
        % setting MODE_DUAL on both sides
        cmdStr = [SET_MODE ' ' CMD_MODE_PREFIX num2str(MODE_DUAL)];
        cmdIDPlay = writeCmd(cmdStr, cmdFilePlay);
        cmdIDRec = writeCmd(cmdStr, cmdFileRec);
        waitForCmdDone([cmdIDPlay, cmdIDRec], COMP_PLAY_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        

      case COMP_PLAY_LABEL
        printStr(sprintf('Compensating PLAY side first'));
        cmdIDPlay = writeCmd([COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_PLAY_SIDE)], cmdFilePlay);
        waitForCmdDone(cmdIDPlay, CAL_REC_UP_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
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
        
        printStr(sprintf('Calibrating REC side at original recLevel of channel %d - %s', ANALYSED_CH_ID, expl));
        
        % amplitude-constrained calibration
        % TODO - for now using lpFundAmpl instead of origRecLevel to allow easy switching between LP and VD for result checking
        % calFreqReq = getConstrainedLevelCalFreqReq(origRecLevel * adjustment, origFreq, ANALYSED_CH_ID);
        
        % max. allowed deviation in each direction from midAmpl
        % the tolerance really does not matter much here
        calTolerance = db2mag(0.05);

        % including mid ampl only for exact value
        calFreqReq = getConstrainedLevelCalFreqReq(origRecLevel * adjustment, origFreq, ANALYSED_CH_ID, calTolerance, adjustment == 1);
        calFreqReqStr = getCalFreqReqStr(calFreqReq);
        % zooming calibration levels + plotting the range so that user can adjust precisely
        % target level = orig Rec level (not the increased range)
        % zoomCalLevels(calFreqReq, getTargetLevelsForAnalysedCh(origRecLevel, ANALYSED_CH_ID));
        zoomCalLevels(calFreqReq, getTargetLevelsForAnalysedCh(origRecLevel, ANALYSED_CH_ID));
        
        cmdID = writeCmd([CALIBRATE ' ' calFreqReqStr ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_REC_SIDE)], cmdFileRec);
        waitForCmdDone(cmdID, label + 1, MANUAL_TIMEOUT, ERROR, mfilename());
        return;
        
      case COMP_REC_LABEL
        clearOutBox();
        
        % all calibrations finished, closing the zoomed calib plot
        closeCalibPlot();
        
        printStr(sprintf('Compensating SPLIT REC side'));
        cmdID = writeCmd([COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_REC_SIDE)], cmdFileRec);
        waitForCmdDone(cmdID, ALL_OFF_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case ABORT
        wasAborted= true;
        label = ALL_OFF_LABEL;
        continue;

      case ALL_OFF_LABEL
        cmdIDs = sendAllOffCmds();
        if ~isempty(cmdIDs)
          waitForCmdDone(cmdIDs, DONE_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
          return;
        else
          label = DONE_LABEL;
          continue;
        endif

      case DONE_LABEL
        swStruct.calibrate = false;
        showSwitchWindow('Set switches for measuring DUT', swStruct');
        if wasAborted
          result = false;
        else
          printStr('Range-calibrating REC side finished');  
          result = true;
        endif
        break;
        
      case ERROR
        msg = 'Timeout waiting for command done, exiting range-calibration of REC side';
        printStr(msg);
        writeLog('INFO', msg);
        errordlg(msg);
        result = false;
        break;        
    endswitch
  endwhile
  
  % just in case the task was aborted with calib plot zoomed in
  closeCalibPlot();
  removeTask(mfilename(), NAME);
  
endfunction