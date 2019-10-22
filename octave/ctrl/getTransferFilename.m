% Detemines transfer filename for freq and circuit. Transfer files are stored in dataDir_EXTRA_EXTRA_TRANSFER_DIR
function filename = getTransferFilename(freq, extCircuit)
  global dataDir;
  global EXTRA_TRANSFER_DIR;
  
  filedir = [dataDir '_' EXTRA_TRANSFER_DIR];
  % creating the directory should it not exist
  if !exist(filedir, 'dir')
    mkdir(filedir);
  endif

  % floating point freq is supported - rounding for now
  filename = ['transfer_' num2str(round(freq)) '_' extCircuit '.dat'];
  filename = genDataPath(filename, filedir);
endfunction