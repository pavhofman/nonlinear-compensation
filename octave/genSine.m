% Generates samplesCnt of cosine signal starting at startingT
function signal = genSine(freq, fs, startingT, samplesCnt)
  % fixed gain for now
  persistent gain = db2mag(-3);
  step = 1/fs;
  t = linspace(startingT, startingT + (samplesCnt - 1) * step, samplesCnt)';
  
  signal = cos(2 * pi * freq * t ) * gain;
endfunction
