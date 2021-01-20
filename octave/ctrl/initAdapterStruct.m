function initAdapterStruct()
  global adapterHasArduino;

  global adapterStruct;
  adapterStruct = struct();

  % all fields (defaults)
  adapterStruct.has2VDs = false;
  adapterStruct.has2LPFs = false;

  % LPF1/2 & VD1/2 not modified by resetAdapterStruct, defining init values here
  adapterStruct.lpf = 1; % 1 = LPF1, 2 = LPF2 if has 2 LPFs
  adapterStruct.vd = 1; % 1 = VD1, 2 = VD2 if has2VDs
  adapterStruct.vdForSplitting = 1;
  adapterStruct.vdForInput = 1;
  global chMode;
  global MODE_DUAL_SE;
  adapterStruct.isSE = (chMode == MODE_DUAL_SE);

  adapterStruct.hasRelays = false;
  adapterStruct.hasStepper = false;
  adapterStruct.useContButton = false;
  % all functions
  adapterStruct.execFunc = @(title) emptyFunc();
  adapterStruct.checkFunc = @(recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask) emptyFunc();
  adapterStruct.abortFunc = @() emptyFunc();
  adapterStruct.updateIOFunc = @(recInfo, playInfo) emptyFunc();

  adapterStruct.defaultOut = false;

  resetAdapterStruct();

  global ardStruct;
  ardStruct = struct();
  % all fields
  ardStruct.ard = struct();
  ardStruct.outPin = '';
  ardStruct.vdLpfPin = '';
  ardStruct.inPin = '';
  ardStruct.lpfPin = '';
  ardStruct.balSePin = ''; % OFF = Bal, ON = SE (corresponds to adapterStruct.isSE)
  ardStruct.gndPlusPin = ''; % ON = OUT plus line grounded
  ardStruct.gndMinusPin = ''; % ON = OUT minus line grounded


  if ~adapterHasArduino
    % switches as well as VD are manually operated - displaying only info window
      % mechanical switches, no stepper
    adapterStruct.useContButton = true;

    adapterStruct.execFunc = @(title) updateNoArduinoAdapterPanel(title);
    adapterStruct.checkFunc = @(recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask)...
      checkAdapterPanel(nextLabel, abortLabel, errorLabel, schedTask);
    % empty function
    adapterStruct.abortFunc = @() abortAdapterPanel();
  else
    % all other adapter types with arduino/at least one stepper
    ardStruct.ard = findArduinoOrExit();

    global steppers;
    steppers = cell();

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
      adapterStruct.useContButton = true;
      adapterStruct.execFunc = @(title) execAdapterPanelWithOnlyStepper(title);

    elseif strcmp(firmware, 'CleanSine-1.0')
      % relays + 1 stepper, 2 LPFs
      adapterStruct.hasRelays = true;
      adapterStruct.has2LPFs = true;
      steppers{1} = initStepper(ardStruct.ard, 1, 6, 9, 8, 7);
      % relays pins
      ardStruct.outPin = 'D15';
      ardStruct.vdLpfPin = 'D10';
      ardStruct.inPin = 'D16';
      ardStruct.lpfPin = 'D14'; % LPF 1/2
      adapterStruct.execFunc = @(title) execRelaysAdapter(title);

    elseif strcmp(firmware, 'CleanSine-2.0')
      % relays + 2 steppers VD1/VD2, 2 LPFs
      adapterStruct.hasRelays = true;
      adapterStruct.has2LPFs = true;
      adapterStruct.has2VDs = true;
      % second VD used for calibration at input level
      adapterStruct.vdForSplitting = 1;
      adapterStruct.vdForInput = 2;
      steppers{1} = initStepper(ardStruct.ard, 1, 2, 5, 4, 3);
      steppers{2} = initStepper(ardStruct.ard, 2, 6, 19, 8, 7);

      % relays pins
      ardStruct.outPin = 'D10';
      ardStruct.vdLpfPin = 'D14';
      ardStruct.inPin = 'D15';
      ardStruct.lpfPin = 'D16'; % LPF 1/2
      ardStruct.vdPin = 'D18'; % VD1/2


      % LEDs
      global gpios;
      gpios = struct();
      gpios.out = struct();
      gpios.out.pin = 'D21';
      gpios.out.status = 0;

      gpios.in = struct();
      gpios.in.pin = 'D20';
      gpios.in.status = 0;

      % green
      gpios.ctrl1 = struct();
      gpios.ctrl1.pin = 'D9';
      gpios.ctrl1.status = 1;

      % orange
      gpios.ctrl2 = struct();
      gpios.ctrl2.pin = 'D0';
      gpios.ctrl2.status = 0;

      % switch
      gpios.sw = struct();
      gpios.sw.pin = 'D1';
      gpios.sw.pushedSince = NA;
      ardStruct.ard._configurePin(gpios.sw.pin,'Pullup');

      adapterStruct.execFunc = @(title) execRelaysAdapter(title);
      adapterStruct.updateIOFunc = @(recInfo, playInfo) updateLedsAndSwitch(recInfo, playInfo);
    elseif strcmp(firmware, 'CleanSine-bal')
        % relays, 1 LPF, bal/SE
        adapterStruct.hasRelays = true;
        % 2 steppers VD1/VD2: VD1 for +line in DAC/ADC levels @BAL and DAC level @SE,
        % VD2 for -line in DAC/ADC levels @BAL and ADC level @SE
        adapterStruct.has2VDs = true;
        % no OUT relay, always ON
        adapterStruct.defaultOut = true;

        % second VD used for calibration at input level - for SE mode!
        adapterStruct.vdForSplitting = 1;
        adapterStruct.vdForInput = 2;
        steppers{1} = initStepper(ardStruct.ard, 1, 6, 19, 8, 7);
        steppers{2} = initStepper(ardStruct.ard, 2, 2, 5, 4, 3);

        % relays pins
        ardStruct.vdLpfPin = 'D10';
        ardStruct.inPin = 'D14';
        ardStruct.vdPin = 'A0'; % VD1/2
        ardStruct.balSePin = 'A2'; % OFF = Bal, ON = SE
        ardStruct.gndPlusPin = 'D15'; % ON = OUT +line grounded
        ardStruct.gndMinusPin = 'D16'; % ON = OUT -line grounded

        % LEDs, switches - not supported for now
        adapterStruct.execFunc = @(title) execRelaysAdapter(title);

    end % stepper adapter type
  end % adapter has arduino
  adapterStruct.out = adapterStruct.defaultOut;

  % checked in updateRelays() to call updateAdapterPanel
  adapterStruct.adapterPanelDrawn = false;
  % initial setting relays if needed
  updateRelays();


end

function updateNoArduinoAdapterPanel(title)
  global adapterStruct;
  adapterStruct.label = title;
  updateAdapterPanel();
end

function ard = findArduinoOrExit()
  try
    ard = findArduino('ttyACM');
    % found, returning
  catch
    writeLog('ERROR', 'No arduino adapter found, cannot continue');
    h = errordlg('No arduino adapter found, quitting all CleanSine processes');
    uiwait(h);

    kill(getppid(), 15);
    % exiting
    error("No arduino found");
  end
end

function stepperStruct = initStepper(ard, stepperID, p1, p2, p3, p4)
  ard.initStepperType4(stepperID, p1, p2, p3, p4);
  ard.setSpeed(stepperID, 500);
  % 0 accel = acceleration off
  ard.setAccel(stepperID, 0);
  stepperStruct = initStepperStruct(stepperID);
end


function abortAdapterPanel()
  % empty
end

function abortAdapterPanelWithStepper()
  abortAdapterPanel();
  abortStepper();
end

function emptyFunc()
end