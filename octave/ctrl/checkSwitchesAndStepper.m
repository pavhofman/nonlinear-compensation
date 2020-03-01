% checkFunc for tasks
function schedTask = checkSwitchesAndStepper(adapterStruct, recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask)
  global switchesSet;
  persistent checkingStepper = false;

  % first checking continue status
  if switchesSet
    % CONTINUE button pressed, can continue with checking stepper
    checkingStepper = true;
    % resetting flag
    switchesSet = false;
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