if ~isempty(recordedData)
  % writing existing data to known file
  filePath = sinkStruct.(MEMORY_SINK).file;
  audiowrite(filePath, recordedData, fs, 'BitsPerSample', 24);
  writeLog('INFO', 'Written %d samples to %s, closed', rows(recordedData), filePath);
  % stop recording
  source 'stop_recording.m';    
endif