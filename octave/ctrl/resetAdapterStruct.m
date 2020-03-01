% setting adapter params to default values
function resetAdapterStruct()
  global adapterStruct;
  adapterStruct.in = true; % DUT IN
  adapterStruct.out = true; % OUT ON
  adapterStruct.lpf = false; % VD
  % same format as peaksCh, phase column not required
  adapterStruct.reqLevels = [];
  adapterStruct.maxAmplDiff = [];
endfunction