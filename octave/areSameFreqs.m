function result  = areSameFreqs(fundPeaksCh, prevFundPeaksCh)
  % both must exist
  if isempty(fundPeaksCh) || isempty(prevFundPeaksCh)
    result = false;
    return;
  endif
  % same freqs
  if ~isequal(fundPeaksCh(:, 1), prevFundPeaksCh(:, 1))
    % different freqs
    result = false;
  else
    result = true;
  endif
endfunction


%!test
% empty peaks
%! fundPeaksCh = [1000, 0.8, 0; 1500, 0.9, 0];
%! prevFundPeaksCh = [];
%! result = areSameFreqs(fundPeaksCh, prevFundPeaksCh, 0.1);
%! assert(result, false);
%
%!test
% different freqs
%! fundPeaksCh = [1000, 0.8, 0; 1500, 0.9, 0];
%! prevFundPeaksCh = [2000, 0.8, 0; 1500, 0.9, 0];
%! result = areSameFreqs(fundPeaksCh, prevFundPeaksCh, 0.1);
%! assert(result, false);
%
%!test
% same freqs, close ampls - OK
%! fundPeaksCh = [1000, 0.8, 0; 1500, 0.9, 0];
%! prevFundPeaksCh = [1000, 0.8, 0; 1500, 0.89, 0];
%! result = areSameFreqs(fundPeaksCh, prevFundPeaksCh, 0.1);
%! assert(result, true);
