if ~isempty(recordedData)
  % writing existing data to known file
  filePath = sinkStruct.(MEMORY_SINK).file;
  audiowrite(filePath, recordedData, fs, 'BitsPerSample', 24);
  printf('Written %d samples to %s, closed\n', rows(recordedData), filePath);
  % stop recording
  source 'stop_recording.m';    
endif