% setting adapter params to default values
function resetAdapterStruct()
  global adapterStruct;
  adapterStruct.calibrate = false; % that means cal/in switch is switched to IN
  adapterStruct.out = true; % OUT switch
  adapterStruct.vd = false;
  % same format as peaksCh, phase column not required
  adapterStruct.reqLevels = [];
  adapterStruct.maxAmplDiff = [];
endfunction