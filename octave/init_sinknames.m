% init sinkNames
sinkNames = cell();
if any(sinks == PLAYREC_SINK)
  sinkNames{end + 1} = getPlayrecDevName(playRecConfig.playDeviceID);
endif
if any(sinks == FILE_SINK)
  sinkNames{end + 1} = getBasename(sinkFile);
endif
