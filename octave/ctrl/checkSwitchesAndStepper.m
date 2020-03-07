% checkFunc for tasks
function schedTask = checkSwitchesAndStepper(recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask)
  global adapterStruct;
  persistent checkingStepper = false;

  % first checking continue status
  if adapterStruct.switchesSet
    % CONTINUE button pressed, can continue with checking stepper
    checkingStepper = true;
    % setting flags
    adapterStruct.switchesSet = false;
    adapterStruct.resetPrevMeasPeaks = true;
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