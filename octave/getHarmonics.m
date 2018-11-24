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
    [fundPeaks1, distortPeaks1, errorMsg1] = findHarmonicsFromFFT(yc(:, i), y(:, i), x, Fs / nfft);
    % resize to common (=fixed) size for both channels (2 rows)
    fundPeaks(:, :, i) = resize(fundPeaks1,2,3);
    % resize to common (=fixed) size for both channels (20 rows)
    if rows(distortPeaks1) > 20
        % take 20 strongest harmonics sorted by frequencies
        distortPeaks1 = sortrows(distortPeaks1,-2);
        distortPeaks1 = resize(distortPeaks1,20,3);
        distortPeaks1 = sortrows(distortPeaks1,1);
    else
        % harmonics sorted by frequencies
        distortPeaks1 = sortrows(distortPeaks1,1);
        distortPeaks1 = resize(distortPeaks1,20,3);;
    end
    distortPeaks(:, :, i) = distortPeaks1;
    errorMsg(:, i) = cellstr(errorMsg1);
  endfor
  disp(distortPeaks);
endfunction
