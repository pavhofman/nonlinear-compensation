function [freqs, result] = calibrate(buffer, fs, deviceName, extraCircuit, freqs, restart)
  persistent calBuffer = [];  
  calibrationSize = fs; % 1 second
  
  if (restart)
    calBuffer = [];
  endif
  
  currentSize = length(calBuffer);
  if (currentSize + length(buffer) < calibrationSize)
    % not enough data, copying whole buffer
    calBuffer = [calBuffer; buffer];
    % not finished
    global NOT_FINISHED_RESULT;
    result = NOT_FINISHED_RESULT;
  else
    % enough data, copying only up to calibrationSize data
    calBuffer = [calBuffer; buffer(1:calibrationSize - currentSize, :)];
    [fundPeaks, distortPeaks] = getHarmonics(calBuffer, fs);

    % storing joint directions cal file
    [freqs, result] = saveCalFile(fundPeaks, distortPeaks, fs, deviceName, extraCircuit);
  endif
endfunction