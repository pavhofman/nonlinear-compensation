function initStepperParams()
  global ardStruct;
  % format: rows [lastSteps, ratio ADC/DAC measured ampl, lastBacklashCoeff (0, 1)]
  ardStruct.moves = [];
  ardStruct.lastSteps = NA;
  ardStruct.lastPos0 = NA;
  ardStruct.backlashCleared = false;
  ardStruct.calibrated = false;
  % flag for isStepperRunning
  ardStruct.stepperStarted = false;
  % flag for areLevelsStable
  ardStruct.stepperMoved = false;
endfunction