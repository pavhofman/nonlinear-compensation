% Generates samplesCnt of cosine signal starting at startingT
function signal = genSine(freq, fs, genAmpl, startingT, samplesCnt)
  step = 1/fs;
  t = linspace(startingT, startingT + (samplesCnt - 1) * step, samplesCnt)';
  
  signal = cos(2 * pi * freq * t ) * genAmpl;
endfunction
