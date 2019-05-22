% sending calibration command to rec side + showing lastLines in the plots
function clbkJointCalib(src, data, contCalib)
  global playInfo;
  global CMD_PLAY_AMPLS_PREFIX;
  global COMP_TYPE_JOINT;

  % joint-sides calibration needs information about current playback levels - reading from playInfo
  measuredPeaks = playInfo.measuredPeaks;
  playAmpls = cell();
  for channelID = 1:length(measuredPeaks)
    measuredPeaksCh = measuredPeaks{channelID};
    if ~isempty(measuredPeaksCh)
      playAmpls{end + 1} = transpose(measuredPeaksCh(:, 2));
    else
      playAmpls{end + 1} = [];
    endif
  endfor
  
  extraCmd = getMatrixCellsToCmdStr(playAmpls, CMD_PLAY_AMPLS_PREFIX);  
  clbkCalib(src, data, COMP_TYPE_JOINT, contCalib, extraCmd);
endfunction
