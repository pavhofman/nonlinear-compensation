% for now only showing fft every fs samples
function writeData(buffer, fs, restart)
  persistent writeBuffer = [];

  if (restart)
    writeBuffer = [];
    % initialize FFT figure
    showFFTFigure(writeBuffer, fs)
  endif

  writeBuffer = [writeBuffer; buffer];

  l = length(writeBuffer);
  if (l >= fs)
    % update FFT figure
    showFFTFigure(writeBuffer(1:fs, :), fs)
    if l >= fs+1
        writeBuffer = writeBuffer(fs+1:end, :);
    else
        writeBuffer = [];
    end
  end
endfunction
