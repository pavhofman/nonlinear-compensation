% building one row for calFIle.peaks. dPeaksC can be empty
function complPeak = buildCalPeakRow(timestamp, fundPeaksCh, dPeaksC, playAmplsCh)
  % build new complPeak line
  fundAmpls = fundPeaksCh(:, 2);
  % playAmplsCh - must have always two values
  % fill with NA
  playAmplsCh = [playAmplsCh, repmat(NA, 1, 2 - length(playAmplsCh))];
  
  % fundPhaseDiff is added later on, zeros here
  complPeak = [timestamp, [NA, NA], playAmplsCh, transpose(fundAmpls), dPeaksC];
end

%!test
%! timestamp = 5;
%! fundPeaksCh = [1000, 0.5, 0; 2000, 0.4, 0];
%! dPeaksC = [0.1, 0.2];
%! playAmplsCh = [];
%! complPeak = buildCalPeakRow(timestamp, fundPeaksCh, dPeaksC, playAmplsCh);
%! expected = [5, 0, 0, 0, 0, 0.5, 0.4, dPeaksC];
%! assert(expected, complPeak);