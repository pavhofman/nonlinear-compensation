% init sourceStruct
if sourceStruct.src == PLAYREC_SRC
  sourceStruct.name = getPlayrecDevName(playRecConfig.recDeviceID);
  addStatus(PASSING);
elseif sourceStruct.src == FILE_SRC
  sourceStruct.name = getBasename(sourceStruct.file);
  addStatus(PASSING);
else
  sourceStruct.name = 'None';
  setStatus(PAUSED);
end
