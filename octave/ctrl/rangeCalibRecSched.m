% scheduler-enabled function for range-calibration of REC side
% Range calibration calibrates at higher, lower, and exact level of the original signal to provide lines in calFile for interpolation
% Not using generator
% result: NA = not finished yet, false = error/failed, true = finished OK
function result = rangeCalibRecSched(label = 1)
  result = NA;
  % init section
  [CHECKING_LABEL, START_LABEL, MODE_LABEL, COMP_PLAY_LABEL, ...
      ADJ_REC_UP_LABEL, ADJ_REC_DOWN_LABEL, ADJ_REC_EX_LABEL,...
      CAL_REC_UP_LABEL, CAL_REC_DOWN_LABEL, CAL_REC_EX_LABEL,...
      COMP_REC_LABEL, ALL_OFF_LABEL, DONE_LABEL, FINISH_DONE_LABEL, ERROR] = enum();
  
  persistent NAME = 'Range-Calibrating REC Side';
  persistent AUTO_TIMEOUT = 10;
  % manual calibration timeout - enough time to adjust the level into the range limits
  persistent MANUAL_TIMEOUT = 500;
  
  % step above and below exact calibration level to also calibrate for interpolation
  persistent CAL_LEVEL_STEP = db2mag(0.05);
  
  % analysed input ch goes through LP or VD, the other input channel is direct
  global ANALYSED_CH_ID;

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
  persistent maxAmplDiff = NA;
  persistent adjustment = NA;

  global adapterStruct;
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
        
        label = START_LABEL;
        continue;
        
      case START_LABEL
        clearOutBox();
        adapterStruct.calibrate = true; % IN calib
        adapterStruct.vd = true; % VD
        adapterStruct.reqLevels = []; % no stepper adjustment
        adapterStruct.maxAmplDiff = [];
        waitForAdapterAdjust(sprintf('Set switches for calibration through VD', ANALYSED_CH_ID),
          adapterStruct, MODE_LABEL, ABORT, ERROR, mfilename());
        return;

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
        printStr('Compensating PLAY side first');
        cmdIDPlay = writeCmd([COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_PLAY_SIDE)], cmdFilePlay);
        waitForCmdDone(cmdIDPlay, ADJ_REC_UP_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case {ADJ_REC_UP_LABEL, ADJ_REC_DOWN_LABEL, ADJ_REC_EX_LABEL}
        switch label
          case ADJ_REC_UP_LABEL           
            expl = 'upper limit';
            adjustment = CAL_LEVEL_STEP;
            % approximate value
            maxAmplDiff = db2mag(-75);
            nextLabel = CAL_REC_UP_LABEL;
            
          case ADJ_REC_DOWN_LABEL
            expl = 'lower limit';
            adjustment = 1/CAL_LEVEL_STEP;
            % approximate value
            maxAmplDiff = db2mag(-75);
            nextLabel = CAL_REC_DOWN_LABEL;

          case ADJ_REC_EX_LABEL
            % last run at exact value - for now
            expl = 'exact value';
            adjustment = 1;
            % better fit for exact value
            maxAmplDiff = db2mag(-85);
            nextLabel = CAL_REC_EX_LABEL;
        endswitch
        
        printStr('Calibrating REC side at original recLevel of channel %d - %s', ANALYSED_CH_ID, expl);
        
        adapterStruct.calibrate = true;
        adapterStruct.vd = true;
        adapterStruct.reqLevels = origRecLevel * adjustment;
        adapterStruct.maxAmplDiff = maxAmplDiff;
        % adjusting level
        waitForTaskFinish('setVDLevelSched', nextLabel, ABORT, mfilename());
        return;
        
      case {CAL_REC_UP_LABEL, CAL_REC_DOWN_LABEL, CAL_REC_EX_LABEL}
        switch label
          case CAL_REC_UP_LABEL
            nextLabel = ADJ_REC_DOWN_LABEL;
          
          case CAL_REC_DOWN_LABEL
            nextLabel = ADJ_REC_EX_LABEL;

          case CAL_REC_EX_LABEL
            nextLabel = COMP_REC_LABEL;
        endswitch
        
        % amplitude-constrained calibration
        % TODO - for now using lpFundAmpl instead of origRecLevel to allow easy switching between LP and VD for result checking

        % max. allowed deviation in each direction from midAmpl
        % the tolerance really does not matter much here

        % including mid ampl only for exact value
        calFreqReq = getConstrainedLevelCalFreqReq(adapterStruct.reqLevels, origFreq, ANALYSED_CH_ID, adapterStruct.maxAmplDiff, adjustment == 1);
        calFreqReqStr = getCalFreqReqStr(calFreqReq);
        % zooming calibration levels + plotting the range so that user can adjust precisely
        % target level = orig Rec level (not the increased range)
        % zoomCalLevels(calFreqReq, getTargetLevelsForAnalysedCh(origRecLevel, ANALYSED_CH_ID));
        zoomCalLevels(calFreqReq, getTargetLevelsForAnalysedCh(origRecLevel, ANALYSED_CH_ID));
        
        cmdID = writeCmd([CALIBRATE ' ' calFreqReqStr ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_REC_SIDE)], cmdFileRec);
        waitForCmdDone(cmdID, nextLabel, MANUAL_TIMEOUT, ERROR, mfilename());
        return;
        
      case COMP_REC_LABEL
        % all calibrations finished, closing the zoomed calib plot
        closeCalibPlot();
        
        printStr('Compensating SPLIT REC side');
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
        adapterStruct.out = true; % OUT on
        adapterStruct.calibrate = false; % IN DUT
        adapterStruct.vd = false; % LPF
        adapterStruct.reqLevels = []; % no stepper
        adapterStruct.maxAmplDiff = [];
        waitForAdapterAdjust('Set switches for measuring DUT', adapterStruct, FINISH_DONE_LABEL, FINISH_DONE_LABEL, ERROR, mfilename());
        return;

      case FINISH_DONE_LABEL
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