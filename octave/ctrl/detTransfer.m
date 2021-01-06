% Determine filter transfer at freq from calrows for LPF and VD of same level (to keep characteristics same)
% Gain is against playAmpl, phaseshift against the other channel, corrected for interchannel difference
% output format: [gain, phaseShift]
function [gain, phaseShift] = detTransfer(peaksRow)
  global AMPL_IDX;  % = index of fundAmpl1
  global PLAY_AMPL_IDX;  % = index of playAmpl1
  global PHASEDIFF_IDX;  % = index of phaseDiff

  fundAmpl = peaksRow(1, AMPL_IDX);
  playAmpl = peaksRow(1, PLAY_AMPL_IDX);
  gain = fundAmpl/playAmpl;
  
  phaseShift = peaksRow(1, PHASEDIFF_IDX);  
end
