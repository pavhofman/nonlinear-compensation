function result = calibrate(buffer, fs, deviceName, extraCircuit, restart)
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
    % each channel stored separately
    for channelID = 1:size(fundPeaks, 3)
      fundPeaksCh = fundPeaks(:, :, channelID);    
      if hasAnyPeak(fundPeaksCh)
        saveCalFile(fundPeaksCh, distortPeaks(:, :, channelID), fs, channelID, deviceName, extraCircuit);
      else
        printf('No fundaments found for channel ID %d, not storing its calibration file\n', channelID);
      endif
    endfor
    global FINISHED_RESULT;
    result = FINISHED_RESULT;    
  endif
endfunction