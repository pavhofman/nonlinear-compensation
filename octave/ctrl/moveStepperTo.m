function moveStepperTo(stepperID, steps)
  global ardStruct;
  
  writeLog('DEBUG', 'Moving stepper [%d] steps: %d', stepperID, steps);
  printStr("Moving stepper [%d] steps: %d", stepperID, steps);
  ardStruct.ard.relMoveTo(stepperID, steps);
  % remembering
  global steppers;
  steppers{stepperID}.lastSteps = steps;
  steppers{stepperID}.stepperRunning = true;
  steppers{stepperID}.stepperMoved = true;
endfunction