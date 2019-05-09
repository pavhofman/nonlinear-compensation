% generates frequencies to measure transfer for fundFreq. For now only single tone is supported
function freqs = getTransferFreqs(fundFreq, fs)
  % const
  persistent MAX_FREQS = 10;

  % only single frequency supported for now
  cnt = min(MAX_FREQS, floor((fs/2 - 1) / fundFreq));
  freqs = fundFreq:fundFreq:fundFreq * cnt;
endfunction