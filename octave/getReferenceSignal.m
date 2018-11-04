function [reference] = getReferenceSignal(recorded, fs, measfreq)
    [refGain, phaseShift, ys, bins] = measurePhase(recorded, fs, measfreq, false);

    % generating the reference sine
    t = 0:1/fs:length(recorded)/fs;
    t = t(1:length(recorded))';
    reference = cos(2*pi * measfreq * t + phaseShift)* refGain;
endfunction
