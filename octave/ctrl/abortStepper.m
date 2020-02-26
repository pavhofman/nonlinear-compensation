function abortStepper()
  global ardStruct;
  writeLog('DEBUG', 'Aborting stepper move');
  % just sending 0 relative steps
  % TODO - implement support for firmata cmd stepper.stop
  ardStruct.ard.relMoveTo(ardStruct.stepperID, 0);
  % ardStruct.moves is not valid now, resetting the stepper params
  initStepperParams();
endfunction