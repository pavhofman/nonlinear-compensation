function result = saveCalFile(fundPeaksCh, distortPeaksCh, fs, channelID, timestamp, deviceName, extraCircuit = '')
      % shift all peaks to zero time
      distortPeaksCh = phasesAtZeroTimeCh(fundPeaksCh, distortPeaksCh);
      fundPeaksCh(:, 3) = 0;
      % has fund freqs, storing
      calRec.timestamp = timestamp;
      calRec.fundPeaks = fundPeaksCh;
      calRec.distortPeaks = distortPeaksCh;
      disp(calRec);
      freqs =  getFreqs(fundPeaksCh);
      
      calFile = genCalFilename(freqs, fs, channelID, deviceName, extraCircuit);
      save(calFile, 'calRec');
      printf('Saved calfile %s\n', calFile);
  global FINISHED_RESULT;
  result = FINISHED_RESULT;
endfunction