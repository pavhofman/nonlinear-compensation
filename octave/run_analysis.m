[measuredPeaks, startingT, fundPeaks, distortPeaks, result] = analyse(buffer, fs, calDeviceName, compExtraCircuit, statusContains(COMPENSATING), reloadCalFiles);
setStatusResult(ANALYSING, result);
reloadCalFiles = false;