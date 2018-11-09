function [reference] = genCompenReference(peaks, currPhase, currAmpl, fs, samplesCnt)
  % first harmonics = zero
  reference = zeros(samplesCnt, 1);
  measfreq = peaks(1, 1);
  origAmpl = peaks(1, 2);
  origPhase = peaks(1, 3);
  compenPhase = currPhase - origPhase;
  scale = currAmpl / origAmpl;
  step = 1/fs;
  t = linspace(0, (samplesCnt - 1) * step, samplesCnt)';
  for i = (2:length(peaks))
    gain = peaks(i, 2);
    if (gain > 1e-8)
      % inverted phase 
      shift = (peaks(i, 3) + compenPhase * i) - pi;
      reference += cos(2*pi * i * measfreq * t + shift) * gain * scale;
     endif
  endfor
endfunction
