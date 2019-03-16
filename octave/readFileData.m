function [buffer, fs] = readFileData(fs, sourceFile, chanList, cycleLength, doWait, restart)
  persistent allSamples = [];
  persistent readPtr = 1;
  
  if (restart)
    allSamples = [];
    readPtr = 1;
  endif

  if (isempty(allSamples))
    [allSamples, fs] = loadSamples(sourceFile, chanList);
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
  readPtr = newPtr + 1;
  
  if doWait
    % emulating samplerate timing
    waitRemainingTime(length(buffer)/fs);
  endif
endfunction

function [samples, fs] = loadSamples(sourceFile, chanList)
    [recorded, fs] = audioreadAndCut(sourceFile, chanList);
    limit = floor(length(recorded)/fs) * fs;
    samples = recorded(1:limit, :);
    tic();
endfunction

function waitRemainingTime(bufferTime)
  delay = toc();
  if (delay > bufferTime)
    printf("XRUN: delay: %f, bufferTime %f\n", delay, bufferTime);
  else
    % sleep for the remaining time
    sleepTime = bufferTime - delay;
    printf("Sleeping in readFileData for %f\n", sleepTime);
    pause(sleepTime);
  endif  
  tic();
endfunction
