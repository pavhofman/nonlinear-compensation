% init sinkNames
sinkStruct.names = cell();
if any(sinkStruct.sinks == PLAYREC_SINK)
  sinkStruct.names{end + 1} = getPlayrecDevName(playRecConfig.playDeviceID);
endif
if any(sinkStruct.sinks == MEMORY_SINK)
  sinkStruct.names{end + 1} = 'memory buffer';
endif
