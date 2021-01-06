% scheduler-enabled function for testing automated VD level adjustment with stepper
% result: NA = not finished yet, false = error/failed, true = finished OK
function result = setVDLevelSched(label = 1)
  result = NA;
  % init section
  [START_LABEL, DONE_LABEL, FINISH_DONE_LABEL, ERROR] = enum();
  
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

        % for restoration at the end
        keepInOutSwitches();

        adapterStruct.in = false; % CALIB IN
        adapterStruct.calibLPF = false; % VD
        % VD as currently selected

        % adapterStruct.reqLevels already set from the txt input

        if isempty(adapterStruct.maxAmplDiff)
          % default value
          adapterStruct.maxAmplDiff = db2mag(-80);
        end

        waitForAdapterAdjust('Set switches for calibration through VD', 
          adapterStruct, DONE_LABEL, ABORT, ERROR, mfilename());
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
          printStr('Setting VD level finished');
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
    endswitch
  end

  removeTask(mfilename(), NAME);
  
end