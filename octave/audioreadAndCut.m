function [audiodata, fs] = audioreadAndCut(wavPath, channel=1);
    [audiodata, fs] = audioread(wavPath);

    % Offset must be large enough to skip samples from the first alsa period where some garbled data appears.
    % Alsa period size could be read precisely from /proc/asound/cardXXX/pcmXc/sub0/hw_params
    % Safe bet is 200ms.
    offset = 0.2 * fs;

    if columns(audiodata) > 1
        % convert to mono and cut
        audiodata = audiodata(offset + 1:end - offset, channel);
    else
        % cut
        audiodata = audiodata(offset + 1:end - offset);
    end
endfunction
