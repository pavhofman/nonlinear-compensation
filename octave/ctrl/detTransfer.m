% Determine filter transfer at freq from calrows for LP and VD of same level (to keep characteristics same)
% Gain is against playAmpl, phaseshift against the other channel, corrected for interchannel difference
% output format: [gain, phaseShift]
function [gain, phaseShift] = detTransfer(freq, peaksVDRow, peaksLPRow, playAmpl)
  persistent AMPL_IDX = 4;  % = index of fundAmpl1
  persistent PHASEDIFF_IDX = 2;  % = index of phaseDiff

  fundLPAmpl = peaksLPRow(1, AMPL_IDX);
  phaseLPDiff = peaksLPRow(1, PHASEDIFF_IDX);
    
  gain = fundLPAmpl/playAmpl;
    
  % phaseshift between directCh and transfer channel for direct loopback (no filter) - soundcard and VD is not ideal
  phaseVDDiff = peaksVDRow(1, PHASEDIFF_IDX);  
  % LP transfer phase shift - adjusted for phaseVDDiff
  phaseShift = phaseLPDiff - phaseVDDiff;
endfunction
