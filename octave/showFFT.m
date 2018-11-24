function peaks = showFFT(series, label, plotID, fs, plotsCnt, fundFreq=0)
  [fundPeaks, distortPeaks, errorMsg, x, y] = getHarmonics(series, fs, 'hanning', 0, fundFreq);
  peaks = [fundPeaks; distortPeaks];
  drawHarmonics(x, y, label, plotID, plotsCnt);
  format short;
  fprintf([label ':\n']);
  fprintf('%8.2f Hz, %7.2f dB, %7.2f dg\n', convertPeaksToPrintable(peaks)');
endfunction
