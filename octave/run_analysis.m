[measuredPeaks, startingT, fundLevels, distortPeaks, result, msg] = analyse(buffer, fs, calDeviceName, compExtraCircuit, statusContains(COMPENSATING), reloadCalFiles);
setStatusResult(ANALYSING, result);
setStatusMsg(ANALYSING, msg);