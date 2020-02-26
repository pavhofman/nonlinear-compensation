function abortStepper()
  global steppers;

  stepperID = findRunningStepperID();
  if ~isempty(stepperID)
    writeLog('DEBUG', 'Aborting stepper [%d] move', stepperID);
    printStr('Aborting stepper [%d] move', stepperID);
    global ardStruct;
  % just sending 0 relative steps
  % TODO - implement support for firmata cmd stepper.stop
    ardStruct.ard.relMoveTo(stepperID, 0);
    % stepper params are not valid now, resetting
    steppers{stepperID} = initStepperStruct(stepperID);
  endif

  % resetting all non-initialized steppers to clear possible abort of non-running stepper but before initialization finished
  for stepperID = 1:length(steppers)
    if ~steppers{stepperID}.initialized
      steppers{stepperID} = initStepperStruct(stepperID);
    endif
  endfor
endfunction