% removing calPeaks older than MAX_CALIB_ROW_AGE
function calPeaks = removeOutdatedCalPeaks(calPeaks, timestamp)
  global MAX_CALIB_ROW_AGE;
  % calPeaks: time, fundPhaseDiff1, fundPhaseDiff2, playAmpl1, playAmpl2, fundAmpl1, fundAmpl2, f1, f2, f3...... where f1, f2,... are distortion freqs in the same order as freqs

  % calibration time is in the first column
  outdatedRowIDs = find(calPeaks(:, 1) < (timestamp - MAX_CALIB_ROW_AGE));
  if ~isempty(outdatedRowIDs)
    writeLog('INFO', "Removing outdated rows IDs: %s", num2str(outdatedRowIDs));
    calPeaks(outdatedRowIDs, :) = [];
  endif
endfunction