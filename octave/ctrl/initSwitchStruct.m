function swStruct = initSwitchStruct()
  global PLAY_CH_ID;
  global ANALYSED_CH_ID;

  swStruct = struct();
  
  swStruct.calibrate = false;
  swStruct.inputR = (PLAY_CH_ID == 2);
  swStruct.vd = true;
  swStruct.directL = true;
  swStruct.analysedR = (ANALYSED_CH_ID == 2);
endfunction