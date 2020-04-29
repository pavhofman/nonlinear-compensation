% scheduler-enabled function for testing automated VD level adjustment with stepper
% result: NA = not finished yet, false = error/failed, true = finished OK
function result = setVDLevelSched(label = 1)
  result = NA;
  % init section
  [START_LABEL, ALL_OFF_LABEL, DONE_LABEL, FINISH_DONE_LABEL, ERROR] = enum();
  
  persistent NAME = 'Setting VD level';
  persistent AUTO_TIMEOUT = 10;

  global ABORT;
  
  global adapterStruct;
  persistent wasAborted = false;

  while true
    switch(label)

      case START_LABEL
        addTask(mfilename(), NAME);
        % init value
        wasAborted = false;

        adapterStruct.in = false; % CALIB IN
        adapterStruct.calibLPF = false; % VD
        % VD as currently selected

        % adapterStruct.reqLevels already set from the txt input

        if isempty(adapterStruct.maxAmplDiff)
          % default value
          adapterStruct.maxAmplDiff = db2mag(-80);
        endif

        waitForAdapterAdjust('Set switches for calibration through VD', 
          adapterStruct, DONE_LABEL, ABORT, ERROR, mfilename());
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
        if wasAborted
          result = false;
        else
          printStr('Setting VD level finished');
          result = true;
        endif
        break;
        
      case ERROR
        msg = 'Timeout waiting for command done, exiting setting VD level';
        printStr(msg);
        writeLog('INFO', msg);
        errordlg(msg);
        result = false;
        break;        
    endswitch
  endwhile

  removeTask(mfilename(), NAME);
  
endfunction