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
%   distortPeaksCh [ frequency , amplitude_in_absolute_values, angle_in_radians ]
%
function [distortPeaksCh] = getDistortionProductsCh(fundPeaks, x, yc, y, binwidth=1)
  % consts
  global MIN_DISTORT_LEVEL;
  global MAX_DISTORT_ID;
  %const
  persistent IMD_RANGE = 8;

  distortPeaksCh = [];
  fundPeakBins = [];
  nffto2 = rows(y);
  ymax = max(fundPeaks(:, 2));
  for f = transpose(fundPeaks(:, 1))
      bb = round(f / binwidth) + 1;
      fundPeakBins = [fundPeakBins; bb];
      % TODO - fix limits!
      for nh = 1:MAX_DISTORT_ID
          i = (nh * (bb - 1)) + 1;
          if i > nffto2 - 1
              % ignore aliased frequencies
              break
          end
          if (y(i) >= (ymax / 10)) || (y(i) < MIN_DISTORT_LEVEL)
              % ignore frequencies stronger than 1/10 (-20dB) of the strongest one
              % ignore frequencies weaker than MIN_LEVEL
              continue
          end
          distortPeaksCh = [distortPeaksCh; x(i), y(i), arg(yc(i))];
      end
  end
  fundPeakBins = sort(fundPeakBins);

  if rows(fundPeaks) == 2
    % compute intermodulations between two strongest frequencies
    f1 = (fundPeakBins(1) - 1);
    f2 = (fundPeakBins(2) - 1);
    for m1 = -IMD_RANGE: IMD_RANGE
      for m2 = -IMD_RANGE: IMD_RANGE
        f = f1*m1 + f2*m2;
        idx = f + 1;
        if ...
          % ignore aliased frequencies
          (f < 1) || (f > nffto2) ...
          % ignore frequencies stronger than 1/10 (-20dB) of the strongest one
          || (y(idx) >= (ymax / 10)) ...
          % ignore frequencies waker than MIN_LEVEL
          || (y(idx) < MIN_DISTORT_LEVEL)
          continue
        end
        distortPeaksCh = [distortPeaksCh; x(idx), y(idx), arg(yc(idx))];                
      end
    end
  end
  distortPeaksCh = unique(distortPeaksCh, 'rows');
end
