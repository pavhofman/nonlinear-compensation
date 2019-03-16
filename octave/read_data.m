if sourceStruct.src == PLAYREC_SRC && ~any(sinks == PLAYREC_SINK)
  % reading from playrec, but not writing, clearing the output buffer
  buffer = [];
endif  

if sourceStruct.src == PLAYREC_SRC || any(sinks == PLAYREC_SINK)
  % reading and/or writing to soundcards
  [buffer, fs] = readWritePlayrec(-1, buffer, restartReading);  
endif
    
if sourceStruct.src == FILE_SRC
  [buffer, fs] = readFileData(-1, fs, sourceStruct.file, FILE_CHAN_LIST, restartReading);
endif

restartReading = false;
