% fitted function for nonlinear regression of calculating the DAC/ADC split distortions
function [output] = vdlpEqs2(t, distortF, amplA, phaseA, amplD, phaseD, fundGainVD, fundGainLP, distortGainVD, distortGainLP, distortPhaseShiftVD, distortPhaseShiftLP, timeOffsetVD, timeOffsetLP)
  persistent PI2 = 2*pi;
  % eq 1 - fitting VD distortion at distortF
  % amplitude D was attenuated and shifted by VD, preceeding amplitude A by timeOffsetVD
  sineD_VD = amplD * distortGainVD * cos(PI2 * distortF * (t - timeOffsetVD) + phaseD + distortPhaseShiftVD);
  % amplitude A was at full scale for the incoming level of fundamental freq
  % amplA is being calculated for fundGainVD, no need for any linear interpolation
  sineA_VD = amplA * cos(PI2 * distortF * t + phaseA);
  sineVD =  sineD_VD + sineA_VD;
  
  % eq 2 - fitting LP distortion at distortF
  % amplitude D was attenuated and shifted by LPF, preceeding amplitude A by timeOffsetLP
  sineD_LP = amplD * distortGainLP * cos(PI2 * distortF * (t - timeOffsetLP) + phaseD + distortPhaseShiftLP);
  % amplitude A was at full scale for the incoming level of fundamental freq.
  % amplA is being calculated for fundGainVD, it must be linearly interpolated to fundGainVD
  sineA_LP = amplA * (fundGainLP/fundGainVD) * cos(PI2 * distortF * t + phaseA);
  
  sineLP = sineD_LP + sineA_LP;
  output = [sineVD; sineLP];
endfunction