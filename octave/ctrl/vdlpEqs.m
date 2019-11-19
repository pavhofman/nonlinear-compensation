% fitted function for nonlinear regression of calculating the DAC/ADC split distortions
function [output] = vdlpEqs(t, distortF, amplA, phaseA, amplD, phaseD, fundGainVD, fundGainLP, distortGainVD, distortGainLP, distortPhaseShiftVD, distortPhaseShiftLP, phaseShiftByFundVD, phaseShiftByFundLP)
  persistent PI2 = 2*pi;
  % eq 1 - fitting VD distortion at distortF
  % amplitude D was attenuated and shifted by VD, preceeding amplitude A by fundamental phase shift scaled to distortF
  sineD_VD = amplD * distortGainVD * cos(PI2 * distortF * t + phaseD - phaseShiftByFundVD + distortPhaseShiftVD);
  % amplitude A was at full scale for the incoming level of fundamental freq
  % amplA is being calculated for fundGainVD, no need for any linear interpolation
  sineA_VD = amplA * cos(PI2 * distortF * t + phaseA);
  sineVD =  sineD_VD + sineA_VD;
  
  % eq 2 - fitting LP distortion at distortF
  % amplitude D was attenuated and shifted by LPF, preceeding amplitude A by fundamental phase shift scaled to distortF
  sineD_LP = amplD * distortGainLP * cos(PI2 * distortF * t + phaseD - phaseShiftByFundLP + distortPhaseShiftLP);
  % amplitude A was at full scale for the incoming level of fundamental freq.
  % amplA is being calculated for fundGainVD, it must be linearly interpolated to fundGainVD
  sineA_LP = amplA * (fundGainLP/fundGainVD) * cos(PI2 * distortF * t + phaseA);
  
  sineLP = sineD_LP + sineA_LP;
  % column vector
  output = [sineVD; sineLP];
endfunction