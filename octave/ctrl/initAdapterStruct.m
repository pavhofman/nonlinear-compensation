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

    adapterStruct.execFunc = @(title, thisStruct) execAdapterPanelWithStepper(title, thisStruct);
    adapterStruct.checkFunc = @(thisStruct, recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask)...
      checkAdapterPanelWithStepper(thisStruct, recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask);
    adapterStruct.abortFunc = @() abortAdapterPanelWithStepper();
  endif
endfunction

function abortAdapterPanel()
  global adapterContinue;
  % resetting flag
  adapterContinue = false;
endfunction

function abortAdapterPanelWithStepper()
  abortAdapterPanel();
  abortStepper();
endfunction