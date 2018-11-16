function result = calibrate(buffer, fs, restart)
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
    result = 0;
  else
    % enough data, copying only up to calibrationSize data
    calBuffer = [calBuffer; buffer(1:calibrationSize - currentSize, :)];
    global wavPath;
    global channel;

    result = doCalibrate(calBuffer, fs);    
  endif
endfunction
  
function result = doCalibrate(calBuffer, fs)
  peaks = getHarmonics(calBuffer, fs);
  printf('Calibration: Peaks:\n');
  disp(convertPeaksToPrintable(peaks));

  global wavPath;
  global channel;
  global calFile;
  calRec.time = time();
  calRec.direction = 'capture';
  calRec.device = wavPath;
  calRec.channel = channel;
  % first ten frequencies
  calRec.peaks = peaks(1:10, :, :);

  disp(calRec);
  save(calFile, 'calRec');
  result = 1;
endfunction