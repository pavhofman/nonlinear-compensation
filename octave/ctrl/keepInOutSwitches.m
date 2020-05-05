% remembering current values of in/out switches
function keepInOutSwitches()
  global adapterStruct;
  % stacking the values
  adapterStruct.prevOut{end + 1} = adapterStruct.out;
  adapterStruct.prevIn{end + 1} = adapterStruct.in;
endfunction