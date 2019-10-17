% calculating FFT + harmonics up to Fs
%
% computes FFT from number of samples that is maximum whole multiple of Fs
%
% returns:
%   x - bin IDs
%   yc - complex amplitudes
%   nfft - number of FFT points
%
function [x, yc, nfft] = computeFFT(samples, fftLength, window_name = 'rect')
  nfft = fftLength * floor(rows(samples)/fftLength);
  data = samples(1:nfft, :);
  switch (window_name)
      case { 'rect', 'rectangular' }
          winweight = 1;
      case { 'hann', 'hanning' }
          [data, winweight] = applyWindow(data, hanning(nfft));
      case { 'flattop' }
          [data, winweight] = applyWindow(data, flattopwin(nfft));
      otherwise
          error(sprintf('unknown window %s\n', window_name));
  endswitch
  nffto2 = (nfft / 2) + 1;
  x = double(fftLength/2) * linspace(0, 1, nffto2);
  yc = fft(data)(1:nffto2, :) / (nffto2 * winweight);
endfunction

function [out, winweight] = applyWindow(in, winfun)
  winfun = repmat(winfun, 1, columns(in));
  out = in .* winfun;
  winweight = mean(winfun)(1);
endfunction
