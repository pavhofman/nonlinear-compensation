% find fundamental frequencies and their distortion products
%
% params:
%   yc - complex DFT value of (non-negative) frequencies
%   y - absolute value of yf (optional)
%   x - (non-negative) frequencies
%   binwidth - Fs / nfft
%
% returns:
%   fundPeaks [ frequency , amplitude_in_absolute_values, angle_in_radians ]
%   disgtortPeaks [ frequency , amplitude_in_absolute_values, angle_in_radians ]
%
function [fundPeaks, distortPeaks, errorMsg] = findHarmonicsFromFFT(yc, y, x, binwidth=1)
  fundPeaks = zeros(0, 3);
  distortPeaks = zeros(0, 3);
  errorMsg = '';

  nffto2 = rows(y);

  [ymax, iymax] = max(y);
  if isempty(iymax) || (ymax < 1e-5)
      errorMsg = 'no peaks stronger than -100dBFS';
      return
  end

  for b = find(y >= ymax/10)'
      bb = b - 1;
      if (x(bb) < 10) || ((bb < nffto2) && (y(bb) < y(bb+1))) || (y(bb-1) > y(bb))
          % skip frequencies under 10Hz and those which are not a local maximum
          continue
      end
      if rows(fundPeaks) > 2
          errorMsg = 'too many fundamental peaks';
          break
      end
      fundPeaks = [fundPeaks; x(bb), y(bb), arg(yc(bb))];
  end

  fundPeakBins = [];
  for f = fundPeaks(:, 1)'
      bb = round(f / binwidth) + 1;
      fundPeakBins = [fundPeakBins; bb];
      for nh = 1:20
          i = (nh * (bb - 1)) + 1;
          if i > nffto2
              % ignore aliased frequencies
              break
          end
          if (y(i) >= (ymax / 10))
              % ignore frequencies stronger than 1/10 (-20dB) of the strongest one
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
                  if (i < 1) || (i > nffto2) || (y(i) >= (ymax / 10)) || (y(i) < 3.1623e-08)
                      % ignore aliased frequencies
                      % ignore frequencies stronger than 1/10 (-20dB) of the strongest one
                      % ignore frequencies waker than -150dBFS
                      continue
                  end
                  distortPeaks = [distortPeaks; x(i), y(i), arg(yc(i))];
              end
          end
      end
  end
endfunction
