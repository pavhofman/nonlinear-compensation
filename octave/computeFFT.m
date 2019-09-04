% calculating FFT + harmonics up to Fs
%
% computes FFT from number of samples that is maximum whole multiple of Fs
%
% hanning window is used if precise_amplitude is 0
% flattop window is used if precise_amplitude is 1
%
% returns:
%   x - freqencies
%   yc - complex amplitudes
%   nfft - number of FFT points
%
function [x, yc, nfft] = computeFFT(samples, Fs, window_name = 'rect')
  nfft = Fs * floor(length(samples)/Fs);
  data = samples(1:nfft, :);
  switch (window_name)
      case { 'rect', 'rectangular' }
          winweight = 1;
      case { 'hann', 'hanning' }
          [data, winweight] = applyWindow(data, hanning(rows(data)));
      case { 'flattop' }
          [data, winweight] = applyWindow(data, flattopwin(rows(data)));
      otherwise
          error(sprintf('unknown window %s\n', window_name));
  endswitch
  nffto2 = (nfft / 2) + 1;
  x = double(Fs/2) * linspace(0, 1, nffto2);
  yc = fft(data)(1:nffto2, :) / (nffto2 * winweight);
endfunction

function [out, winweight] = applyWindow(in, winfun)
  winfun = repmat(winfun, 1, columns(in));
  out = in .* winfun;
  winweight = mean(winfun)(1);
endfunction
