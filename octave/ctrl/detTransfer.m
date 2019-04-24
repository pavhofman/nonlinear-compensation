% Determine filter transfer at freq from calrows for LP and VD of same level (to keep characteristics same)
% Gain is against playAmpl, phaseshift against the other channel, corrected for interchannel difference
% output format: [gain, phaseShift]
function [gain, phaseShift] = detTransfer(peaksRow, playAmpl)
  global AMPL_IDX;  % = index of fundAmpl1
  global PHASEDIFF_IDX;  % = index of phaseDiff

  fundAmpl = peaksRow(1, AMPL_IDX);
  gain = fundAmpl/playAmpl;
  
  phaseShift = peaksRow(1, PHASEDIFF_IDX);  
endfunction
