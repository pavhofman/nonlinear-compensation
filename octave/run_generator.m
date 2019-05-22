% generator running
% generating buffer-length of sine at genStartingT
channelCnt = columns(buffer);

% copying last channel values up to channelCnt - must be columns!

genFunds(end + 1: channelCnt) = genFunds{end};

buffer = genSine(genFunds, fs, genStartingT, rows(buffer));
setStatusResult(GENERATING, RUNNING_OK_RESULT);
% advancing startingT to next cycle
genStartingT = genStartingT + rows(buffer) * 1/fs;