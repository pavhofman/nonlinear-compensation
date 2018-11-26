% we need ampl > 0. If ampl < 0, we must invert phase
function [ampl, phaseShift] = fixMeasuredAmplPhase(ampl, phaseShift)
  if (ampl < 0)
    ampl = abs(ampl);
    % inverting phase
    phaseShift += pi;
  endif
endfunction
