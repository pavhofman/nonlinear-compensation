if ~isempty(recordedData)
  % writing existing data to known file
  audiowrite(sinkStruct.file, recordedData, fs, 'BitsPerSample', 24);
  printf('Written %d samples to %s, closed\n', rows(recordedData), sinkStruct.file);
  % stop recording
  source 'stop_recording.m';    
endif