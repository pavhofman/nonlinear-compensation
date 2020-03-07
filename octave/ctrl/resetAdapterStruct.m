% setting adapter params to default values
function resetAdapterStruct()
  global adapterStruct;
  adapterStruct.in = false; % IN CALIB
  adapterStruct.out = false; % OUT OFF
  adapterStruct.lpf = false; % VD
  % same format as peaksCh, phase column not required
  adapterStruct.reqLevels = [];
  adapterStruct.maxAmplDiff = [];

  % flag for indicating that phase of setting switches is finished
  adapterStruct.switchesSet = false;
  % flag indicating change in switches
  adapterStruct.switchesChanged = false;
endfunction