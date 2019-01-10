% find key freqs in measured peaks of one channel. measuredPeaksCh has always 2 rows. Only one zero.
function freqs = getFreqs(fundPeaksCh)
  % transpose rows to columns
  freqs = fundPeaksCh(:, 1)';
endfunction
