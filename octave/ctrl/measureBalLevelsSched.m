% scheduler-enabled function for measuring current levels on +/- input
% measured results are stored to global adapterStruct.curBalLevels
% result: NA = not finished yet, false = error/failed, true = finished OK
function result = measureBalLevelsSched(label = 1)
  result = NA;
  % init section
  [START_LABEL, SET_PLUS, WAIT_FOR_STABLE_PLUS, STORE_PLUS, SET_MINUS, WAIT_FOR_STABLE_MINUS, STORE_MINUS, DONE_LABEL, FINISH_DONE_LABEL, ERROR] = enum();
  
  persistent NAME = 'Measuring balanced level';
  persistent STABILIZATION_TIMEOUT = 1000;
  persistent MAX_AMPL_DIFF = db2mag(-80);

  global ABORT;
  global adapterStruct;
  global ANALYSED_CH_ID;
  global recInfo;

  persistent wasAborted = false;

  while true
    switch(label)

      case START_LABEL
        addTask(mfilename(), NAME);
        % init value
        wasAborted = false;
        label = SET_PLUS;

      case SET_PLUS
        % grounded minus line
        adapterStruct.gndPlus = false;
        adapterStruct.gndMinus = true;
        waitForAdapterAdjust('Set switches for plus-line level measurement',
          adapterStruct, WAIT_FOR_STABLE_PLUS, ABORT, ERROR, mfilename());
        return;

      case WAIT_FOR_STABLE_PLUS
        writeLog('Waiting for +IN stable levels');
        % possible change in levels, requesting reset of historic peaks
        adapterStruct.resetPrevMeasPeaks = true;
        waitForStableLevels(STORE_PLUS, STABILIZATION_TIMEOUT, ABORT, mfilename());
        return;
        
      case STORE_PLUS
        measPeaksCh = recInfo.measuredPeaks{ANALYSED_CH_ID};
        level = measPeaksCh(1, 2);
        adapterStruct.curBalLevels = [level, 0];
        writeLog('DEBUG', 'Current +IN level measured: %f', level)
        label = SET_MINUS;

      case SET_MINUS
        % grounded plus line
        adapterStruct.gndPlus = true;
        adapterStruct.gndMinus = false;
        waitForAdapterAdjust('Set switches for minus-line level measurement',
          adapterStruct, WAIT_FOR_STABLE_MINUS, ABORT, ERROR, mfilename());
        return;

      case WAIT_FOR_STABLE_MINUS
        writeLog('Waiting for -IN stable levels');
        % possible change in levels, requesting reset of historic peaks
        adapterStruct.resetPrevMeasPeaks = true;
        waitForStableLevels(STORE_MINUS, STABILIZATION_TIMEOUT, ABORT, mfilename());
        return;

      case STORE_MINUS
        measPeaksCh = recInfo.measuredPeaks{ANALYSED_CH_ID};
        % second index
        level = measPeaksCh(1, 2);
        adapterStruct.curBalLevels(2) = level;
        writeLog('DEBUG', 'Current -IN level measured: %f', level)
        label = DONE_LABEL;

      case ABORT
        wasAborted= true;
        label = DONE_LABEL;

      case DONE_LABEL
        % restoring switches
        adapterStruct.gndPlus = false;
        adapterStruct.gndMinus = false;
        waitForAdapterAdjust('Restore switches', adapterStruct, FINISH_DONE_LABEL, FINISH_DONE_LABEL, ERROR, mfilename());
        return;

      case FINISH_DONE_LABEL
        % clearing the label
        adapterStruct.label = '';
        updateAdapterPanel();
        if wasAborted
          result = false;
        else
          printStr('Setting BAL VD levels finished');
          result = true;
        end
        break;
        
      case ERROR
        msg = 'Timeout waiting for command done, exiting setting VD level';
        printStr(msg);
        writeLog('INFO', msg);
        errordlg(msg);
        result = false;
        break;        
    end
  end

  removeTask(mfilename(), NAME);
  
end