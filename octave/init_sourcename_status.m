% init sourceName
if fromSource == PLAYREC_SRC
  sourceName = getPlayrecDevName(playRecConfig.recDeviceID);
  setStatus(PASSING);
elseif fromSource == FILE_SRC
  sourceName = getBasename(sourceFile);
  setStatus(PASSING);
else
  sourceName = 'None';
  setStatus(PAUSED);
endif
