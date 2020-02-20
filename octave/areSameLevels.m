function result  = areSameLevels(peaksCh1, peaksCh2, maxAmplDiff)
  % both must exist and same frequencies
  if isempty(peaksCh1) || isempty(peaksCh2) || ~isequal(peaksCh1(:, 1), peaksCh2(:, 1))
    result = false;
    return;
  endif
  ampls = peaksCh1(:, 2);
  prevAmpls = peaksCh2(:, 2);
  differentAmplIDs = find(abs(1 - ampls ./ prevAmpls) > maxAmplDiff);
  result =  isempty(differentAmplIDs);
endfunction


%!test
% empty peaks
%! fundPeaksCh = [1000, 0.8, 0; 1500, 0.9, 0];
%! prevFundPeaksCh = [];
%! result = areSameLevels(fundPeaksCh, prevFundPeaksCh, 0.1);
%! assert(result, false);
%
%
%!test
% same freqs, too different ampls
%! fundPeaksCh = [1000, 0.8, 0; 1500, 0.9, 0];
%! prevFundPeaksCh = [1000, 0.8, 0; 1500, 0.79, 0];
%! result = areSameLevels(fundPeaksCh, prevFundPeaksCh, 0.1);
%! assert(result, false);
%
%!test
% same freqs, close ampls - OK
%! fundPeaksCh = [1000, 0.8, 0; 1500, 0.9, 0];
%! prevFundPeaksCh = [1000, 0.8, 0; 1500, 0.89, 0];
%! result = areSameLevels(fundPeaksCh, prevFundPeaksCh, 0.1);
%! assert(result, true);
