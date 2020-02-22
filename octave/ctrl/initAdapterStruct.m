function adapterStruct = initAdapterStruct()
  global PLAY_CH_ID;
  global ANALYSED_CH_ID;
  global adapterType;
  global ADAPTER_TYPE_SWITCHWIN;

  adapterStruct = struct();
  
  adapterStruct.calibrate = false;
  adapterStruct.vd = true;
  adapterStruct.analysedR = (ANALYSED_CH_ID == 2);

  if adapterType == ADAPTER_TYPE_SWITCHWIN
    % simple info window with switch positions
    adapterStruct.execFunc = @(title, thisStruct) showSwitchWindow(title, thisStruct);
    adapterStruct.checkFunc = @(thisStruct, nextLabel, abortLabel, errorLabel, schedItem) checkSwitchWindow(thisStruct, nextLabel, abortLabel, errorLabel, schedItem);
  endif
endfunction