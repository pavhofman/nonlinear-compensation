% Detemines transfer filename for freq and circuit. Transfer files are stored in dataDir_EXTRA_EXTRA_TRANSFER_DIR
function filename = getTransferFilename(freq, extCircuit)
  global dataDir;
  global EXTRA_TRANSFER_DIR;
  
  filedir = [dataDir '_' EXTRA_TRANSFER_DIR];
  % creating the directory should it not exist
  if !exist(filedir, 'dir')
    mkdir(filedir);
  endif

  filename = ['transfer_' num2str(freq) '_' extCircuit '.dat'];
  filename = genDataPath(filename, filedir);
endfunction