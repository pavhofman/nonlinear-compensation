% both firstFundPeaksCh and secondFundPeaksCh are never empty!!
function timeOffset = determineTimeOffset(firstFundPeaksCh, secondFundPeaksCh)
  if rows(firstFundPeaksCh) == 1  || rows(secondFundPeaksCh) == 1
    % first or second have one single tone
    timeOffset = determineSingleToneTimeOffset(firstFundPeaksCh, secondFundPeaksCh);
  elseif rows(firstFundPeaksCh) > 1  && rows(secondFundPeaksCh) > 1
    % both have at least two tones
    timeOffset = determineDualToneTimeOffset(firstFundPeaksCh(1:2, :), secondFundPeaksCh(1:2, :));
  else
    error('determineTimeOffset called with rows(fundPeaks) != 1 or 2!');
  endif
endfunction

% result = phase 2 - phase 1 within interval <0, 2*pi>
function shift = getPositivePhaseDiff(ph1, ph2)
  shift = ph2 - ph1;
  if (shift < 0)
    shift += 2 * pi;
  endif
endfunction


% single frequency
% one has one freq, the other at least one freq
function timeOffset = determineSingleToneTimeOffset(firstFundPeaksCh, secondFundPeaksCh)
  firstPhase = firstFundPeaksCh(1, 3);
  secondPhase = secondFundPeaksCh(1, 3);
  measFreq = secondFundPeaksCh(1, 1);
  
  phaseShift = getPositivePhaseDiff(firstPhase, secondPhase);
  
  % time offset between current time and calibration time within single period of the signal
  timeOffset = phaseShift/(2 * pi * measFreq);
endfunction

% Two frequencies
% Both peaks have two rows
% Assuming firstFundPeaksCh and secondFundPeaksCh have same frequencies
% Typically first = calibration time, second = measure time
% Time offset can be determined precisely only for this specific case: both frequencies must be integer-divisable by their difference
% E.g. 13k + 14k OK, 10k + 12k OK, 9960 + 9980 OK, but 9k + 11k FAIL
function timeOffset = determineDualToneTimeOffset(firstFundPeaksCh, secondFundPeaksCh)  
  % sorting by frequency desc
  firstFundPeaksCh = sortrows(firstFundPeaksCh, -1);
  secondFundPeaksCh = sortrows(secondFundPeaksCh, -1);
  
  % now f1 > f2 => period2 > period1
  f1 = firstFundPeaksCh(1, 1);
  f2 = firstFundPeaksCh(2, 1);
  % periods at secs
  per1 = 1/f1;
  per2 = 1/f2;
  
  % fractional delay of phase2 behind phase1 at time per1 (phase1 = 0 at per1 time)
  fractDelay2AtPer1 = (per2 - per1)/per2;
  
  % every per1 time the phase difference grows by
  phaseDiffEveryPer1 = fractDelay2AtPer1 * 2 *pi;
  
  
  % phase diff at first time
  ph1 = firstFundPeaksCh(1, 3);
  ph2 = firstFundPeaksCh(2, 3);
  % f1 is ahead of f2 by calPhaseDiff at cal time
  firstPhaseDiff = getPositivePhaseDiff(ph2, ph1);
 

  % phase diff at second time
  mph1 = secondFundPeaksCh(1, 3);
  mph2 = secondFundPeaksCh(2, 3);
  % second f1 is ahead of second f2 by secondPhaseDiff at second time
  secondPhaseDiff = getPositivePhaseDiff(mph2, mph1);
  
  % the difference between them
  firstSecondphaseDiff = getPositivePhaseDiff(firstPhaseDiff, secondPhaseDiff);
  
  % it took this long to accummulate this phase difference:
  timeOffset = (firstSecondphaseDiff/phaseDiffEveryPer1) * per1;
endfunction
