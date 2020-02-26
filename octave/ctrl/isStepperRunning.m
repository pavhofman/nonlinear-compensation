function result = isStepperRunning(stepperID)
  global ardStruct;
  global steppers;

  if steppers{stepperID}.stepperRunning
    [position, reportedStepperID] = ardStruct.ard.checkMoveComplete();
    finished = ~isempty(position) && reportedStepperID == stepperID;
    if finished
      writeLog('DEBUG', "Stepper [%d] finished at internal position %d", stepperID, position);
      % resetting flag
      steppers{stepperID}.stepperRunning = false;
    endif
    result = ~finished;
  else
    % not even started
    result = false;
  endif
endfunction