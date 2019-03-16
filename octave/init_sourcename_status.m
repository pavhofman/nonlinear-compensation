% init sourceStruct
if sourceStruct.src == PLAYREC_SRC
  sourceStruct.name = getPlayrecDevName(playRecConfig.recDeviceID);
  setStatus(PASSING);
elseif sourceStruct.src == FILE_SRC
  sourceStruct.name = getBasename(sourceStruct.file);
  setStatus(PASSING);
else
  sourceStruct.name = 'None';
  setStatus(PAUSED);
endif
