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
function [fundPeaks, distortPeaks, errorMsg] = findHarmonicsFromFFT(Fs, nfft, x, yc, fuzzy=0, y=abs(yc), fundFreq=0)
  fundPeaks = zeros(0, 3);
  distortPeaks = zeros(0, 3);
  errorMsg = '';

  nffto2 = length(y);
  binwidth = Fs / nfft;

  % skip frequencies under 10Hz
  skip_bins = ceil(10 / binwidth);

  [ymax, iymax] = max(y(skip_bins:end));
  if isempty(iymax) || (ymax < 1e-5)
      errorMsg = 'no peaks stronger than -100dBFS';
      return
  end

  fundPeakBins = [];
  for b = find(y(skip_bins:end) >= ymax/10)'
      bb = skip_bins + b - 1;
      if ((bb < nffto2) && (y(bb) < y(bb+1))) || (y(bb-1) > y(bb))
          continue
      end
      if rows(fundPeaks) > 2
          errorMsg = 'too many fundamental peaks';
          break
      end
      fundPeakBins = [fundPeakBins; bb];
      fundPeaks = [fundPeaks; x(bb), y(bb), arg(yc(bb))];
      lasth = min(20, floor(Fs / 2 / x(bb)));
      for nh = 1:lasth
          i = (nh * (bb - 1)) + 1;
          if y(i) >= (ymax / 10)
              continue
          end
          distortPeaks = [distortPeaks; x(i), y(i), arg(yc(i))];
      end
  end

  if rows(fundPeaks) == 2
      % compute intermodulations between two strongest frequencies (5th order max)
      for imd_order = 2:5
          for o1 = 1 : (imd_order-1)
              o2 = imd_order - o1;
              i1 = o1 * (fundPeakBins(1) - 1);
              i2 = o2 * (fundPeakBins(2) - 1);
              for i = [ i1 + i2 + 1, i1 - i2 + 1, i2 - i1 + 1 ];
                  if (i < 1) || (i > nffto2) || (y(i) >= (ymax / 10))
                      % ignore aliased frequencies and stronger than 1/10 of the strongest one
                      continue
                  end
                  distortPeaks = [distortPeaks; x(i), y(i), arg(yc(i))];
              end
          end
      end
  end
endfunction
