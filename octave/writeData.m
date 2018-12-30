% for now only showing fft
function writeData(buffer, fs, restart)
  if (restart)
    % re-initialize FFT figure
    %showFFTFigure([], fs)
  endif
  %showFFTFigure(buffer, fs);
endfunction
