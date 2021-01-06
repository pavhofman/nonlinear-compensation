function updatePanelTitle(dirStruct, infoStruct)
  global DIR_REC;
  dirStr = ifelse(dirStruct.direction == DIR_REC, 'Capture', 'Playback');

  if isstruct(infoStruct)
    rateStr = sprintf(' %d Hz', infoStruct.fs);
  else
    rateStr = '';
  end

  title = sprintf('%s %s', dirStr, rateStr);
  setFieldTitle(dirStruct.panel, title);
end