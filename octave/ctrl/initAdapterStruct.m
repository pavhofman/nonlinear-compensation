function initAdapterStruct()
  global adapterType;
  global ADAPTER_TYPE_SWITCHWIN;
  global ADAPTER_TYPE_SWITCHWIN_VD_STEPPER;
  global ADAPTER_TYPE_RELAYS_1STEPPER;

  global adapterStruct;
  adapterStruct = struct();
  resetAdapterStruct();
  % lpf1/2 is not modified by resetAdapterStruct, defining init value here
  adapterStruct.lpf = 1; % 1 = LPF1, 2 = LPF2

  if adapterType == ADAPTER_TYPE_SWITCHWIN
    % mechanical switches, no stepper
    adapterStruct.hasRelays = false;
    adapterStruct.hasStepper = false;

    adapterStruct.execFunc = @(title) updateAdapterPanel(title, true);
    adapterStruct.checkFunc = @(recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask)...
      checkAdapterPanel(nextLabel, abortLabel, errorLabel, schedTask);
    % empty function
    adapterStruct.abortFunc = @() abortAdapterPanel();
  else
    % all other adapter types have some steppers
    adapterStruct.hasStepper = true;
    % flag for checkStepper() - set after every switch change and stepper move
    adapterStruct.resetPrevMeasPeaks = true;

    initArduino();
    global ardStruct;
    global steppers;
    steppers{1} = initStepper(ardStruct.ard, 1, 6, 9, 8, 7);

    % same for all stepper adapters
    adapterStruct.checkFunc = @(recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask)...
      checkSwitchesAndStepper(recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask);
    adapterStruct.abortFunc = @() abortAdapterPanelWithStepper();

    if adapterType == ADAPTER_TYPE_SWITCHWIN_VD_STEPPER
      % simple info window with switch positions
      adapterStruct.hasRelays = false;
      adapterStruct.execFunc = @(title) execAdapterPanelWithStepper(title);
  
    elseif adapterType == ADAPTER_TYPE_RELAYS_1STEPPER
      adapterStruct.hasRelays = true;
      % relays pins
      ardStruct.outPin = 15;
      ardStruct.calibLPFPin = 10;
      ardStruct.inPin = 16;
      ardStruct.lpfPin = 14; % LPF 1/2
      adapterStruct.execFunc = @(title) execRelaysAdapter(title);
    endif % stepper adapter type
  endif % adapter type
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
  ard.setSpeed(stepperID, 450);
  % 0 accel = acceleration off
  ard.setAccel(stepperID, 0);
  stepperStruct = initStepperStruct(stepperID);
endfunction


function abortAdapterPanel()
  % setting switches to default values + restoring IN/OUT switches
  resetAdapterStruct();
endfunction

function abortAdapterPanelWithStepper()
  abortAdapterPanel();
  abortStepper();
endfunction