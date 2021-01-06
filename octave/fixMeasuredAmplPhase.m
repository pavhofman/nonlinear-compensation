% we need ampl > 0. If ampl < 0, we must invert phase
function [ampl, phaseShift] = fixMeasuredAmplPhase(ampl, phaseShift)
  if (ampl < 0)
    % inverting amplitude
    ampl = -ampl;
    % inverting phase
    phaseShift += pi;
  end
end
