function moveStepperTo(stepperID, steps)
  global ardStruct;
  
  writeLog('DEBUG', 'Moving stepper [%d] steps: %d', stepperID, steps);
  printStr("Moving stepper [%d] steps: %d", stepperID, steps);
  ardStruct.ard.enableStepper(stepperID);
  % just in case
  pause(0.01);
  ardStruct.ard.relMoveTo(stepperID, steps);
  % remembering
  global steppers;
  steppers{stepperID}.lastSteps = steps;
  steppers{stepperID}.running = true;
  steppers{stepperID}.hasMoved = true;
endfunction