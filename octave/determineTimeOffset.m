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
function timeOffset = determineDualToneTimeOffset(firstFundPeaksCh, secondFundPeaksCh)
  zeroT1 = determineZeroTime(firstFundPeaksCh);
  zeroT2 = determineZeroTime(secondFundPeaksCh);
  timeOffset = zeroT2 - zeroT1;
endfunction
