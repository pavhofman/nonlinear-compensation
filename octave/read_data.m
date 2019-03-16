if sourceStruct.src == PLAYREC_SRC && ~any(sinks == PLAYREC_SINK)
  % reading from playrec, but not writing, clearing the output buffer
  buffer = [];
endif  

if sourceStruct.src == PLAYREC_SRC || any(sinks == PLAYREC_SINK)
  % reading and/or writing to soundcards
  [buffer, fs] = readWritePlayrec(buffer, CYCLE_LENGTH, restartReading);
  % already waited
  hasWaited = true;
else
  % did not read from playrec, has no waited yet
  hasWaited = false;
endif
    
if sourceStruct.src == FILE_SRC
  [buffer, fs] = readFileData(fs, sourceStruct.file, FILE_CHAN_LIST, CYCLE_LENGTH, ~hasWaited, restartReading);
endif

restartReading = false;
