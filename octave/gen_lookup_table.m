pkg load miscellaneous
pkg load control
#pkg load signal
#pkg load optim


# values obtained from measure_phase.m
# TODO - merging the two scripts. 
# But polynomial can be generated only when the phase shift is correctly detected 
# (i.e. only one peak, recorded and reference waveforms are at the end properly aligned!

# all values should be identical for both channels
offset = 9600;
phaseshift = -3.668867597605448e-01;
measfreq = 1000;

# at least 2 secs
wavPath = "/home/hestia/tmp/octave/wavs/juli/recorded.wav";

# 1 = left, 2 = right
channel = 2;


# the polynomial will transform recorded to reference. Adjust gain of the generated reference sine to fit the recorded first harmonics.
refGain = db2mag(-3.5);

# calculating FFT + first 10 harmonics
# return: peaks [ freq , power, angle ]
function [peaks, x, y] = getHarmonics(samples, fs)
  # fft length (must be 2^n)
  nfft = 2^16;
  
  data = samples(1:nfft);
  winlen = length(data);
  winfun = hanning(winlen);
  waudio = zeros(nfft, 1);
  waudio(1:winlen) = data .* winfun;
  yf = fft(waudio);
  nffto2 = nfft / 2;
  # fft normalization and window compensation
  y = abs(yf(1:nffto2)) / (nffto2 * mean(winfun));
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

function drawHarmonics(x, y, label, plotID, plotsCnt)
  subplot(plotsCnt,1,plotID);
  semilogx(x, y, 'linewidth', 1.5, 'color', 'black');
  grid('on');
  ylim([-180 0])
  axis([900 10000]);
  xlabel('Frequency (Hz)', 'fontsize', 10);
  ylabel('Magnitude (dB)', 'fontsize', 10);
  title(label);
  % change the tick labels of the graph from scientific notation to floating point:
  xt = get(gca,'XTick');
  set(gca,'XTickLabel', sprintf('%.0f|',xt))
endfunction

function showFFT(series, label, plotID, fs, plotsCnt)
  [ peaks, x, y ] = getHarmonics(series, fs);
  drawHarmonics(x, y, label, plotID, plotsCnt);

  fprintf([label ':\n']);
  fprintf('%8.2f Hz, %7.2f dB, %7.2f dg\n', peaks');
endfunction


format long e;
[recorded, fs] = audioread(wavPath);
if columns(recorded) > 1
    % convert to mono
    recorded = recorded(offset + 1:end, channel);
end

t = 0:1/fs:length(recorded)/fs;
t = t(1:length(recorded));


reference = cos(2*pi * measfreq * t + phaseshift) * refGain;
reference = reference';

recoveredPolyCoeffs = 8
recoveredPoly = polyfit(recorded, reference, recoveredPolyCoeffs);
# normalizing linear gain to 1 (index last - 1)
recoveredPoly = recoveredPoly / recoveredPoly(recoveredPolyCoeffs);


plotsCnt = 4;
showFFT(recorded, "Recorded", 1, fs, plotsCnt);


recovered = polyval(recoveredPoly, recorded);
showFFT(recovered, "Recovered", 2, fs, plotsCnt);


printf("Compensation Polynomial (copy to capture route 'polynom [ xx xx xx ...]'):\n");
disp(fliplr(recoveredPoly));

##############################################################################
#####š Recovery with Inverted Lookup Table from Forward Polynomial  ##########
##############################################################################


fwPolyCoeffs = 8;
fwPoly = polyfit(reference, recorded, fwPolyCoeffs);
# normalize linear gain  to 1 (index last - 1)
fwPoly = fwPoly / fwPoly(fwPolyCoeffs);

printf("Forward Polynomial:\n");
disp(fliplr(fwPoly));

showFFT(polyval(fwPoly, reference), "Estimated with forward polynomial", 3, fs, plotsCnt);

MIN_INT24 = -2147483648/256;
MAX_INT24 = -MIN_INT24 - 1;
TOTAL_INT24 = MAX_INT24 - MIN_INT24 + 1;

# notation: all xxxNormXxx variables refer to range <-1, 1>

# maximum value of the fw polynomial. For this range polynomial values will be calculated
fwNormLimit = refGain * 1; 

normStep = (1 - (-1))/TOTAL_INT24;
# number of steps in one half of the range (negative, positive)
fwHalfSteps = round(fwNormLimit/normStep);

fwNormRange = linspace(-fwNormLimit, fwNormLimit, (2*fwHalfSteps) + 1);

# scaler from norm level to int24
scaler = 1/normStep;

# calculated forward values, scaled to int24, centered around 0
centeredFw = round(polyval(fwPoly, fwNormRange)* scaler);

# shifting for positive vector indices
# TODO - negative values close to bottom? - will fail as index in inversed vector!
fw = centeredFw - MIN_INT24;

# filling bottom and top linear sections of the lookup table
minFw = fw(1);
maxFw = fw(end);

# bottom - straight line from 1 (first index in octave array) to the first value of fw
bottomLinear = round(linspace(1, minFw, -MIN_INT24 - fwHalfSteps + 1));
# top - straight line from last value of fw to MAX_INT24 - final index
topLinear = round(linspace(maxFw, TOTAL_INT24, MAX_INT24 - fwHalfSteps + 1));

# joining - the boundary elements overlaying with fw must be skipped (thus the "end -1" and "2")
wholeRange = [ bottomLinear(1:end - 1), fw, topLinear(2:end)];

# inversing the vector - creating the inverse table. Simple in octave :-)
lookupTable (wholeRange) = 1: length(wholeRange);

#### checking results

# scaling recorded data from <-1, 1> to <1, TOTAL_INT24>
scaledRecorded = round(recorded * scaler) - MIN_INT24;

# recovering with the lookup  table
recoveredWithLookup = arrayfun(@(x) lookupTable(x), scaledRecorded);

#plotting recovered results
normRecovLookup = (recoveredWithLookup + MIN_INT24)/scaler;
showFFT(normRecov2, "Recovered with forward lookup", 4, fs, plotsCnt);
return;
