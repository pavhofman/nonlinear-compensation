function result = isStepperRunning(stepperID)
  global ardStruct;
  global steppers;

  if steppers{stepperID}.running
    [position, reportedStepperID] = ardStruct.ard.checkMoveComplete();
    finished = ~isempty(position) && reportedStepperID == stepperID;
    if finished
      ardStruct.ard.disableStepper(stepperID);
      writeLog('DEBUG', "Stepper [%d] finished at internal position %d", stepperID, position);
      % resetting flag
      steppers{stepperID}.running = false;
    endif
    result = ~finished;
  else
    % not even started
    result = false;
  endif
endfunction