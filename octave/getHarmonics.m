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
%   peaks [ frequency , amplitude_in_dB, angle_in_degrees ]
%   x - freqencies
%   y - amplitudes_in_dB
%
function [peaks, x, y] = getHarmonics(samples, Fs, precise_amplitude = 0)
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
  y = 20 * log10(ya);

  peaks = findHarmonics(Fs, nfft, x, yf, ya);

  disp(peaks);

  peaks(:,2) = 20 * log10(peaks(:,2));
  p1 = peaks(1,3);
  peaks(:,3) = mod((peaks(:,3) - p1) * 180/pi, 360);
endfunction
