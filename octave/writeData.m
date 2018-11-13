% for now only showing fft every fs samples
function writeData(buffer, fs, restart)
  persistent writeBuffer = [];
  
  if (restart)
    writeBuffer = [];
  endif
  
  if (length(writeBuffer) >= fs)
    showFFT(writeBuffer, "Output", 1, fs, 1);
    writeBuffer = [];
  else
    writeBuffer = [writeBuffer; buffer];
  end
endfunction