function request = initCompRequest(compType, playChannelID, extraCircuit)
  request = struct();
  request.compType = compType;
  request.playChannelID = playChannelID;
  request.extraCircuit = extraCircuit;
endfunction