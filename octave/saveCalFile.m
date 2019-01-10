function result = saveCalFile(fundPeaksCh, distortPeaksCh, fs, channelID, deviceName, extraCircuit = '')
      % has fund freqs, storing
      calRec.time = time();
      calRec.fundPeaks = fundPeaksCh;
      calRec.distortPeaks = distortPeaksCh;
      disp(calRec);
      freqs = getFreqs(fundPeaksCh);
      calFile = genCalFilename(freqs, fs, channelID, deviceName, extraCircuit);
      save(calFile, 'calRec');
      printf('Saved calfile %s\n', calFile);
  global FINISHED_RESULT;
  result = FINISHED_RESULT;
endfunction