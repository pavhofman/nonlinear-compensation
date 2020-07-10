function execAdapterPanelWithOnlyStepper(label)
  % updating adapter panel only, rest is in checkSwitchesAndStepper
  global adapterStruct;
  adapterStruct.label = label;
  updateAdapterPanel();
endfunction