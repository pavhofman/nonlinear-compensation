% Determine filter transfer at freq using pre-recorded calfiles for LP and VD (expectes only one level calibrated!).
% Gain is against playAmpl, phaseshift against the other channel, corrected for interchannel difference)
% output format: [gain, phaseShift]
function [gain, phaseShift] = detTransferFromCalFile(freq, fs, playChID, analysedChID, chMode, extCircuit, extDir = '')
  global COMP_TYPE_JOINT;
  
  peaksRow = loadCalRow(freq, fs, COMP_TYPE_JOINT, playChID, analysedChID, chMode, extCircuit, extDir);
  [gain, phaseShift] = detTransfer(peaksRow);  
endfunction