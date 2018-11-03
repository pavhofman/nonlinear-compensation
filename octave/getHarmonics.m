# calculating FFT + first 10 harmonics
# return: peaks [ freq , power, angle ]
function [peaks, x, y] = getHarmonics(samples, fs)
  # fft length - even number
  nfft = min(floor(length(samples)/2) * 2, 2^16);

  
  data = samples(1:nfft);
  winlen = length(data);
  winfun = hanning(winlen);
  waudio = zeros(nfft, 1);
  waudio(1:winlen) = data .* winfun;
  yf = fft(waudio);
  nffto2 = nfft / 2;
  # fft normalization and window compensation
  y = abs(yf(1:nffto2)) / (nffto2 * mean(winfun));
  y(y == 0) = 10^-10;
  # logarithmic y-axis
  y = 20 * log10(y);
  x = linspace(1, fs/2, nffto2);

  # finding peaks
  # [ freq , power, angle ]
  merged = [x', y, arg(yf(1:nffto2)) * 180/pi];
  sorted = sortrows(merged, [-2]);

  peaks = repmat([0,-999,0],10,1);
  ff = sorted(1, 1);
  fa = sorted(1, 2);
  fp = sorted(1, 3);
  peaks(1, :) = [ ff, fa, 0 ];
  binwidth = fs / nfft;
  skip=int32(1.5*ff/binwidth);
  merged2 = merged(skip:nffto2, :);
  sorted2 = sortrows(merged2, [-2]);
  for i = 1:100
      r = sorted2(i, :);
      n =int32(r(1) / ff);
      if abs(r(1) - (n * ff)) < 10
          if n <= 10 && peaks(n, 1) == 0
              peaks(n, :) = [r(1), r(2), mod(r(3) - fp, 360)];
          end
      end
  end
endfunction
