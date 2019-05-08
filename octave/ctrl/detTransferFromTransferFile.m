% Determine filter transfer at freq using pre-recorded fresferFiles for LP and VD
% Gain is against playAmpl, phaseshift against the other channel, corrected for interchannel difference)
% output format: [gain, phaseShift]
function [gain, phaseShift] = detTransferFromTransferFile(freq, extCircuit)
  transferFilename = getTransferFilename(freq, extCircuit);
  load(transferFilename);
  % loading transfRec variable

  peaksRow = transfRec.peaksRow;
  [gain, phaseShift] = detTransfer(peaksRow);  
endfunction