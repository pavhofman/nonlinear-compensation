% generates frequencies to measure transfer for fundFreq. For now only single tone is supported
function freqs = getTransferFreqs(fundFreq, fs, nonInteger)
  global MAX_TRANSFER_FREQS;
  % for nonInteger mode
  persistent LIMIT_TO_NYQUIST = 0.95;

  % nonInteger frequency detection using curve fitting does not work reliably at > 0.95 Nyquist (fs/2)
  if nonInteger
    limit = LIMIT_TO_NYQUIST;
  else
    % integer Hz FFT frequency measurement works precisely
    limit = 1;
  end

  % only single frequency supported for now
  cnt = min(MAX_TRANSFER_FREQS, floor((limit * fs/2 - 1) / fundFreq));
  writeLog('DEBUG', 'Generating %d transfer freqs for fundFreq %f and fs %d', cnt, fundFreq, fs);
  freqs = linspace(fundFreq, fundFreq * cnt, cnt);
end