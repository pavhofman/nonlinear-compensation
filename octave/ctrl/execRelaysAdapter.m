function execRelaysAdapter(label)
  % updating adapter panel only, rest is in checkSwitchesAndStepper
  global adapterStruct;
  adapterStruct.label = label;
  adapterStruct.showContinueBtn = true;
  updateAdapterPanel();

  updateRelays();
endfunction