% DFDP (jacobian) for nonlinear regression of calculating the DAC/ADC split distortions
function output = vdlpDfdp(t, distortF, amplA, phaseA, amplD, phaseD, fundGainVD, fundGainLP, distortGainVD, distortGainLP, distortPhaseShiftVD, distortPhaseShiftLP, phaseShiftByFundVD, phaseShiftByFundLP)
  persistent PI2 = 2*pi;

  % eq 1 - fitting VD distortion at distortF
  % sineD_VD = amplD * distortGainVD * cos(PI2 * distortF * t + phaseD - phaseShiftByFundVD + distortPhaseShiftVD);
  % sineA_VD = amplA * cos(PI2 * distortF * t + phaseA);
  % sineVD =  sineD_VD + sineA_VD;
  
  % amplD * distortGainVD * cos(PI2 * distortF * t + phaseD - phaseShiftByFundVD + distortPhaseShiftVD) + amplA * cos(PI2 * distortF * t + phaseA)
  
  dfdpVD = [cos(PI2 * distortF * t + phaseA),...
    -1 * amplA * sin(PI2 * distortF * t + phaseA),...
    distortGainVD * cos(PI2 * distortF * t + phaseD - phaseShiftByFundVD + distortPhaseShiftVD),...
    -1 * amplD * distortGainVD * sin(PI2 * distortF * t + phaseD - phaseShiftByFundVD + distortPhaseShiftVD)];

  
  % eq 2 - fitting LP distortion at distortF
  % sineD_LP = amplD * distortGainLP * cos(PI2 * distortF * t + phaseD - phaseShiftByFundLP + distortPhaseShiftLP);
  % sineA_LP = amplA * (fundGainLP/fundGainVD) * cos(PI2 * distortF * t + phaseA);  
  % sineLP = sineD_LP + sineA_LP;
  
  % amplD * distortGainLP * cos(PI2 * distortF * t + phaseD - phaseShiftByFundLP + distortPhaseShiftLP) + amplA * (fundGainLP/fundGainVD) * cos(PI2 * distortF * t + phaseA)
  
  dfdpLP = [(fundGainLP/fundGainVD) * cos(PI2 * distortF * t + phaseA),...
    -1 * amplA * (fundGainLP/fundGainVD) * sin(PI2 * distortF * t + phaseA),...
    distortGainLP * cos(PI2 * distortF * t + phaseD - phaseShiftByFundLP + distortPhaseShiftLP),...
    -1 * amplD * distortGainLP * sin(PI2 * distortF * t + phaseD - phaseShiftByFundLP + distortPhaseShiftLP)];
  
  % column vector
  output = [dfdpVD; dfdpLP];
endfunction