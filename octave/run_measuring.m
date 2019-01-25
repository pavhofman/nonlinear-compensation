% transfer measurement running
[transfer, result] = measureTransfer(buffer, fs, transfer, genAmpl, restartMeasuring);
restartMeasuring = false;
if (result == 1)
  % finished
  if (exist(transferFile, 'file'))
    % stored variable transfers
    load(transferFile);
  else
    transfers = [];
  endif
  % TODO - simplify array operations!
  % removing transfer for this freq
  idx = [];
  for i = 1:rows(transfers)
    if (transfers(i).freq == transfer.freq)
       idx = [idx, i];
    endif    
  endfor
  transfers(idx, :) = [];
  % adding new one
  if (length(transfers) == 0)
    transfers = transfer;
  else
    transfers = [transfers; transfer];
  endif
  
  % sorting by frequency
  [tmp ind]=sort([transfers.freq]);
  transfers = transfers(ind);
  printf('Adding transfer line for freq %d\n', transfer.freq);
  printf('Storing %d transfer lines into %s\n', rows(transfers), transferFile);
  % saving updated transfers to file
  save(transferFile, 'transfers');
  cmd = {PASS};
endif

