function moveStepperTo(steps)
  global ardStruct;
  
  writeLog('DEBUG', 'Moving stepper %d steps', steps);
  ardStruct.ard.relMoveTo(ardStruct.stepperID, steps);
  % remembering
  ardStruct.lastSteps = steps;
  ardStruct.stepperStarted = true;
  ardStruct.stepperMoved = true;
endfunction