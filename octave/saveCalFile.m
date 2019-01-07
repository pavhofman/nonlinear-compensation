function [freqs, result] = saveCalFile(fundPeaks, distortPeaks, fs, deviceName, extraCircuit = '')
  % freqs read from first channel only
  freqs = fundPeaks(:, 1, 1);

  calRec.time = time();
  calRec.fundPeaks = fundPeaks;
  calRec.distortPeaks = distortPeaks;

  disp(calRec);
  
  calFile = genCalFilename(freqs, fs, deviceName, extraCircuit);
  save(calFile, 'calRec');
  
  global FINISHED_RESULT;
  result = FINISHED_RESULT;
endfunction