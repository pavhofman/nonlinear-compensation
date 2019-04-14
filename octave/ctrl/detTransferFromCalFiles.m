% Determine filter transfer at freq using pre-recorded calfiles for LP and VD (expectes only one level calibrated!).
% Gain is against playAmpl, phaseshift against the other channel, corrected for interchannel difference)
% output format: [gain, phaseShift]
function [gain, phaseShift] = detTransferFromCalFiles(freq, fs, playAmpl, playChID, analysedChID, filterName)
  global COMP_TYPE_JOINT;
  
  peaksLPRow = loadCalRow(freq, fs, COMP_TYPE_JOINT, playChID, analysedChID, filterName);
  peaksVDRow = loadCalRow(freq, fs, COMP_TYPE_JOINT, playChID, analysedChID);
  [gain, phaseShift] = detTransfer(freq, peaksVDRow, peaksLPRow, playAmpl);
  
endfunction