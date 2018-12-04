% calculating FFT + harmonics up to Fs
%
% computes FFT from number of samples that is maximum whole multiple of Fs
%
% hanning window is used if precise_amplitude is 0
% flattop window is used if precise_amplitude is 1
%
% returns:
%   fundPeaks [ frequency , amplitude_in_absolute_values, angle_in_radians ]
%   distortPeaks [ frequency , amplitude_in_absolute_values, angle_in_radians ]
%   errorMsg - nonempty if finding distortion frequencies has failed
%   x - freqencies
%   y - amplitudes_in_abs_value
%
function [fundPeaks, distortPeaks, errorMsg, x, y] = getHarmonics(samples, Fs, genDistortPeaks = true, window_name = 'hanning')
  persistent maxDistortCnt = 40;
  [x, yc, nfft] = computeFFT(samples, Fs, window_name);
  y = abs(yc);
  fundPeaks = [];
  distortPeaks = zeros(maxDistortCnt, 3, columns(yc));
  for i = 1:columns(yc)
    ycCh = yc(:, i);
    yCh = y(:, i);
    [fundPeaksCh, errorMsgCh] = findFundPeaksCh(x, ycCh, yCh);
    fundPeaks(:, :, i) = fundPeaksCh;
    errorMsg(:, i) = cellstr(errorMsgCh);
    
    if (genDistortPeaks)
      [distortPeaksCh] = getDistortionProductsCh(fundPeaksCh, x, ycCh, yCh, Fs / nfft);
      % limit distortPeak to maxDistortCnt rows
      if rows(distortPeaksCh) > maxDistortCnt
          % take 20 strongest harmonics, keep unsorted
          distortPeaksCh = resize(sortrows(distortPeaksCh,-2), maxDistortCnt,3);
      end
      distortPeaks(1:length(distortPeaksCh), :, i) = distortPeaksCh;
    endif    
  endfor  
 
  printf('Determined fundamental peaks:\n');
  disp(fundPeaks);
  printf('Determined distortion peaks:\n');
  disp(distortPeaks);
endfunction