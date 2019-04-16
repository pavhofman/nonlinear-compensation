function result  = areSameLevels(fundPeaksCh, prevFundPeaksCh, maxAmplDiff)
  % both must exist
  if isempty(fundPeaksCh) || isempty(prevFundPeaksCh)
    result = false;
    return;
  endif
  ampls = fundPeaksCh(:, 2);
  prevAmpls = prevFundPeaksCh(:, 2);
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
