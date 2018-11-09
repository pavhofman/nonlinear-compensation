function peaks = showFFT(series, label, plotID, fs, plotsCnt)
  [ peaks, x, y ] = getHarmonics(series, fs);
  drawHarmonics(x, y, label, plotID, plotsCnt);
  format short;
  fprintf([label ':\n']);
  fprintf('%8.2f Hz, %7.2f dB, %7.2f dg\n', convertPeaksToPrintable(peaks)');
endfunction
