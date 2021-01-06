function updatePanelTitle(dirStruct, info)
  global DIR_REC;
  dirStr = ifelse(dirStruct.dir == DIR_REC, 'Capture', 'Playback');

  if isstruct(info)
    rateStr = sprintf(' %d Hz', info.fs);
  else
    rateStr = '';
  end

  title = sprintf('%s %s', dirStr, rateStr);
  setFieldTitle(dirStruct.panel, title);
end