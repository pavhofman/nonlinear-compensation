[measuredPeaks, startingTs, fundLevels, distortPeaks, result, msg] = analyse(buffer, fs, compRequest, chMode, reloadCalFiles, restartAnalysis, nonInteger);
% calFiles already reloaded (if requested)
reloadCalFiles = false;
restartAnalysis = false;

setStatusResult(ANALYSING, result);
setStatusMsg(ANALYSING, msg);