function [filtered] = filterHarmonic(signal, fs, fundamental, nharmonic, taps=500)
    % more taps, better band rejection, but much more slower
    taps = 500;
    % filter computes output from previous outputs, drop early values
    skip = 3 * taps;
    % frequency in Hz to (0,1) range
    nf = fundamental / (fs / 2);
    % width of filter borders in Hz to (0,1) range
    nfd = (fundamental / 2) / (fs / 2);

    hfilt = fir1(taps, [nharmonic*nf - nfd, nharmonic*nf + nfd]);
    sfilt = filter(hfilt, 1, signal);

    filtered = sfilt(skip:end);
endfunction
