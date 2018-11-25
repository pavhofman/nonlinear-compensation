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
function [fundPeaks, errorMsg] = findFundPeaks(x, yc, y)
  fundPeaks = zeros(0, 3);
  errorMsg = '';

  nffto2 = rows(y);

  [ymax, iymax] = max(y);
  if ymax < 1e-5
      errorMsg = 'no peaks stronger than -100dBFS';
      return
  end

  for b = find(y >= ymax/10)'
      bb = b - 1;
      if (bb < 1) || (x(bb) < 10) || ((bb < nffto2) && (y(bb) < y(bb+1))) || (y(bb-1) > y(bb))
          % skip frequencies under 10Hz and those which are not a local maximum
          continue
      end
      if rows(fundPeaks) > 2
          errorMsg = 'too many fundamental peaks';
          break
      end
      fundPeaks = [fundPeaks; x(bb), y(bb), arg(yc(bb))];
  end
endfunction
