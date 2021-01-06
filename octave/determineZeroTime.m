% Determines time it took from all fundamentals at zero phase (zero time) to reach current phases at peaksCh.
% Supports any number of fundamentals, any freqs
% peaksCh - at least one fundamental required!
% zeroT - single zero time, or empty if none determined (i.e. error)
function zeroT = determineZeroTime(peaksCh)
  % function works only for integer values. Rounding frequencies to integers.
  % Determined zero time will be scaled at the end to original frequency
  origPeaksCh = peaksCh;
  peaksCh(:, 1) = round(peaksCh(:, 1));
  % details - row freq, period, phaseTime. Row per freq
  details = getDetails(peaksCh);
  % sorting by phaseTime DESC
  details = sortrows(details, -3);

  freq1 = details(1, 1);
  period1 = details(1, 2);
  phaseTime1 = details(1, 3);

  if (rows(details) == 1)
    % one-tone, nothing to compute, zeroTime was before starting the last incomplete period
    zeroT = phaseTime1;
    return;
  end

  % generating vector of times when freq1 has zero phase. In reality this was in past, but we can turn time around and generate positive time
  % the first zero phase is at phaseTime1, and then every period1
  % Since we support only integer-Hz frequencies, the maximum least common multiple of all freqs is 1 second. We need to generate only 1 second (+ a few extra periods for safe margin (e.g. 10))
  zeroTimes = phaseTime1:period1:phaseTime1 + (period1 * (freq1 + 10));
  % we need zeroTimes for every other fundamental we have
  cntToAlign = rows(details) - 1;
  zeroTimes = repmat(zeroTimes, cntToAlign, 1);
  
  periods = details(2:end, 2);
  phaseTimes = details(2:end, 3);

  % time-aligning the zeroTimes for phaseTime and finding what fraction of period (mod(time/period)) corresponds to times of the previous freqs
  % all fundamentals calculated at once
  alignedTimes = zeroTimes - phaseTimes;
  phaseTimesAtZeros = mod(alignedTimes, periods);

  % distance from <zero, period> boundaries
  phaseTimesResidua = periods/2 - abs(phaseTimesAtZeros - periods/2);
  % summing all residua along rows
  summedResidua = sum(phaseTimesResidua, 1);
  % the lowest residua corresponds to time at which all fundamentals were closest to full period
  minIDs = find(summedResidua == min(summedResidua));
  % all zeroTimes rows are identical, using only times from the first row
  finalZeroTimes = zeroTimes(1, minIDs);

  if ~isempty(finalZeroTimes)
    zeroT = finalZeroTimes(1);
    % scaling time to correspond to floating-point frequencies
    % using first freq - if orig freq was above its rounded value, the resultant time is smaller
    zeroT *=  peaksCh(1, 1) / origPeaksCh(1, 1);
  else
    zeroT = [];
  end
end


% details from peaksCh
function details = getDetails(peaksCh)
  % const
  persistent PI2 = 2 * pi;

  freqs = peaksCh(:, 1);
  periods = 1./freqs;
  phases = peaksCh(:, 3);
  % phases (i.e. time) must be positive
  for freqID = 1:rows(phases)
    if phases(freqID) < 0
      phases(freqID) += PI2;
    end
  end
  phaseTimes = periods .* phases ./ PI2;
  details = [freqs, periods, phaseTimes];
end


%!function peaksCh = genPeaksCh(freqs, T)
%! periods = 1 ./ freqs;
%! 
%! timesToZero = mod(T, periods);
%! phases = 2 * pi * timesToZero ./ periods;
%! ampls = repmat(0.9, rows(freqs), 1);
%! peaksCh = [freqs, ampls, phases];
%!end
%! 
%!function [periodsToZeroT, periodsInT] = checkZeroT(zeroT, T, peaksCh)
%!  periods = 1./peaksCh(:, 1);
%!  phaseTimes = mod(T, periods);
%!  % periods within zeroT - must be integer!
%!  periodsToZeroT = (zeroT - phaseTimes)./periods;
%!  % periods from the beginning to point zeroT (T - zeroT) - must be int!
%!  periodsInT = (T - zeroT)./periods;
%!end
%! 
%! Checking integer value with tolerance tol
%!function result = checkInt(val, tol)
%!   results = abs(round(val) - val) < tol;
%!   result = all(results);
%!end
%!
%!test
%! T = 15.48415358045152; 
%! intTolerance = 1e-6;
%! peaksCh = genPeaksCh([5; 6; 7], T);
%! zeroT = determineZeroTime(peaksCh);
%! [periods1, periods2] = checkZeroT(zeroT, T, peaksCh)
%! assert(checkInt(periods1, intTolerance)); 
%! assert(checkInt(periods2, intTolerance)); 
%! 
%! peaksCh = genPeaksCh([1000; 1100; 1200], T);
%! [periods1, periods2] = checkZeroT(zeroT, T, peaksCh)
%! assert(checkInt(periods1, intTolerance)); 
%! assert(checkInt(periods2, intTolerance)); 
%! 
%! peaksCh = genPeaksCh([9; 101; 11], T);
%! [periods1, periods2] = checkZeroT(zeroT, T, peaksCh)
%! assert(checkInt(periods1, intTolerance)); 
%! assert(checkInt(periods2, intTolerance)); 
%! 
%! peaksCh = genPeaksCh([20001; 10070], T);
%! [periods1, periods2] = checkZeroT(zeroT, T, peaksCh)
%! assert(checkInt(periods1, intTolerance)); 
%! assert(checkInt(periods2, intTolerance)); 
%! 