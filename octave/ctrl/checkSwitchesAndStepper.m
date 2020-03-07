% checkFunc for tasks
function schedTask = checkSwitchesAndStepper(recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask)
  global adapterStruct;
  persistent checkingStepper = false;

  % empty = not waiting for CHANGE_PROPAGATION_DELAY
  persistent lastCheckTime = [];
  % delay to wait before checking stepper after changed switches
  persistent CHANGE_PROPAGATION_DELAY = 0.5;

  % first checking whether switches are already set
  if adapterStruct.switchesSet
    % switches set (CONTINUE button or relays set), can continue
    % resetting flag
    adapterStruct.switchesSet = false;
    if adapterStruct.switchesChanged
      % possible change in levels, requesting reset of historic peaks
      adapterStruct.resetPrevMeasPeaks = true;
      % waiting for CHANGE_PROPAGATION_DELAY
      lastCheckTime = time();

      % resetting flag
      adapterStruct.switchesChanged = false;
    else
      % no switches change, directly to checking stepper
      checkingStepper = true;
    endif
  endif

  % checking for CHANGE_PROPAGATION_DELAY
  if ~isempty(lastCheckTime)
    if lastCheckTime + CHANGE_PROPAGATION_DELAY < time()
      % waiting has expired
      checkingStepper = true;
      % resetting lastCheckTime
      lastCheckTime = [];
    else
      % not yet
      checkingStepper = false;
      writeLog('TRACE', 'Waiting for switch change propagation');
    endif
  endif

  if checkingStepper
    if checkStepper(adapterStruct, recInfo, playInfo)
      % stepper finished, task finished
      schedTask.newLabel = nextLabel;
      % resetting flag
      checkingStepper = false;
      writeLog('DEBUG', 'Finished task');
    endif
  endif
endfunction