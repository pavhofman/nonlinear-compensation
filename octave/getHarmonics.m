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
  binwidth = Fs / nfft;
  nffto2 = (nfft / 2) + 1;

  x = double(Fs/2) * linspace(0, 1, nffto2);
  y = 20 * log10(abs(yf(1:nffto2)) / (nffto2 * mean(winfun)));
  [ymax, iymax] = max(y);
  fundfreq = (iymax - 1) * binwidth;
  peaks = [];
  for nh = 1:floor(Fs/2/fundfreq)
      i = (nh * (iymax - 1)) + 1;
      hp = arg(yf(i)) * 180/pi;
      if (nh > 1)
          hp = mod(hp - fp, 360);
      else
          fp = hp;
          hp = 0;
      end
      if (i + 1 < nffto2) && y(i) > -130 && (y(i - 1) < (y(i))) && ((y(i)) > y(i + 1))
          peaks(nh, :) = [x(i), y(i), hp];
      else
          % do not report frequency if it is not a peak
          if (i + 1 < nffto2)
              nhy = [y(i-1),y(i),y(i+1)];
          else
              % skip y(nffto2) as it requires special weighting
              nhy = [y(i-1)];
          end
          peaks(nh, :) = [0, max(nhy), hp];
      end
  end
endfunction
