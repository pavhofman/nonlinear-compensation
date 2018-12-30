% Generates compensation reference (distortion peaks with inverted phase). Supports single and dual frequencies
function compenSignal = genCompenReference(fundPeaksCh, distortPeaksCh, measuredPeaksCh, fs, startingT, samplesCnt)
  % first harmonics = zero
  compenSignal = zeros(samplesCnt, 1);
  % for now only single fundamental frequency
  measFreq = measuredPeaksCh(1, 1);
  origFundAmpl = fundPeaksCh(1, 2);
  currFundAmpl = measuredPeaksCh(1, 2);
  
  % time offset between current time and calibration time within single period of the signal
  timeOffset = determineTimeOffset(fundPeaksCh, measuredPeaksCh);
  
  scale = currFundAmpl / origFundAmpl;
  step = 1/fs;
  t = linspace(startingT, startingT + (samplesCnt - 1) * step, samplesCnt)';
  pi2 = 2 * pi;
  for i = (1:rows(distortPeaksCh))
    origDistortGain = distortPeaksCh(i, 2);
    distortFreq = distortPeaksCh(i, 1);
    origDistortPhase = distortPeaksCh(i, 3);
    % current phase distortion = original distortion phase + additional phase accumulated in timeOffset
    currentDistortPhase = origDistortPhase + pi2 * distortFreq * timeOffset;
    % inverted phase
    compenDistortPhase = currentDistortPhase - pi;
    compenDistortGain = origDistortGain * scale;
    % compensation signal for this distortion
    compenSignal += cos(pi2 * distortFreq * t + compenDistortPhase) * compenDistortGain;     
  endfor
endfunction


function timeOffset = determineTimeOffset(fundPeaksCh, measuredPeaksCh)
  if (rows(fundPeaksCh) == 1)
    timeOffset = determineSingleToneTimeOffset(fundPeaksCh, measuredPeaksCh);
  else
    timeOffset = determineDualToneTimeOffset(fundPeaksCh(1:2, :), measuredPeaksCh(1:2, :));
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
function timeOffset = determineSingleToneTimeOffset(fundPeaksCh, measuredPeaksCh)
  origPhase = fundPeaksCh(1, 3);
  currPhase = measuredPeaksCh(1, 3);
  measFreq = measuredPeaksCh(1, 1);
  
  currPhaseShift = getPositivePhaseDiff(origPhase, currPhase);
  
  % time offset between current time and calibration time within single period of the signal
  timeOffset = currPhaseShift/(2 * pi * measFreq);
endfunction

% Two frequencies
% Both peaks have two rows
% Assuming fundPeaksCh and measuredPeaksCh have same frequencies
% Time offset can be determined precisely only for this specific case: both frequencies must be integer-divisable by their difference
% E.g. 13k + 14k OK, 10k + 12k OK, 9960 + 9980 OK, but 9k + 11k FAIL
function timeOffset = determineDualToneTimeOffset(fundPeaksCh, measuredPeaksCh)
  % sorting by frequency desc
  fundPeaksCh = sortrows(fundPeaksCh, -1);
  measuredPeaksCh = sortrows(measuredPeaksCh, -1);
  
  % now f1 > f2 => period2 > period1
  f1 = fundPeaksCh(1, 1);
  f2 = fundPeaksCh(2, 1);
  % periods at secs
  per1 = 1/f1;
  per2 = 1/f2;
  
  % fractional delay of phase2 behind phase1 at time per1 (phase1 = 0 at per1 time)
  fractDelay2AtPer1 = (per2 - per1)/per2;
  
  % every per1 time the phase difference grows by
  phaseDiffEveryPer1 = fractDelay2AtPer1 * 2 *pi;
  
  
  % phase diff at calibration time
  ph1 = fundPeaksCh(1, 3);
  ph2 = fundPeaksCh(2, 3);
  % f1 is ahead of f2 by calPhaseDiff at cal time
  calPhaseDiff = getPositivePhaseDiff(ph2, ph1);
 

  % phase diff at measurement time
  mph1 = measuredPeaksCh(1, 3);
  mph2 = measuredPeaksCh(2, 3);
  % measured f1 is ahead of measured f2 by measuredPhaseDiff at measure time
  measuredPhaseDiff = getPositivePhaseDiff(mph2, mph1);
  
  % the difference between them
  measCalPhaseDiff = getPositivePhaseDiff(calPhaseDiff, measuredPhaseDiff);
  
  % it took this long to accummulate this phase difference:
  timeOffset = (measCalPhaseDiff/phaseDiffEveryPer1) * per1;
endfunction
