function adapterStruct = initAdapterStruct()
  global adapterType;
  global ADAPTER_TYPE_SWITCHWIN;
  global ADAPTER_TYPE_SWITCHWIN_VD_STEPPER;

  adapterStruct = struct();

  adapterStruct.calibrate = false; % that means cal/in switch is switched to IN
  adapterStruct.out = true; % OUT switch
  adapterStruct.vd = false;
  % same format as peaksCh, phase column not required
  adapterStruct.reqLevels = [];
  adapterStruct.maxAmplDiff = [];

  if adapterType == ADAPTER_TYPE_SWITCHWIN
    % mechanical switches, no stepper
    adapterStruct.hasRelays = false;
    adapterStruct.hasStepper = false;

    adapterStruct.execFunc = @(title, thisStruct) updateAdapterPanel(title, true);
    adapterStruct.checkFunc = @(thisStruct, recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask)...
      checkAdapterPanel(thisStruct, nextLabel, abortLabel, errorLabel, schedTask);

  elseif adapterType == ADAPTER_TYPE_SWITCHWIN_VD_STEPPER
    % simple info window with switch positions
    adapterStruct.hasRelays = false;
    adapterStruct.hasStepper = true;

    adapterStruct.execFunc = @(title, thisStruct) execAdapterPanelWithStepper(title, thisStruct);
    adapterStruct.checkFunc = @(thisStruct, recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask)...
      checkAdapterPanelWithStepper(thisStruct, recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask);
  endif
endfunction