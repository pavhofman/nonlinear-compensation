function ardStruct = initArdStruct()
  ardStruct = struct();
  ardStruct.stepperID = 1;
  ardStruct.ard = initArduino(ardStruct.stepperID);

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


function ard = initArduino(stepperID)
  ard = findArduino('ttyACM');
  % stepper 0 init
  ard.initStepperType4(stepperID, 5, 4, 6, 7);
  ard.setSpeed(stepperID, 300);
  % 0 accel = acceleration off
  ard.setAccel(stepperID, 0);
endfunction