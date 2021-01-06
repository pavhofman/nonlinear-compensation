function result  = areSameFreqs(peaksCh1, peaksCh2)
  global MAX_FREQ_DIFF_DECIMALS;
  persistent MAX_DIFF_MULTIPLIER = 10^MAX_FREQ_DIFF_DECIMALS;

  % both must exist
  if isempty(peaksCh1) || isempty(peaksCh2)
    result = false;
    return;
  end
  % same freqs
  if ~isequal(round(peaksCh1(:, 1) * MAX_DIFF_MULTIPLIER), round(peaksCh2(:, 1) * MAX_DIFF_MULTIPLIER))
    % different freqs
    result = false;
  else
    result = true;
  end
end


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
