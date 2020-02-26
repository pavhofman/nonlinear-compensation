function result = isStepperRunning()
  global ardStruct;

  if ardStruct.stepperStarted
    [position, reportedStepperID] = ardStruct.ard.checkMoveComplete();
    finished = ~isempty(position) && reportedStepperID == ardStruct.stepperID;
    if finished
      writeLog('DEBUG', "Stepper position: %d", position);
      % resetting flag
      ardStruct.stepperStarted = false;
    endif
    result = ~finished;
  else
    % not even started
    result = false;
  endif
endfunction