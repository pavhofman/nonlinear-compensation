% remembering current values of in/out switches
function keepInOutSwitches()
  global adapterStruct;
  adapterStruct.prevOut = adapterStruct.out;
  adapterStruct.prevIn = adapterStruct.in;
endfunction