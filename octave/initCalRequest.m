function request = initCalRequest(calFreqReq, compType, playChannelID, extraCircuit, contCal, calRuns)  
  request = initCompRequest(compType, playChannelID, extraCircuit);
  % plus calibration-specific data
  request.calFreqReq = calFreqReq;
  request.contCal = contCal;
  % number of consequent calibration runs which contribute to final averaged value
  request.calRuns = calRuns;  
endfunction