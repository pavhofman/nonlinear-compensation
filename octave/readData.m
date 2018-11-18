function [buffer, fs] = readData(cnt, fs, restart)
  persistent allSamples = [];
  persistent readPtr = 1;
  
  
  global wavPath;
  global channel;
  
  if (restart)
    allSamples = [];
    readPtr = 1;
  endif

  if (isempty(allSamples))
    [allSamples, fs] = loadSamples(wavPath, channel);
  endif
  
  if (cnt == -1)
    % requested to determine count internally
    % 200ms
    cnt = fs * 0.2;
  endif
  

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
  
  % emulating samplerate timing
  bufferTime = length(buffer)/fs;
  delay = toc();
  if (delay > bufferTime)
    printf("XRUN: delay: %f, bufferTime %f\n", delay, bufferTime);
  else
    % sleep for the remaining time
    sleepTime = bufferTime - delay;
    printf("Sleeping for %f\n", sleepTime);
    pause(sleepTime);
  endif  
  tic();
endfunction

function [samples, fs] = loadSamples(wavPath, channel)
    [recorded, fs] = audioreadAndCut(wavPath, channel);
    limit = floor(length(recorded)/fs) * fs;
    samples = recorded(1:limit, :);
    tic();
endfunction

function writeData(buffer, fs)  
  % dropping data
endfunction
