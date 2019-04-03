% building one row for calFIle.peaks. dPeaksC can be empty
function complPeak = buildCalPeakRow(timestamp, fundPeaksCh, dPeaksC)
  % build new complPeak line
  fundAmpls = fundPeaksCh(:, 2);
  % fundPhaseDiff is added later on, zeros here  
  complPeak = [timestamp, [0, 0], transpose(fundAmpls), dPeaksC];
endfunction

%!test
%! timestamp = 5;
%! fundPeaksCh = [1000, 0.5, 0; 2000, 0.4, 0];
%! dPeaksC = [0.1, 0.2];
%! complPeak = buildCalPeakRow(timestamp, fundPeaksCh, dPeaksC);
%! expected = [5, 0, 0, 0.5, 0.4, dPeaksC];
%! assert(expected, complPeak);