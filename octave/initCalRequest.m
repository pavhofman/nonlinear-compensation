function request = initCalRequest(freqs, compType, playChannelID, extraCircuit, contCal)  
  request = initCompRequest(compType, playChannelID, extraCircuit);
  % plus calibration freqs
  request.freqs = freqs;
  request.contCal = contCal;
endfunction