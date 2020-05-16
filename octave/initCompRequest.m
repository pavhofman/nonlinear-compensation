function request = initCompRequest(compType, playChannelID, extraCircuit)
  request = struct();
  request.compType = compType;
  request.playChannelID = playChannelID;
  request.extraCircuit = extraCircuit;

  % note - these are NOT global in CTRL
  global playCalDevName;
  global recCalDevName;
  request.playCalDevName = playCalDevName;
  request.recCalDevName = recCalDevName;
endfunction