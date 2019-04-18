function [output] = vdlpEqs(t, distortF, amplA, phaseA, amplD, phaseD, fundVDGain, fundLPGain, distortVDGain, distortLPGain, distortLPvsVDPhaseShift, phaseShiftAByLPvsVD)
  % eq 1 - fitting VD distortion at distortF
  % amplitude D was attenuated by gainVD
  sineD_VD = cos(2*pi * distortF * t + phaseD) * amplD * distortVDGain;
  % amplitude A was at full scale for the incoming level of fundamental freq
  sineA_VD = cos(2*pi * distortF * t + phaseA) * amplA;
  sineVD =  sineD_VD + sineA_VD;
  
  % eq 2 - fitting LP distortion at distortF
  % amplitude D was attenuated by gain of the filter at distortion freq
  % phase D was shifted by LP transfer at distortion freq
  sineD_LP = cos(2*pi * distortF * t + phaseD + distortLPvsVDPhaseShift) * amplD * distortLPGain;
  % amplitude A was at full scale for the incoming level of fundamental freq
  sineA_LP = cos(2*pi * distortF * t + phaseA + phaseShiftAByLPvsVD)* amplA * fundLPGain/fundVDGain;
  
  sineLP = sineD_LP + sineA_LP;
  output = [sineVD; sineLP];
endfunction