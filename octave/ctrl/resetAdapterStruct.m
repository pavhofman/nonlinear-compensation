% setting adapter params to default values
function resetAdapterStruct()
  global adapterStruct;
  adapterStruct.in = false; % IN CALIB
  adapterStruct.out = false; % OUT OFF
  adapterStruct.lpf = false; % VD
  % same format as peaksCh, phase column not required
  adapterStruct.reqLevels = [];
  adapterStruct.maxAmplDiff = [];
endfunction