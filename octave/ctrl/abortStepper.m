function abortStepper()
  stepperID = findRunningStepperID();
  if ~isempty(stepperID)
    writeLog('DEBUG', 'Aborting stepper [%d] move', stepperID);
    printStr('Aborting stepper [%d] move', stepperID);
    global ardStruct;
  % just sending 0 relative steps
  % TODO - implement support for firmata cmd stepper.stop
    ardStruct.ard.relMoveTo(stepperID, 0);
    % stepper params are not valid now, resetting
    global steppers;
    steppers{stepperID} = initStepperStruct(stepperID);
  endif
endfunction