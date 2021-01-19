function updatePanelTitle(dirStruct, infoStruct)
  global DIR_REC;
  global chMode;
  global MODE_DUAL_SE;

  dirStr = ifelse(dirStruct.direction == DIR_REC, 'Capture', 'Playback');
  chModeStr = ifelse(chMode == MODE_DUAL_SE, 'SE', 'BAL');

  if isstruct(infoStruct)
    rateStr = sprintf(' %d Hz', infoStruct.fs);
  else
    rateStr = '';
  end

  title = sprintf('%s - %s %s', dirStr, chModeStr, rateStr);
  setFieldTitle(dirStruct.panel, title);
end