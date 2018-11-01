function showFFTwithDiff(wavPath, channel, label, plotID, plotsCnt)
    format long;
    [recorded, fs] = audioread(wavPath);

    % Offset must be large enough to skip samples from the first alsa period where some garbled data appears.
    % Alsa period size could be read precisely from /proc/asound/cardXXX/pcmXc/sub0/hw_params
    % Safe bet is 200ms.
    offset = 0.2 * fs;

    if columns(recorded) > 1
        % convert to mono
        recorded = recorded(offset + 1:end - offset, channel);
    end

    showFFT(recorded, label, plotID, fs, plotsCnt);

    measfreq = 1000;

    [refGain, phaseShift, ys, bins] = measurePhase(recorded, fs, measfreq);

    plotDiff(recorded, fs, measfreq, refGain, phaseShift, ys, bins, plotID + 1, plotsCnt, label);
endfunction
