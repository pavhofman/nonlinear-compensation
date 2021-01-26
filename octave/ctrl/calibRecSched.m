% scheduler-enabled function for calibration of REC side
% Range calibration calibrates at steps level of the original signal to provide lines in calFile for interpolation
% Not using generator
% result: NA = not finished yet, false = error/failed, true = finished OK
% If PLAY-side not compensating, running joint-sides calibration, otherwise REC-side calibration
function result = calibRecSched(label, steps, schedFilename, name)
  result = NA;
  % init section
  [CHECKING_LABEL, MEASURE_LEVELS, SWITCH_TO_VD_LABEL, ADJ_LABEL, ADJUST_VD_SE, ADJUST_VD_BAL, CAL_LABEL,...
      COMP_REC_LABEL, DONE_LABEL, FINISH_DONE_LABEL, ERROR] = enum();

  persistent AUTO_TIMEOUT = 10;
  % manual calibration timeout - enough time to adjust the level into the range limits
  persistent MANUAL_TIMEOUT = 500;

  
  % analysed input ch goes through LPF or VD, the other input channel is direct
  global ANALYSED_CH_ID;

  global cmdFileRec;
  global cmdFilePlay;
  global adapterStruct;
  global CALIBRATE;
  global COMPENSATE;
  global CMD_COMP_TYPE_PREFIX;
  global ABORT;


  % current frequency of calibration
  % all set in first P1 branch
  persistent fs = NA;
  persistent origFreq = NA;
  persistent origRecLevel = NA;
  persistent calibVDLevel = NA;
  persistent maxAmplDiff = NA;
  persistent adjustment = NA;
  persistent calFreqReq = NA;
  persistent stepID = 1;

  persistent compenType = NA;

  persistent wasAborted = false;

  while true
    switch(label)
    
      case CHECKING_LABEL
        global recInfo;
        
        addTask(schedFilename, name);

        % init values
        wasAborted = false;
        stepID = 1;
        
        % loading current values from analysis
        fs = recInfo.fs;
        origFreq = recInfo.measuredPeaks{ANALYSED_CH_ID}(1, 1);

        label = MEASURE_LEVELS;
        % continue;

      case MEASURE_LEVELS
        origRecLevel = recInfo.measuredPeaks{ANALYSED_CH_ID}(1, 2);

        if adapterStruct.isSE
          % SE mode - VD must be set to measured amplitude, that is already stored in origRecLevel
          label = SWITCH_TO_VD_LABEL;
          % continue
        else
          % balanced mode requires measuring +/- level to adjust VD
          % measureBalLevelsSched stores the measured results to adapterStruct.curBalLevels
          % (same format as adapterStruct.reqBalVDLevels)
          waitForTaskFinish('measureBalLevelsSched', SWITCH_TO_VD_LABEL, ABORT, schedFilename);
          return;
        end

      case SWITCH_TO_VD_LABEL
        clearOutBox();
        % for restoration at the end
        keepInOutSwitches();

        % OUT unchanged
        adapterStruct.in = false; % CALIB IN
        adapterStruct.vdLpf = false; % VD
        label = ADJ_LABEL;
        % continue

      case ADJ_LABEL
        % reqLevel: one amplitude only
        % If empty, no stepper adjustment
        adapterStruct.reqVDLevel = []; % no stepper adjustment
        adapterStruct.reqBalVDLevels = [];
        adapterStruct.maxAmplDiff = [];

        % params for this step
        adjustment = steps(stepID, 1);
        maxAmplDiff = steps(stepID, 2);

        % calibration is perfomed at adjusted origRecLevel
        calibVDLevel = (1 + adjustment) * origRecLevel;

        % level needs to be set slightly more precisely than calibration request to account for possible tiny level drift before calibration
        adapterStruct.maxAmplDiff = maxAmplDiff * 0.9;
        printStr('Calibrating REC side at CH%d level - adj %f, maxAmplDiff %f', ANALYSED_CH_ID, adjustment, maxAmplDiff);

        % including mid ampl only for exact value (only shown by UI, calibration does not use it)
        calFreqReq = getConstrainedLevelCalFreqReq(calibVDLevel, origFreq, ANALYSED_CH_ID, adapterStruct.maxAmplDiff, adjustment == 0);

        % zooming calibration levels + plotting the range so that user can adjust precisely
        % target level = orig Rec level (not the increased range calibVDLevel)
        zoomCalLevels(calFreqReq, getTargetLevelsForAnalysedCh(origRecLevel, ANALYSED_CH_ID));

        if adapterStruct.isSE
          label = ADJUST_VD_SE;
        else
          label = ADJUST_VD_BAL;
        end
        % continue

      case ADJUST_VD_SE
        % SE
        adapterStruct.reqVDLevel = calibVDLevel;
        % VD for input level
        adapterStruct.vd = adapterStruct.vdForInput;

        waitForAdapterAdjust(
          sprintf('Change switch to VD calibration. Adjust captured level to %s for channel %d', getAdapterLevelRangeStr(adapterStruct), ANALYSED_CH_ID),
          adapterStruct, CAL_LABEL, ABORT, ERROR, schedFilename);
        return;

      case ADJUST_VD_BAL
        % VD for input level
        adapterStruct.vd = 1;

        % curBalLevels set by measureBalLevelsSched
        adapterStruct.reqBalVDLevels = (1 + adjustment) * adapterStruct.curBalLevels;
        waitForTaskFinish('setBalVDLevelsSched', CAL_LABEL, ABORT, schedFilename);
        return;

      case CAL_LABEL
        % amplitude-constrained calibration

        % loop for all steps
        if stepID < rows(steps)
          % looping for next calibration step
          nextLabel = ADJ_LABEL;
          ++stepID;
        else
          % will continue after calibration
          nextLabel = COMP_REC_LABEL;
        end


        % determining compensation type - rec-side if compensation running on PLAY side, otherwise joint-sides
        global playInfo;
        global COMP_TYPE_JOINT;
        global COMP_TYPE_REC_SIDE;
        global COMPENSATING;
        compenType = ifelse(structContains(playInfo.status, COMPENSATING), COMP_TYPE_REC_SIDE, COMP_TYPE_JOINT);
        writeLog('DEBUG', 'Calibrating compensation type: %d', compenType);


        calFreqReqStr = getCalFreqReqStr(calFreqReq);
        cmdID = writeCmd([CALIBRATE ' ' calFreqReqStr ' ' CMD_COMP_TYPE_PREFIX num2str(compenType)], cmdFileRec);
        waitForCmdDone(cmdID, nextLabel, MANUAL_TIMEOUT, ERROR, schedFilename);
        return;
        
      case COMP_REC_LABEL
        % all calibrations finished, closing the zoomed calib plot
        closeCalibPlot();

        printStr('Compensating REC side');
        cmdID = writeCmd([COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(compenType)], cmdFileRec);
        waitForCmdDone(cmdID, DONE_LABEL, AUTO_TIMEOUT, ERROR, schedFilename);
        return;
        
      case ABORT
        wasAborted= true;
        label = DONE_LABEL;
        % continue;

      case DONE_LABEL
        % plus restoring IN/OUT switches
        resetAdapterStruct();
        waitForAdapterAdjust('Restore switches', adapterStruct, FINISH_DONE_LABEL, FINISH_DONE_LABEL, ERROR, schedFilename);
        return;

      case FINISH_DONE_LABEL
        % clearing the label
        adapterStruct.label = '';
        updateAdapterPanel();

        if wasAborted
          result = false;
        else
          printStr('Range-calibrating REC side finished');  
          result = true;
        end
        break;
        
      case ERROR
        msg = 'Timeout waiting for command done, exiting range-calibration of REC side';
        printStr(msg);
        writeLog('INFO', msg);
        errordlg(msg);
        result = false;
        break;        
    end
  end
  
  % just in case the task was aborted with calib plot zoomed in
  closeCalibPlot();
  removeTask(schedFilename, name);
  
end