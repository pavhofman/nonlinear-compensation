function [peaksRow, distortFreqs] = loadCalRow(freqs, fs, compType, playChID, analysedChID, extraCircuit = '')
  calFile = genCalFilename(freqs, fs, compType, playChID, analysedChID, extraCircuit);
  % loading calRec structure
  load(calFile);
  
  peaks = calRec.peaks;
  if rows(peaks) != 3
    msg = sprintf('Calfile %s does not have 3 peaks rows, unsupported operation, exiting.', calFile);
    writeLog('ERROR', msg);
    error(msg);
  endif
  
  % always second row
  peaksRow = peaks(2, :);
  distortFreqs = calRec.distortFreqs;
endfunction