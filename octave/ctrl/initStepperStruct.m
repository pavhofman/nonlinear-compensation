function stepper = initStepperStruct(stepperID)
  stepper = struct();
  stepper.ID = stepperID;

  % format: rows [lastSteps, ratio ADC/DAC measured ampl, lastBacklashCoeff (0, 1)]
  stepper.moves = [];
  stepper.lastSteps = NA;
  stepper.lastPos0 = NA;
  stepper.backlashCleared = false;
  stepper.calibrated = false;
  % backlash clearing and calibration really finished
  stepper.initialized = false;
  % flag for isStepperRunning
  stepper.stepperRunning = false;
  % flag for areLevelsStable
  stepper.stepperMoved = false;
endfunction