if sourceStruct.src == PLAYREC_SRC && ~structContains(sinkStruct, PLAYREC_SINK)
  % reading from playrec, but not writing, clearing the output buffer
  buffer = [];
endif  

if sourceStruct.src == PLAYREC_SRC || structContains(sinkStruct, PLAYREC_SINK)
  % reading and/or writing to soundcards
  buffer = readWritePlayrec(buffer, cycleLength, periodSize, fs, restartReading);
  % already waited
  hasWaited = true;
else
  % did not read from playrec, has no waited yet
  hasWaited = false;
endif
    
if sourceStruct.src == FILE_SRC
  [buffer, fs, sourceStruct] = readFileData(fs, sourceStruct, FILE_CHAN_LIST, cycleLength, ~hasWaited, restartReading);
endif

restartReading = false;
