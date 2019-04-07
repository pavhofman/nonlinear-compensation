[measuredPeaks, startingT, fundLevels, distortPeaks, result, msg] = analyse(buffer, fs, compRequest, reloadCalFiles);
% calFiles already reloaded (if requested)
reloadCalFiles = false;

setStatusResult(ANALYSING, result);
setStatusMsg(ANALYSING, msg);