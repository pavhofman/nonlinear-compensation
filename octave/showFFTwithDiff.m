function showFFTwithDiff(wavPath, channel, label, plotID, plotsCnt)

    [recorded, fs] = audioreadAndCut(wavPath, channel);

    measfreq = 1000;

    [refGain, phaseShift, ys, bins] = measurePhase(recorded, fs, measfreq, true);

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

    plotDiff(recorded - reference, plotID + 1, plotsCnt, label);

endfunction
