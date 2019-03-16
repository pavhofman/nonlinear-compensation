% Offset must be large enough to skip samples from the first alsa period where some garbled data appears.
% Alsa period size could be read precisely from /proc/asound/cardXXX/pcmXc/sub0/hw_params
% Safe bet is 200ms.
function [audiodata, fs] = audioreadAndCut(sourceFile, chanList=[], skipFromStartFs=0.2);
    [audiodata, fs] = audioread(sourceFile);
    offset = skipFromStartFs * fs;
    if columns(audiodata) > 1 && ~isempty(chanList)
        % cut, use only chanList
        audiodata = audiodata(offset + 1:end - offset, chanList);
    else
        % all channels, cut only
        audiodata = audiodata(offset + 1:end - offset, :);
    end
endfunction
