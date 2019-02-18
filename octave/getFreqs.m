% find key freqs in measured peaks of one channel. Skip all zeros
function freqs = getFreqs(peaksCh)
  % transpose rows to columns
  if (rows(peaksCh) > 0)
    freqs = transpose(peaksCh(:, 1));
    % remove zeros from freqs
    freqs(freqs == 0) = [];
  else
    freqs = [];
  endif
endfunction
