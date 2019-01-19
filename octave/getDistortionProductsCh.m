% find distortion products of specified fundamental frequencies
%
% params:
%   fundPeaks
%   yc - complex DFT value of (non-negative) frequencies
%   y - absolute value of yc
%   x - (non-negative) frequencies
%   binwidth - Fs / nfft
%
% returns:
%   distortPeaks [ frequency , amplitude_in_absolute_values, angle_in_radians ]
%
function [distortPeaks] = getDistortionProductsCh(fundPeaks, x, yc, y, binwidth=1)
  % consts
  persistent MIN_LEVEL = db2mag(-150);
  distortPeaks = [];
  fundPeakBins = [];
  nffto2 = rows(y);
  ymax = max(fundPeaks(:, 2));
  for f = fundPeaks(:, 1)'
      bb = round(f / binwidth) + 1;
      fundPeakBins = [fundPeakBins; bb];
      for nh = 1:20
          i = (nh * (bb - 1)) + 1;
          if i > nffto2 - 1
              % ignore aliased frequencies
              break
          end
          if (y(i) >= (ymax / 10)) || (y(i) < MIN_LEVEL)
              % ignore frequencies stronger than 1/10 (-20dB) of the strongest one
              % ignore frequencies weaker than MIN_LEVEL
              continue
          end
          distortPeaks = [distortPeaks; x(i), y(i), arg(yc(i))];
      end
  end
  fundPeakBins = sort(fundPeakBins);

  if rows(fundPeaks) == 2
      % compute intermodulations between two strongest frequencies
      for imd_order = 2:20
          for o1 = 1 : (imd_order-1)
              o2 = imd_order - o1;
              i1 = o1 * (fundPeakBins(1) - 1);
              i2 = o2 * (fundPeakBins(2) - 1);
              for i = [ i1 + i2 + 1, i1 - i2 + 1, i2 - i1 + 1 ];
                if ...
                  % ignore aliased frequencies
                  (i < 2) || (i > nffto2 - 1) ...
                  % ignore frequencies stronger than 1/10 (-20dB) of the strongest one
                  || (y(i) >= (ymax / 10)) ...
                  % ignore frequencies waker than MIN_LEVEL
                  || (y(i) < MIN_LEVEL)
                  continue
                end
                distortPeaks = [distortPeaks; x(i), y(i), arg(yc(i))];
              end
          end
      end
  end
  distortPeaks = unique(distortPeaks, 'rows');
endfunction
