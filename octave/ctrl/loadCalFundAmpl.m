function lpFundAmpl = loadCalFundAmpl(freq, fs, playChID, analysedChID, playCalDevName, recCalDevName, extraCircuit)
  global COMP_TYPE_JOINT;
  global AMPL_IDX;  % = index of fundAmpl1
  global MODE_DUAL;

  calFile = genCalFilename(freq, fs, COMP_TYPE_JOINT, playChID, analysedChID, playCalDevName, recCalDevName, MODE_DUAL, extraCircuit);
  [peaksRow, distortFreqs] = loadCalRow(calFile);
  lpFundAmpl = peaksRow(1, AMPL_IDX);
end