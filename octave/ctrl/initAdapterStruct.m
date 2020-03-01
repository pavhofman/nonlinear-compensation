function initAdapterStruct()
  global adapterType;
  global ADAPTER_TYPE_SWITCHWIN;
  global ADAPTER_TYPE_SWITCHWIN_VD_STEPPER;

  global adapterStruct;
  adapterStruct = struct();
  resetAdapterStruct();

  if adapterType == ADAPTER_TYPE_SWITCHWIN
    % mechanical switches, no stepper
    adapterStruct.hasRelays = false;
    adapterStruct.hasStepper = false;

    adapterStruct.execFunc = @(title, thisStruct) updateAdapterPanel(title, true);
    adapterStruct.checkFunc = @(thisStruct, recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask)...
      checkAdapterPanel(thisStruct, nextLabel, abortLabel, errorLabel, schedTask);
    % empty function
    adapterStruct.abortFunc = @() abortAdapterPanel();

  elseif adapterType == ADAPTER_TYPE_SWITCHWIN_VD_STEPPER
    % simple info window with switch positions
    adapterStruct.hasRelays = false;
    adapterStruct.hasStepper = true;

    initArduino();
    global ardStruct;
    global steppers;
    steppers{1} = initStepper(ardStruct.ard, 1, 6, 7, 8, 9);

    adapterStruct.execFunc = @(title, thisStruct) execAdapterPanelWithStepper(title, thisStruct);
    adapterStruct.checkFunc = @(thisStruct, recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask)...
      checkSwitchesAndStepper(thisStruct, recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask);
    adapterStruct.abortFunc = @() abortAdapterPanelWithStepper();

  elseif adapterType == ADAPTER_TYPE_RELAYS_1STEPPER
    adapterStruct.hasRelays = true;
    adapterStruct.hasStepper = true;

    initArduino();
    global ardStruct;
    global steppers;
    steppers{1} = initStepper(ardStruct.ard, 1, 6, 7, 8, 9);
    % relays pins
    ardStruct.outPin = 1;
    ardStruct.vdPin = 2;
    ardStruct.calibratePin = 3;


    adapterStruct.execFunc = @(title, thisStruct) execRelaysAdapter(title, thisStruct);
    adapterStruct.checkFunc = @(thisStruct, recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask)...
      checkSwitchesAndStepper(thisStruct, recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask);
    adapterStruct.abortFunc = @() abortAdapterPanelWithStepper();
  endif
endfunction


function initArduino()
  global ardStruct;
  ardStruct = initArdStruct();
  global steppers;
  steppers = cell();
endfunction

function ardStruct = initArdStruct()
  ardStruct = struct();
  ardStruct.ard = findArduino('ttyACM');
endfunction

function stepperStruct = initStepper(ard, stepperID, p1, p2, p3, p4)
  ard.initStepperType4(stepperID, p1, p2, p3, p4);
  ard.setSpeed(stepperID, 400);
  % 0 accel = acceleration off
  ard.setAccel(stepperID, 0);
  stepperStruct = initStepperStruct(stepperID);
endfunction


function abortAdapterPanel()
  global switchesSet;
  % resetting flag
  switchesSet = false;
  % setting switches to default values
  resetAdapterStruct();
endfunction

function abortAdapterPanelWithStepper()
  abortAdapterPanel();
  abortStepper();
endfunction