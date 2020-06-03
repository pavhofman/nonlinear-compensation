% Detemines transfer filename for freq and circuit. Transfer files are stored in transfDir
function filename = getTransferFilename(freq, extCircuit)
  global transfDir;

  % floating point freq is supported - rounding for now
  filename = sprintf('transfer_%s_%s.dat', round(freq), extCircuit);
  filename = getFilePath(filename, transfDir);
endfunction