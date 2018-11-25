% calculating FFT + harmonics up to Fs
%
% computes FFT from number of samples that is maximum whole multiple of Fs
%
% hanning window is used if precise_amplitude is 0
% flattop window is used if precise_amplitude is 1
%
% returns:
%   fundPeaks [ frequency , amplitude_in_absolute_values, angle_in_radians ]
%   disgtortPeaks [ frequency , amplitude_in_absolute_values, angle_in_radians ]
%   errorMsg - nonempty if finding distortion frequencies has failed
%   x - freqencies
%   y - amplitudes_in_abs_value
%
function [fundPeaks, distortPeaks, errorMsg, x, y] = getHarmonics(samples, Fs, window_name = 'hanning')
  [x, yc, nfft] = computeFFT(samples, Fs, window_name);
  y = abs(yc);
  fundPeaks = [];
  distortPeaks = [];
  for i = 1:columns(yc)
    ycCh = yc(:, i);
    yCh = y(:, i);
    [fundPeaksCh, errorMsgCh] = findFundPeaksCh(x, ycCh, yCh);
    [distortPeaksCh] = getDistortionProductsCh(fundPeaksCh, x, ycCh, yCh, Fs / nfft);
    % resize to common (=fixed) size for both channels (2 rows)
    fundPeaks(:, :, i) = resize(fundPeaksCh,2,3);
    % resize to common (=fixed) size for both channels (20 rows)
    if rows(distortPeaksCh) > 20
        % take 20 strongest harmonics sorted by frequencies
        distortPeaksCh = sortrows(distortPeaksCh,-2);
        distortPeaksCh = resize(distortPeaksCh,20,3);
        distortPeaksCh = sortrows(distortPeaksCh,1);
    else
        % harmonics sorted by frequencies
        distortPeaksCh = sortrows(distortPeaksCh,1);
        distortPeaksCh = resize(distortPeaksCh,20,3);;
    end
    distortPeaks(:, :, i) = distortPeaksCh;
    errorMsg(:, i) = cellstr(errorMsgCh);
  endfor
endfunction
