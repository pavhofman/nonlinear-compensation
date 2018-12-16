% read gain and phaseshift from transfers array for specific freq
function [gain, phaseShift] = getTransferParams(transfers, freq)
  for i = 1:rows(transfers)
    transfer = transfers(i);
    if (transfer.freq == freq)
      gain = transfer.gain;
      phaseShift = transfer.phaseShift;
      break;
    endif
  endfor
endfunction
