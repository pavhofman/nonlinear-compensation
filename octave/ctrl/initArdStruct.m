function initArdStruct()
  global ardStruct;
  ardStruct = struct();
  ardStruct.stepperID = 1;
  ardStruct.ard = initArduino(ardStruct.stepperID);

  initStepperParams();
endfunction


function ard = initArduino(stepperID)
  ard = findArduino('ttyACM');
  % stepper 0 init
  ard.initStepperType4(stepperID, 5, 4, 6, 7);
  ard.setSpeed(stepperID, 300);
  % 0 accel = acceleration off
  ard.setAccel(stepperID, 0);
endfunction