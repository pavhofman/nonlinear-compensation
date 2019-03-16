% init sinkNames
sinkStruct.names = cell();
if any(sinkStruct.sinks == PLAYREC_SINK)
  sinkStruct.names{end + 1} = getPlayrecDevName(playRecConfig.playDeviceID);
endif
if any(sinkStruct.sinks == FILE_SINK)
  sinkStruct.names{end + 1} = getBasename(sinkStruct.file);
endif
