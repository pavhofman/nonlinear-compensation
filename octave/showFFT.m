function showFFT(series, label, plotID, fs, plotsCnt, fundFreq=0)
  [fundPeaks, distortPeaks, errorMsg, x, y] = getHarmonics(fs, series, fs, true);
  drawHarmonics(x, y, label, plotID, plotsCnt);
  format short;
  fprintf([label ':\n']);
  for channelID = 1:rows(fundPeaks)
    fprintf('Channel %d:\n', channelID);
    fprintf('Fund Peaks:\n');
    fprintf('%8.2f Hz, %7.2f dB, %7.2f dg\n', transpose(convertPeaksToPrintable(fundPeaks{channelID})));
    if ~isempty(distortPeaks{channelID})
      fprintf('Distort Peaks:\n');
      fprintf('%8.2f Hz, %7.2f dB, %7.2f dg\n', transpose(convertPeaksToPrintable(distortPeaks{channelID})));
    end
  end
end
