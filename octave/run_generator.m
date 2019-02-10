% generator running
% generating buffer-length of sine at startingT
% fixed amplitude for now
oneCh = genSine(genFreq, fs, genAmpl, startingT, rows(buffer));
buffer = repmat(oneCh, 1, columns(buffer));
setStatusResult(GENERATING, RUNNING_OK_RESULT);
% advancing startingT to next cycle
startingT += rows(buffer) * 1/fs;
