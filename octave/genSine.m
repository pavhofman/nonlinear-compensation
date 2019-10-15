% Generates samplesCnt of cosine signal starting at genStartingT
function signal = genSine(genFunds, fs, genStartingT, samplesCnt)
  step = 1/fs;
  signal = [];
  t = linspace(genStartingT, genStartingT + (samplesCnt - 1) * step, samplesCnt);
  for channelID = 1 : length(genFunds)    
    freqs = genFunds{channelID}(:, 1);
    ampls = genFunds{channelID}(:, 2);
    if all(ampls == 0)
      % all zero ampls, zero signal
      signalCh = zeros(samplesCnt, 1);
    else
      signals = cos(2 * pi * freqs .* t ) .* ampls;
      % sum all rows, transpose to column
      signalCh = sum(signals, 1);
      
      % clipping to <-1, 1>
      signalCh(signalCh > 1) = 1;
      signalCh(signalCh < -1) = -1;
      
      signalCh = transpose(signalCh);
    endif
    signal = [signal, signalCh];
  endfor
endfunction
