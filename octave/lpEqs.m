function [output] = lpEqs(t, distortF, amplA, phaseA, amplD, phaseD, gainVD, distortLPGain, distortLPPhaseShift, fundLPGain, phaseShiftAByLP)
  % eq 1 - fitting VD distortion at distortF
  % amplitude D was attenuated by gainVD
  sineD_VD = cos(2*pi * distortF * t + phaseD) * amplD * gainVD;
  % amplitude A was at full scale for the incoming level of fundamental freq
  sineA_VD = cos(2*pi * distortF * t + phaseA) * amplA;
  sineVD =  sineD_VD + sineA_VD;
  
  % eq 2 - fitting LP distortion at distortF
  % amplitude D was attenuated by gain of the filter at distortion freq
  % phase D was shifted by LP transfer at distortion freq
  sineD_LP = cos(2*pi * distortF * t + phaseD + distortLPPhaseShift)* amplD * distortLPGain;
  % amplitude A was at full scale for the incoming level of fundamental freq
  sineA_LP = cos(2*pi * distortF * t + phaseA + phaseShiftAByLP)* amplA* fundLPGain/gainVD;
  
  sineLP = sineD_LP + sineA_LP;
  output = [sineVD; sineLP];
endfunction