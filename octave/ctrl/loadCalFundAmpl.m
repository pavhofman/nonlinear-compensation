function lpFundAmpl = loadCalFundAmpl(freq, fs, playChID, analysedChID, extraCircuit, extraDir = '')
  global COMP_TYPE_JOINT;
  global AMPL_IDX;  % = index of fundAmpl1
  global MODE_DUAL;
  
  [peaksRow, distortFreqs] = loadCalRow(freq, fs, COMP_TYPE_JOINT, playChID, analysedChID, MODE_DUAL, extraCircuit, extraDir);
  lpFundAmpl = peaksRow(1, AMPL_IDX);
endfunction