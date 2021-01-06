% find key freqs in measured peaks of one channel. Skip all zeros
function freqs = getFreqs(peaksCh)
  % transpose rows to columns
  if (rows(peaksCh) > 0)
    freqs = transpose(peaksCh(:, 1));
    % remove zeros from freqs
    freqs(freqs == 0) = [];
  else
    freqs = [];
  end
end

%!test
%! peaksCh = [1000, 0.5, 0.5; 2000, 0.4, 0.4];
%! expected = [1000, 2000];
%! assert(expected, getFreqs(peaksCh));
% empty peaks
%! peaksCh = [];
%! expected = [];
%! assert(expected, getFreqs(peaksCh));
