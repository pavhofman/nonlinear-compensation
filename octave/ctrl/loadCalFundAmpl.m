function lpFundAmpl = loadCalFundAmpl(freq, fs, playChID, analysedChID, playCalDevName, recCalDevName, extraCircuit)
  global COMP_TYPE_JOINT;
  global AMPL_IDX;  % = index of fundAmpl1
  global chMode;

  calFile = genCalFilename(freq, fs, COMP_TYPE_JOINT, playChID, analysedChID, playCalDevName, recCalDevName, chMode, extraCircuit);
  [peaksRow, distortFreqs] = loadCalRow(calFile);
  lpFundAmpl = peaksRow(1, AMPL_IDX);
end