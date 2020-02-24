function adapterStruct = initAdapterStruct()
  global adapterType;
  global ADAPTER_TYPE_SWITCHWIN;

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

    adapterStruct.execFunc = @(title, thisStruct) updateAdapterPanel(title, thisStruct, true);
    adapterStruct.checkFunc = @(thisStruct, recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedItem)...
      checkAdapterPanel(thisStruct, nextLabel, abortLabel, errorLabel, schedItem);
  endif
endfunction