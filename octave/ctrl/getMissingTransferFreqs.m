% returns freqs for which no transfer file is found (or is too old - global variable maxTransferAge)
% since playFundFreq and recFundFreq can slightly differ (nonInteger mode), missing transfer freqs are returned for both
function [playFreqs, recFreqs] = getMissingTransferFreqs(playFundFreq, recFundFreq, fs, extCircuit, nonInteger)
  % external variable, ugly hack but the easiest way to control without passing
  global maxTransferAge;

  minTime = time() - maxTransferAge;
  allPlayFreqs = getTransferFreqs(playFundFreq, fs, nonInteger);
  allRecFreqs = getTransferFreqs(recFundFreq, fs, nonInteger);
  idsToKeep = [];

  for freqID = 1:min(length(allPlayFreqs), length(allRecFreqs))
    transferFile = getTransferFilename(allRecFreqs(freqID), extCircuit);
    if exist(transferFile, 'file')
      % loading transfRec variable
      load(transferFile);
      % checking if the file is recent enough
      if transfRec.timestamp > minTime
        % ok
        continue;
      else
        writeLog('DEBUG', 'Transfer file %s too old, deleting', transferFile);
        deleteFile(transferFile);
      end
    else
      writeLog('DEBUG', 'Transfer file %s not found', transferFile);
    end
    % missing or too old, missing freq
    idsToKeep = [idsToKeep, freqID];
  end

  playFreqs = allPlayFreqs(idsToKeep);
  recFreqs = allRecFreqs(idsToKeep);
end