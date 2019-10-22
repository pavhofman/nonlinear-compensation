% find fundamental frequencies and their distortion products
%
% params:
%   yc - complex DFT value of (non-negative) frequencies
%   y - absolute value of yf (optional)
%   x - (non-negative) frequencies
%
% returns:
%   fundPeaks [ frequency , amplitude_in_absolute_values, angle_in_radians ]
%
function [fundPeaksCh, errorMsg] = findFundPeaksCh(x, yc, y)
  % ratio of minimum fundamental amplitude picked to the max. fundamental present
  persistent MIN_FUND_RATIO = 1/15;

  % minimum amplitude to consider for fundamental
  persistent MIN_FUND_AMPL = 1e-5;

  fundPeaksCh = [];
  errorMsg = '';

  nffto2 = rows(y);

  [ymax, iymax] = max(y);
  if ymax < MIN_FUND_AMPL
      errorMsg = 'no peaks stronger than -100dBFS';
      return
  end

  for idx = transpose(find(y >= ymax * MIN_FUND_RATIO))
    % local maximum?
      if ...
        % first bin
        (idx < 2) ...
        % or frequencies under 10Hz
        || (x(idx) < 10) ...
        % or next bin larger while not last
        || ((idx + 1 < nffto2) && (y(idx) < y(idx + 1))) ...
        % or previous bin larger
        || (y(idx) < y(idx - 1))
          % not local maximum, skipping
          continue
      end
      fundPeaksCh = [fundPeaksCh; x(idx), y(idx), angle(yc(idx))];
  end
endfunction
