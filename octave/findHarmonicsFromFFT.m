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
%   fuzzy - set 1 to allow fuzzy harmonics detection
%           (for frequencies that do not fall exactly into bins)
%   ya - absolute value of yf (optional)
%   fundFreq - frequency of fundamental to search harmonics for
%       (0 for autodetect)
%       (-freq for autodetect of second fundamental around freq)
%
% returns:
%   peaks [ frequency , amplitude_in_absolute_values, angle_in_radians ]
%
function [peaks] = findHarmonicsFromFFT(Fs, nfft, x, yc, fuzzy=0, y=abs(yc), fundFreq=0)
  peaks = zeros(20, 3);

  binwidth = Fs / nfft;
  % skip frequencies under 10Hz
  skip_bins = ceil(10 / binwidth);

  if fundFreq == 0
      [ymax, iymax] = max(y(skip_bins:end));
      if isempty(iymax)
          return
      end
      fundFreq = (skip_bins + iymax - 2) * binwidth;
  elseif fundFreq > 0
      iymax = round((fundFreq / binwidth) + 2 - skip_bins);
  else
      % try to find another fundamental around negated fundFreq
      iymax = round((-fundFreq / binwidth) + 2 - skip_bins);
      ymax = y(skip_bins + iymax);
      % at least 49Hz between two fundamentals
      skipf = ceil(49 / binwidth);
      % search before the first fundamental
      skip2a_bins = skip_bins + iymax - skipf;
      [ymax2a, iymax2a] = max(y(skip_bins:skip2a_bins));
      % search after the first fundamental
      skip2b_bins = skip_bins + iymax + skipf;
      [ymax2b, iymax2b] = max(y(skip2b_bins:end));
      % choose a side with a higher amplitude
      if isempty(iymax2a) || (!isempty(iymax2b) && (ymax2a < ymax2b))
          iymax2 = iymax2b + skip2b_bins - skip_bins;
          ymax2 = ymax2b;
      else
          iymax2 = iymax2a + skip2a_bins - skip_bins;
          ymax2 = ymax2a;
      end
      % second fundamental must not be more than 10x weaker than the first one
      if ymax2 < ymax / 10
          return
      end
      % continue as if the second fundamental was the first
      iymax = iymax2;
      fundFreq = (skip_bins + iymax - 2) * binwidth;
  end

  % find at most 20 harmonics
  lasth = min(20, floor(Fs / 2 / fundFreq));
  fundFreqBin = skip_bins + iymax - 1;
  nffto2 = length(y);
  for nh = 1:lasth
      i = (nh * (fundFreqBin - 1)) + 1;
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
