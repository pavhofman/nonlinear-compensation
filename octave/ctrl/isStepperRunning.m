function result = isStepperRunning()
  global ardStruct;

  if ardStruct.stepperRunning
    [position, reportedStepperID] = ardStruct.ard.checkMoveComplete();
    finished = ~isempty(position) && reportedStepperID == ardStruct.stepperID;
    if finished
      writeLog('DEBUG', "Stepper position: %d", position);
      % resetting flag
      ardStruct.stepperRunning = false;
    endif
    result = ~finished;
  else
    % not even started
    result = false;
  endif
endfunction