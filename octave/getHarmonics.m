% calculating FFT + first 10 harmonics
% return: peaks [ freq , power, angle ]
function [peaks, x, y] = getHarmonics(samples, fs)
  % fft length - even number
  nfft = min(floor(length(samples)/2) * 2, 2^17);

  % determine frequency with max. amplitude
  data = samples(1:nfft);
  winfun = flattopwin(length(data));
  yf = fft(data .* winfun);
  nffto2 = nfft / 2;
  [ymax, iymax] = max(abs(yf(1:nffto2)));
  maxfreq = (iymax-1)*fs/2/(nffto2-1);

  % determine number of bins required for exact phase measurememnt
  nsamplesInPeriod = uint32(fs/maxfreq);
  nperiods = length(samples) / nsamplesInPeriod;
  if (nperiods > 10)
      nperiods = 10;
  end
  nfft = nperiods * nsamplesInPeriod;
  nfft -= mod(nfft, 2);

  % compute fft again with rectangle window
  data = samples(1:nfft);
  yf = fft(data);
  nffto2 = nfft / 2;
  % fft normalization and window compensation
  y = abs(yf(1:nffto2)) / double(nffto2);
  % logarithmic y-axis
  y = 20 * log10(y);
  y(y < -145) = -999;
  x = fs/2 * linspace(0, 1, nffto2)';

  % finding peaks
  % [ freq , power, angle ]
  merged = [x, y, arg(yf(1:nffto2)) * 180/pi];
  sorted = sortrows(merged, [-2]);
  peaks = repmat([0,-999,0],10,1);
  ff = sorted(1, 1);
  fa = sorted(1, 2);
  fp = sorted(1, 3);
  maxfreq = int32(maxfreq);
  peaks(1, :) = [ maxfreq, fa, 0 ];
  % Notice: retype is required to force double precision of the output
  binwidth = fs / double(nffto2);
  skip=int32(1.5*ff/binwidth);
  merged2 = merged(skip:nffto2, :);
  sorted2 = sortrows(merged2, [-2]);
  for i = 1:length(sorted2)
      r = sorted2(i, :);
      n = int32(r(1) / ff);
      if abs(r(1) - (n * ff)) < binwidth
          if n <= 10 && peaks(n,  1) == 0
              peaks(n, :) = [n * maxfreq, r(2), mod(r(3) - fp, 360)];
          end
      end
  end
endfunction
