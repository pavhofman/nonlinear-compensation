% Generates compensation reference (distortion peaks with inverted phase). Supports only single fundamental frequency, for now.
function reference = genCompenReference(fundPeaks, distortPeaks, currPhase, currAmpl, fs, startingT, samplesCnt)
  % first harmonics = zero
  reference = zeros(samplesCnt, 1);
  % for now only single fundamental frequency
  measfreq = fundPeaks(1, 1);
  origAmpl = fundPeaks(1, 2);
  origPhase = fundPeaks(1, 3);
  compenPhase = currPhase - origPhase;
  scale = currAmpl / origAmpl;
  step = 1/fs;
  t = linspace(startingT, startingT + (samplesCnt - 1) * step, samplesCnt)'; 
  for i = (1:length(distortPeaks))
    gain = distortPeaks(i, 2);
    if (gain > 1e-8)
      % inverted phase 
      % harmonicNb - for now works only with single fundamental frequency - i.e. first row = second harmonics
      harmonicNb = i + 1;
      shift = (distortPeaks(i, 3) + compenPhase * harmonicNb) - pi;
      reference += cos(2*pi * harmonicNb * measfreq * t + shift) * gain * scale;
     endif
  endfor
endfunction
