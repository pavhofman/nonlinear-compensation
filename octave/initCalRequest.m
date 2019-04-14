function request = initCalRequest(calFreqReq, compType, playChannelID, extraCircuit, contCal)  
  request = initCompRequest(compType, playChannelID, extraCircuit);
  % plus calibration-specific data
  request.calFreqReq = calFreqReq;
  request.contCal = contCal;
endfunction