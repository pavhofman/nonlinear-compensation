function result = hasAnyPeak(peaksCh)
  % any freq (col idx 1) > 0
  result = any(peaksCh(peaksCh(:, 1) > 0));
endfunction