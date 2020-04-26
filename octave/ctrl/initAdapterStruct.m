function initAdapterStruct()
  global adapterHasArduino;

  global adapterStruct;
  adapterStruct = struct();
  resetAdapterStruct();

  % defaults
  adapterStruct.has2VDs = false;
  adapterStruct.has2LPFs = false;

  % LPF1/2 & VD1/2 not modified by resetAdapterStruct, defining init values here
  adapterStruct.lpf = 1; % 1 = LPF1, 2 = LPF2 if has2LPFs
  adapterStruct.vd = 1; % 1 = VD1, 2 = VD2 if has2VDs
  adapterStruct.vdForSplitting = 1;
  adapterStruct.vdForInput = 1;

  adapterStruct.hasRelays = false;
  adapterStruct.hasStepper = false;

  if ~adapterHasArduino
    % switches as well as VD are manually operated - displaying only info window
      % mechanical switches, no stepper

    adapterStruct.execFunc = @(title) updateSwitchWinPanel(title);
    adapterStruct.checkFunc = @(recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask)...
      checkAdapterPanel(nextLabel, abortLabel, errorLabel, schedTask);
    % empty function
    adapterStruct.abortFunc = @() abortAdapterPanel();
  else
    % all other adapter types with arduino/at least one stepper
    global ardStruct;
    global steppers;
    initArduino();

    % same for all stepper adapters
    adapterStruct.hasStepper = true;
    % flag for checkStepper() - set after every switch change and stepper move
    adapterStruct.resetPrevMeasPeaks = true;


    adapterStruct.checkFunc = @(recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask)...
      checkSwitchesAndStepper(recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask);
    adapterStruct.abortFunc = @() abortAdapterPanelWithStepper();

    firmware = ardStruct.ard.getFirmware();
    if strcmp(firmware, 'CleanSine-0.1')
      % switches are manually operated - displaying only info window. VD operated by a stepper
      steppers{1} = initStepper(ardStruct.ard, 1, 6, 9, 8, 7);
      % simple info window with switch positions
      adapterStruct.hasRelays = false;
      adapterStruct.execFunc = @(title) execAdapterPanelWithStepper(title);

    elseif strcmp(firmware, 'CleanSine-1.0')
      % relays + 1 stepper, 2 LPFs
      adapterStruct.hasRelays = true;
      adapterStruct.has2LPFs = true;
      steppers{1} = initStepper(ardStruct.ard, 1, 6, 9, 8, 7);
      % relays pins
      ardStruct.outPin = 15;
      ardStruct.calibLPFPin = 10;
      ardStruct.inPin = 16;
      ardStruct.lpfPin = 14; % LPF 1/2
      adapterStruct.execFunc = @(title) execRelaysAdapter(title);

    elseif strcmp(firmware, 'CleanSine-2.0')
      % relays + 2 steppers VD1/VD2, 2 LPFs
      adapterStruct.hasRelays = true;
      adapterStruct.has2LPFs = true;
      adapterStruct.has2VDs = true;
      % second VD used for calibration at input level
      adapterStruct.vdForInput = 2;
      steppers{1} = initStepper(ardStruct.ard, 1, 2, 5, 4, 3);
      steppers{2} = initStepper(ardStruct.ard, 2, 6, 19, 8, 7);

      % relays pins
      ardStruct.outPin = 10;
      ardStruct.calibLPFPin = 14;
      ardStruct.inPin = 15;
      ardStruct.lpfPin = 16; % LPF 1/2
      ardStruct.vdPin = 18; % VD1/2
      adapterStruct.execFunc = @(title) execRelaysAdapter(title);

    endif % stepper adapter type
  endif % adapter has arduino
endfunction

function updateSwitchWinPanel(title)
  global adapterStruct;
  adapterStruct.label = title;
  adapterStruct.showContinueBtn = true;
  updateAdapterPanel();
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