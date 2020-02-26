function initArdStruct()
  global ardStruct;

  ardStruct = struct();
  ardStruct.ard = findArduino('ttyACM');
  stepperID = 1;
  initStepper(ardStruct.ard, stepperID, 5, 4, 6, 7);

  global steppers;
  steppers = cell();
  steppers{stepperID} = initStepperStruct(stepperID);
endfunction


function initStepper(ard, stepperID, p1, p2, p3, p4)
  ard.initStepperType4(stepperID, p1, p2, p3, p4);
  ard.setSpeed(stepperID, 300);
  % 0 accel = acceleration off
  ard.setAccel(stepperID, 0);
endfunction