% scheduler-enabled function for setting balanced levels with stepper
% result: NA = not finished yet, false = error/failed, true = finished OK
function result = setBalVDLevelsSched(label = 1)
  result = NA;
  % init section
  [START_LABEL, ADJUST_PLUS, ADJUST_MINUS, DONE_LABEL, FINISH_DONE_LABEL, ERROR] = enum();
  
  persistent NAME = 'Setting balanced VD level';
  persistent AUTO_TIMEOUT = 10;
  persistent MAX_AMPL_DIFF = db2mag(-80);

  global ABORT;
  
  global adapterStruct;
  persistent wasAborted = false;

  while true
    switch(label)

      case START_LABEL
        addTask(mfilename(), NAME);
        % init value
        wasAborted = false;

        % adapterStruct.reqBalVDLevels must be already set
        if isempty( adapterStruct.reqBalVDLevels)
          label = ABORT;
          continue;
        end


        % for restoration at the end
        keepInOutSwitches();

        adapterStruct.in = false; % CALIB IN
        adapterStruct.vdLpf = false; % VD
        if isempty(adapterStruct.maxAmplDiff)
          % default value
          adapterStruct.maxAmplDiff = MAX_AMPL_DIFF;
        end
        label = ADJUST_PLUS;

      case ADJUST_PLUS
        % plus line with VD1 - default for balanced mode
        adapterStruct.vd = 1;
        adapterStruct.stepperToMove = 1;
        adapterStruct.reqVDLevel = adapterStruct.reqBalVDLevels(1);
        % grounded minus line
        adapterStruct.groundPlus = false;
        adapterStruct.groundMinus = true;
        waitForAdapterAdjust('Set switches for plus-line level measurement through VD1',
          adapterStruct, ADJUST_MINUS, ABORT, ERROR, mfilename());
        return;

      case ADJUST_MINUS
        % minus line with moving VD2 (but vd kept at 1)
        adapterStruct.stepperToMove = 2;
        adapterStruct.reqVDLevel = adapterStruct.reqBalVDLevels(2);
        % grounded plus line
        adapterStruct.groundPlus = true;
        adapterStruct.groundMinus = false;
        waitForAdapterAdjust('Set switches for minus-line level measurement through VD2',
          adapterStruct, DONE_LABEL, ABORT, ERROR, mfilename());
        return;

      case ABORT
        wasAborted= true;
        label = DONE_LABEL;

      case DONE_LABEL
        % restoring switches
        resetAdapterStruct();
        % returning to VD1 which is for balanced VD
        adapterStruct.vd = 1;
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