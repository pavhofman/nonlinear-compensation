function [freqs, result] = calibrate(buffer, fs, restart)
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
    % unknown frequencies
    freqs = -1;
    result = 0;
  else
    % enough data, copying only up to calibrationSize data
    calBuffer = [calBuffer; buffer(1:calibrationSize - currentSize, :)];
    global wavPath;
    global channel;

    [freqs, result] = doCalibrate(calBuffer, fs);    
  endif
endfunction
  
function [ freqs, result] = doCalibrate(calBuffer, fs)
  peaks = getHarmonics(calBuffer, fs);
  printf('Calibration: Peaks:\n');
  disp(convertPeaksToPrintable(peaks));

  global wavPath;
  global channel;
  global calDir;
  calRec.time = time();
  calRec.direction = 'capture';
  calRec.device = wavPath;
  calRec.channel = channel;
  % first ten frequencies
  calRec.peaks = peaks(1:10, :, :);

  disp(calRec);
  % for now only single frequency
  freqs = peaks(1, 1, 1);

  calFile = genCalFilename(freqs, fs);
  save(calFile, 'calRec');
  result = 1;
endfunction