[measuredPeaks, startingTs, fundLevels, distortPeaks, result, msg] = analyse(buffer, fs, compRequest, chMode, reloadCalFiles, nonInteger);
% calFiles already reloaded (if requested)
reloadCalFiles = false;

setStatusResult(ANALYSING, result);
setStatusMsg(ANALYSING, msg);