function [output] = lpEqs(t, distortF, amplA, phaseA, amplD, phaseD, gainRD, gainLPAtDistort, phaseLPAtDistort, gainAByLP, phaseAByLP)
  % eq 1
  % amplitude D was attenuated by gainRD
  % amplitude A was at full scale for the incoming level of fundamental freq
  out1 = cos(2*pi * distortF * t + phaseD)* amplD * gainRD + cos(2*pi * distortF * t + phaseA)* amplA;
  
  % eq 2
  % amplitude D was attenuated by gain of the filter at distortion freq
  % phase D was shifted by LP transfer at distortion freaq
  
  % amplitude A was at full scale for the incoming level of fundamental freq
  
  out2 = cos(2*pi * distortF * t + phaseD + phaseLPAtDistort)* amplD * gainLPAtDistort + cos(2*pi * distortF * t + phaseA + phaseAByLP)* amplA * gainAByLP;
  output = [out1; out2];
endfunction