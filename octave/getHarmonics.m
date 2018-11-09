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
function [peaks, x, yf] = getHarmonics(samples, Fs, precise_amplitude = 0)
   nfft = Fs * floor(length(samples)/Fs);
  data = samples(1:nfft);
  if precise_amplitude == 0
      winfun = flattopwin(length(data));
  else
      winfun = hanning(length(data));
  end
  waudio = data .* winfun;
  yf = fft(waudio);
  nffto2 = (nfft / 2) + 1;

  x = double(Fs/2) * linspace(0, 1, nffto2);
  yf = yf(1:nffto2) / (nffto2 * mean(winfun));
  ya = abs(yf);

  peaks = findHarmonicsFromFFT(Fs, nfft, x, yf, ya);
endfunction
