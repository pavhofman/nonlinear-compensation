function showFFTwithDiff(wavPath, channel, label, plotID, plotsCnt)

    [recorded, fs] = audioreadAndCut(wavPath, channel);

    measfreq = 1000;

    reference = getReferenceSignal(recorded, fs, measfreq);

    [fundPeaks, distortPeaks, errorMsg, x, y] = getHarmonics(recorded, fs);
    peaks = [fundPeaks; distortPeaks];

    fprintf([label ':\n']);
    fprintf('%8.2f Hz, %7.2f dB, %7.2f dg\n', convertPeaksToPrintable(peaks)');

    label2 = cstrcat(label, ' (fundamental ~',
        num2str(peaks(1,1), '%.2f'), ' kHz, ',
        num2str(peaks(1,2), '%.2f'), ' dB)');

    [fundPeaks, distortPeaks, errorMsg, x, y] = getHarmonics(recorded - reference, fs);
    peaks = [fundPeaks; distortPeaks];
    drawHarmonics(x, y, label2, plotID, plotsCnt, [-140, -70]);

    plotDiff(recorded - reference, plotID + 1, plotsCnt, label);

endfunction
