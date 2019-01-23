% find key freqs in measured peaks of one channel. Skip all zeros
function freqs = getFreqs(fundPeaksCh)
  % transpose rows to columns
  if (rows(fundPeaksCh) > 0)
    freqs = transpose(fundPeaksCh(:, 1));
    % remove zeros from freqs
    freqs(freqs == 0) = [];
  else
    freqs = [];
  endif
endfunction
