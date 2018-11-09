% find harmonics of the strongest signal up to Fs
%
% frequency in peaks is non-zero only if the harmonics is a peak
% if there is no peak peaks.amplitude is maximum of 3 bins which are
% the most close to the expected frequency of the harmonics
%
% params:
%   Fs - sampling rate of signal
%   nfft - point used for computing x and y
%   x - (non-negative) frequencies
%   yc - complex DFT value of (non-negative) frequencies
%   ya - absolute value of yf (optional)
%
% returns:
%   peaks [ frequency , amplitude_in_absolute_values, angle_in_radians ]
%
function [peaks] = findHarmonicsFromFFT(Fs, nfft, x, yc, fuzzy=0, y=abs(yc))
  binwidth = Fs / nfft;
  nffto2 = length(y);
  % skip frequencies under 10Hz
  skip_bins = ceil(10 / binwidth);
  [ymax, iymax] = max(y(skip_bins:end));
  peaks = [0, 0, 0];
  if iymax < 1
      return
  end
  fundfreq = (skip_bins + iymax - 2) * binwidth;
  % find at most 20 harmonics
  lasth = min(20, floor(Fs/2/fundfreq));
  for nh = 1:lasth
      i = (nh * (skip_bins + iymax - 2)) + 1;
      hp = arg(yc(i));
      if fuzzy == 0
          peaks(nh, :) = [x(i), y(i), hp];
      elseif (i + 1 < nffto2) && y(i) > -130 && (y(i - 1) < (y(i))) && ((y(i)) > y(i + 1))
          peaks(nh, :) = [x(i), y(i), hp];
      elseif (i + 2 < nffto2) && y(i + 1) > -130 && (y(i) < (y(i + 1))) && ((y(i + 1)) > y(i + 2))
          peaks(nh, :) = [x(i + 1), y(i + 1), hp];
      elseif y(i - 1) > -130 && (y(i - 2) < (y(i - 1))) && ((y(i - 1)) > y(i))
          peaks(nh, :) = [x(i - 1), y(i - 1), hp];
      else
          % do not report frequency if it is not a peak
          if (i + 2 < nffto2)
              nhy = [y(i-2),y(i-1),y(i),y(i+1),y(i+2)];
          else
              % skip y(nffto2) as it requires special weighting
              nhy = [y(i-2),y(i-1)];
          end
          peaks(nh, :) = [0, max(nhy), hp];
      end
  end
endfunction
