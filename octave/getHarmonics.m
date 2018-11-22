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
function [peaks, x, y] = getHarmonics(samples, Fs, window_name = 'hanning', fuzzy = 0, fundFreq=0)
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
  peaks = [];
  for i = 1:columns(yf)
    columnPeaks = findHarmonicsFromFFT(Fs, nfft, x, yf(:, i), fuzzy, y(:, i), fundFreq);
    peaks(:, :, i) = columnPeaks;
    columnPeaks2 = findHarmonicsFromFFT(Fs, nfft, x, yf(:, i), fuzzy, y(:, i), -columnPeaks(1, 1));
    peaks(:, :, columns(yf) + i) = columnPeaks2;
  endfor
endfunction

function [out, winweight] = applyWindow(in, winfun)
  winfun = repmat(winfun, 1, columns(in));
  out = in .* winfun;
  winweight = mean(winfun)(1);
endfunction
