function [buffer, fs, sourceStruct] = readFileData(fs, sourceStruct, chanList, cycleLength, doWait, restart)
  persistent allSamples = [];
  persistent readPtr = 1;
  
  if (restart)
    allSamples = [];
    readPtr = 1;
  endif

  if (isempty(allSamples))
    [allSamples, fs] = audioreadAndCut(sourceStruct.file, chanList);
    % in secs
    sourceStruct.fileLength = rows(allSamples)/fs;
    % only start timing when waiting required
    if doWait
      tic();
    endif
  endif
  
  cnt = fs * cycleLength;

  newPtr = readPtr + cnt - 1;
  if (newPtr <= length(allSamples))
    % no repetition
    buffer = allSamples(readPtr:newPtr, :);
  else
    % works only for cnt < length(allSamples)!
    % crossing boundary, repetition
    newPtr -= length(allSamples);
    buffer = [allSamples(readPtr:end, :); allSamples(1:newPtr, :)];
  endif
  sourceStruct.filePos = newPtr/fs;
  readPtr = newPtr + 1;
  
  if doWait
    % emulating samplerate timing
    waitRemainingTime(length(buffer)/fs);
  endif
endfunction

function waitRemainingTime(bufferTime)
  delay = toc();
  if (delay > bufferTime)
    writeLog('WARN', "XRUN: delay: %f, bufferTime %f", delay, bufferTime);
  else
    % sleep for the remaining time
    sleepTime = bufferTime - delay;
    writeLog('DEBUG', "Sleeping in readFileData for %f", sleepTime);
    pause(sleepTime);
  endif  
  tic();
endfunction
