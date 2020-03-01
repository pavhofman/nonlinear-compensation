function execRelaysAdapter(label)
  % updating adapter panel only, rest is in checkSwitchesAndStepper
  updateAdapterPanel(label, true);
  updateRelays();
endfunction