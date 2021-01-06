% init sinkNames
if structContains(sinkStruct, PLAYREC_SINK)
  sinkStruct.(PLAYREC_SINK).name = getPlayrecDevName(playRecConfig.playDeviceID);
end
if structContains(sinkStruct, MEMORY_SINK)
  sinkStruct.(MEMORY_SINK).name = 'Recording';
end
