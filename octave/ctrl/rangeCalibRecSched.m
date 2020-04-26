% scheduler-enabled function for range-calibration of REC side
% Range calibration calibrates at higher, lower, and exact level of the original signal to provide lines in calFile for interpolation
% Not using generator
% result: NA = not finished yet, false = error/failed, true = finished OK
% If PLAY-side not compensating, running joint-sides calibration, otherwise REC-side calibration
function result = rangeCalibRecSched(label = 1)
  result = NA;
  % init section
  [CHECKING_LABEL, START_LABEL, MODE_LABEL, ADJ_LABEL, CAL_LABEL,...
      COMP_REC_LABEL, DONE_LABEL, FINISH_DONE_LABEL, ERROR] = enum();

  persistent NAME = 'Range-Calibrating REC Side';
  persistent AUTO_TIMEOUT = 10;
  % manual calibration timeout - enough time to adjust the level into the range limits
  persistent MANUAL_TIMEOUT = 500;
  
  % step above and below exact calibration level to also calibrate for interpolation
  persistent CAL_LEVEL_STEP = db2mag(-58);

  % format [adjustment1, maxAmplDiff1; adjustment2, maxAmplDiff2;...]
  % For production operation the sequence should be in one direction (up, exact, down) do speed-up level setup (clearing backlash only once).
  % But that means the last VD position will leave it at level not equal to input level, complicating testing
  % For testing let's use the suboptimal sequence with exact level as last.
  persistent STEPS = [...
    % up
    % 2 * CAL_LEVEL_STEP,   db2mag(-75);...
    CAL_LEVEL_STEP,   db2mag(-75);...
    % down
    -CAL_LEVEL_STEP, db2mag(-75);...
    % -2 * CAL_LEVEL_STEP, db2mag(-75);...
    % very exact value
    0,                db2mag(-85);...
  ];

  
  % analysed input ch goes through LPF or VD, the other input channel is direct
  global ANALYSED_CH_ID;

  global cmdFileRec;
  global cmdFilePlay;
  global CALIBRATE;
  global COMPENSATE;
  global CMD_COMP_TYPE_PREFIX;

  global MODE_DUAL;
  global ABORT;
  
 
  % current frequency of calibration
  % all set in first P1 branch
  persistent fs = NA;
  persistent origFreq = NA;
  persistent origRecLevel = NA;
  persistent maxAmplDiff = NA;
  persistent adjustment = NA;
  persistent calFreqReq = NA;
  persistent stepID = 1;

  persistent compenType = NA;

  global adapterStruct;
  persistent wasAborted = false;

  while true
    switch(label)
    
      case CHECKING_LABEL
        global recInfo;
        
        addTask(mfilename(), NAME);

        % init values
        wasAborted = false;
        stepID = 1;
        
        % loading current values from analysis
        fs = recInfo.fs;
        origFreq = recInfo.measuredPeaks{ANALYSED_CH_ID}(1, 1);
        origRecLevel = recInfo.measuredPeaks{ANALYSED_CH_ID}(:, 2);

        label = START_LABEL;
        continue;
        
      case START_LABEL
        clearOutBox();
        % for restoration at the end
        keepInOutSwitches();

        % OUT unchanged
        adapterStruct.in = false; % CALIB IN
        adapterStruct.calibLPF = false; % VD
        % VD for input level
        adapterStruct.vd = adapterStruct.vdForInput;

        adapterStruct.reqLevels = []; % no stepper adjustment
        adapterStruct.maxAmplDiff = [];
        waitForAdapterAdjust(sprintf('Set switches for CH%d calibration through VD', ANALYSED_CH_ID),
          adapterStruct, MODE_LABEL, ABORT, ERROR, mfilename());
        return;

      case MODE_LABEL
        
        global SET_MODE;
        global CMD_MODE_PREFIX;
        
        % setting MODE_DUAL on both sides
        cmdStr = [SET_MODE ' ' CMD_MODE_PREFIX num2str(MODE_DUAL)];
        cmdIDPlay = writeCmd(cmdStr, cmdFilePlay);
        cmdIDRec = writeCmd(cmdStr, cmdFileRec);
        waitForCmdDone([cmdIDPlay, cmdIDRec], ADJ_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        

      case ADJ_LABEL
        % params for this step
        adjustment = STEPS(stepID, 1);
        maxAmplDiff = STEPS(stepID, 2);

        printStr('Calibrating REC side at CH%d level - adj %f, maxAmplDiff %f', ANALYSED_CH_ID, adjustment, maxAmplDiff);
        
        adapterStruct.reqLevels = (1 + adjustment) * origRecLevel;
        % level needs to be set slightly more precisely than calibration request to account for possible tiny level drift before calibration
        adapterStruct.maxAmplDiff = maxAmplDiff * 0.9;

        % including mid ampl only for exact value
        calFreqReq = getConstrainedLevelCalFreqReq(adapterStruct.reqLevels, origFreq, ANALYSED_CH_ID, adapterStruct.maxAmplDiff, adjustment == 0);

        % zooming calibration levels + plotting the range so that user can adjust precisely
        % target level = orig Rec level (not the increased range)
        zoomCalLevels(calFreqReq, getTargetLevelsForAnalysedCh(origRecLevel, ANALYSED_CH_ID));


        % scheduled adjusting level
        waitForTaskFinish('setVDLevelSched', CAL_LABEL, ABORT, mfilename());
        return;
        
      case CAL_LABEL
        % amplitude-constrained calibration

        % loop for all STEPS
        if stepID < rows(STEPS)
          % looping for next calibration step
          nextLabel = ADJ_LABEL;
          ++stepID;
        else
          % will continue after calibration
          nextLabel = COMP_REC_LABEL;
        endif


        % determining compensation type - rec-side if compensation running on PLAY side, otherwise joint-sides
        global playInfo;
        global COMP_TYPE_JOINT;
        global COMP_TYPE_REC_SIDE;
        compenType = ifelse(structContains(playInfo.status, COMPENSATE), COMP_TYPE_REC_SIDE, COMP_TYPE_JOINT);


        calFreqReqStr = getCalFreqReqStr(calFreqReq);
        cmdID = writeCmd([CALIBRATE ' ' calFreqReqStr ' ' CMD_COMP_TYPE_PREFIX num2str(compenType)], cmdFileRec);
        waitForCmdDone(cmdID, nextLabel, MANUAL_TIMEOUT, ERROR, mfilename());
        return;
        
      case COMP_REC_LABEL
        % all calibrations finished, closing the zoomed calib plot
        closeCalibPlot();

        printStr('Compensating REC side');
        cmdID = writeCmd([COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(compenType)], cmdFileRec);
        waitForCmdDone(cmdID, DONE_LABEL, AUTO_TIMEOUT, ERROR, mfilename());
        return;
        
      case ABORT
        wasAborted= true;
        label = DONE_LABEL;
        continue;

      case DONE_LABEL
        % plus restoring IN/OUT switches
        resetAdapterStruct();
        waitForAdapterAdjust('Restore switches', adapterStruct, FINISH_DONE_LABEL, FINISH_DONE_LABEL, ERROR, mfilename());
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