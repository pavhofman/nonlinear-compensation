% returns array of freqs for which no transfer file is found (or is too old - see MAX_TRANSFER_AGE)
function freqs = getMissingTransferFreqs(fundFreqs, fs, extCircuit)
  global MAX_TRANSFER_AGE;
  minTime = time() - MAX_TRANSFER_AGE;
  allFreqs = getTransferFreqs(fundFreqs, fs);
  freqs = [];
  for freq = allFreqs
    transferFile = getTransferFilename(freq, extCircuit);
    if exist(transferFile, 'file')
      % loading transfRec variable
      load(transferFile);
      % checking if the file is recent enough
      if transfRec.timestamp > minTime
        % ok
        continue;
      else
        writeLog('DEBUG', 'Transfer file %s too old, ignored', transferFile);
      endif
    else
      writeLog('DEBUG', 'Transfer file %s not found', transferFile);
    endif
    % missing or too old, missing freq
    freqs = [freqs, freq];    
  endfor
endfunction