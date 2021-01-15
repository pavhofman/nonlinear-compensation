% Detemines transfer filename for freq and circuit. Transfer files are stored in transfDir
function filepath = getTransferFilename(freq, extCircuit)
  global transfDir;

  % floating point freq is supported - rounding for now
  filename = sprintf('transfer_%d_M%d_%s.dat', round(freq), getChMode(), extCircuit);
  filepath = getFilePath(filename, transfDir);
end