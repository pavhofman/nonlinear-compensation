% calculating FFT + harmonics up to Fs
%
% computes FFT from number of samples that is maximum whole multiple of Fs
%
% hanning window is used if precise_amplitude is 0
% flattop window is used if precise_amplitude is 1
%
% frequency in peaks is non-zero only if the harmonics is a peak
% if there is no peak peaks.amplitude is maximum of 3 bins which are
% the most close to the expected frequency of the harmonics
%
% returns:
%   peaks [ frequency , amplitude_in_abs_value, angle_in_radians ]
%   x - freqencies
%   y - amplitudes_in_abs_value
%
function [fundPeaks, distortPeaks, errorMsg, x, y] = getHarmonics(samples, Fs, window_name = 'hanning', fuzzy = 0, fundFreq=0)
  nfft = Fs * floor(length(samples)/Fs);
  data = samples(1:nfft, :);
  switch (window_name)
      case { 'rect', 'rectangular' }
          winweight = 1;
      case { 'hann', 'hanning' }
          [data, winweight] = applyWindow(data, hanning(length(data)));
      case { 'flattop' }
          [data, winweight] = applyWindow(data, flattopwin(length(data)));
      otherwise
          error(sprintf('unknown window %s\n', window_name));
  endswitch
  yf = fft(data);
  nffto2 = (nfft / 2) + 1;
  x = double(Fs/2) * linspace(0, 1, nffto2);
  yf = yf(1:nffto2, :) / (nffto2 * winweight);
  y = abs(yf);
  fundPeaks = [];
  distortPeaks = [];
  for i = 1:columns(yf)
    [fundPeaks1, distortPeaks1, errorMsg1] = findHarmonicsFromFFT(yf(:, i), y(:, i), x, Fs / nfft);
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

function [out, winweight] = applyWindow(in, winfun)
  winfun = repmat(winfun, 1, columns(in));
  out = in .* winfun;
  winweight = mean(winfun)(1);
endfunction
