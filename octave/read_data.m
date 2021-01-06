if sourceStruct.src == PLAYREC_SRC && ~structContains(sinkStruct, PLAYREC_SINK)
  % reading from playrec, but not writing, clearing the output buffer
  buffer = [];
end

if sourceStruct.src == PLAYREC_SRC || structContains(sinkStruct, PLAYREC_SINK)
  % reading and/or writing to soundcards
  buffer = readWritePlayrec(buffer, cycleLength, periodSize, fs, restartReading);
  % already waited
  hasWaitedInPlayrec = true;
else
  % did not read from playrec, has not waited yet
  hasWaitedInPlayrec = false;
end
    
if sourceStruct.src == FILE_SRC
  [buffer, fs, sourceStruct] = readFileData(fs, sourceStruct, FILE_CHAN_LIST, cycleLength, ~hasWaitedInPlayrec, restartReading);
end

restartReading = false;
