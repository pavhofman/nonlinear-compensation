function result  = areSameExistingPeaks(fundPeaksCh, prevFundPeaksCh, maxAmplDiff)
  % both must exist
  if isempty(fundPeaksCh) || isempty(prevFundPeaksCh)
    result = false;
    return;
  endif
  % same freqs
  if ~isequal(fundPeaksCh(:, 1), prevFundPeaksCh(:, 1))
    % different freqs
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
%! result = areSameExistingPeaks(fundPeaksCh, prevFundPeaksCh, 0.1);
%! assert(result, false);
%
%!test
% different freqs
%! fundPeaksCh = [1000, 0.8, 0; 1500, 0.9, 0];
%! prevFundPeaksCh = [2000, 0.8, 0; 1500, 0.9, 0];
%! result = areSameExistingPeaks(fundPeaksCh, prevFundPeaksCh, 0.1);
%! assert(result, false);
%
%!test
% same freqs, too different ampls
%! fundPeaksCh = [1000, 0.8, 0; 1500, 0.9, 0];
%! prevFundPeaksCh = [1000, 0.8, 0; 1500, 0.79, 0];
%! result = areSameExistingPeaks(fundPeaksCh, prevFundPeaksCh, 0.1);
%! assert(result, false);
%
%!test
% same freqs, close ampls - OK
%! fundPeaksCh = [1000, 0.8, 0; 1500, 0.9, 0];
%! prevFundPeaksCh = [1000, 0.8, 0; 1500, 0.89, 0];
%! result = areSameExistingPeaks(fundPeaksCh, prevFundPeaksCh, 0.1);
%! assert(result, true);
