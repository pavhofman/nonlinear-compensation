function request = initCalRequest(calFreqReq, compType, playChannelID, playAmpls, extraCircuit, contCal, calRuns, chMode)  
  request = initCompRequest(compType, playChannelID, extraCircuit);
  % plus calibration-specific data
  request.calFreqReq = calFreqReq;
  request.contCal = contCal;
  % number of consequent calibration runs which contribute to final averaged value
  request.calRuns = calRuns;
  % chMode is part of created calfile name.
  request.chMode = chMode;
  % current playback ampls generating the calibrated signal on rec side. Real values passed only in compType COMP_TYPE_JOINT!
  request.playAmpls = playAmpls;
endfunction