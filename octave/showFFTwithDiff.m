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

    measfreq = 1000;

    [refGain, phaseShift, ys, bins] = measurePhase(recorded, fs, measfreq);

    % generating the reference sine
    t = 0:1/fs:length(recorded)/fs;
    t = t(1:length(recorded))';
    reference = cos(2*pi * measfreq * t + phaseShift)* refGain;

    [ peaks, x, y ] = getHarmonics(recorded, fs);

    fprintf([label ':\n']);
    fprintf('%8.2f Hz, %7.2f dB, %7.2f dg\n', peaks');

    label2 = cstrcat(label, ' (fundamental ~',
        num2str(peaks(1,1), '%.2f'), ' kHz, ',
        num2str(peaks(1,2), '%.2f'), ' dB)');

    [ peaks, x, y ] = getHarmonics(recorded - reference, fs);
    drawHarmonics(x, y, label2, plotID, plotsCnt, [-140, -70]);

    plotDiff(recorded - reference, fs, bins, plotID + 1, plotsCnt, label);

endfunction
