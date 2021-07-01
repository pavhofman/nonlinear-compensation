% polycompensation running
result = RUNNING_OK_RESULT;
msg = '';
buffer(:, PLAY_CH_ID) = ppval(pp, buffer(:, PLAY_CH_ID));
% buffer(:, PLAY_CH_ID) = polyval(pp, buffer(:, PLAY_CH_ID));

setStatusResult(POLYCOMPENSATING, result);
setStatusMsg(POLYCOMPENSATING, msg);