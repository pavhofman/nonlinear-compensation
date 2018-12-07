if (strcmp(cmd, PAUSE))
  status = PAUSED;
  
elseif (strcmp(cmd, CALIBRATE))    
  % start/restart calibration
  status = CALIBRATING;
  % clearing calibration buffer
  restartCal = true;
  showFFTFigureConfig.restartAvg = 1;

elseif (strcmp(cmd, COMPENSATE))
  % start/restart analysis first, compensation will run after measuring current stream parameters
  status = ANALYSING;
  restartAnalysis = true;
  % re-determine freqs in case of change
  freqs = -1;
  showFFTFigureConfig.restartAvg = 1;

% distortion allowed only for status PASSING and COMPENSATING
elseif (strcmp(cmd, DISTORT) && (bitand(status, PASSING) || bitand(status, COMPENSATING)))
  % enable distortion
  status = bitor(status, DISTORTING);

elseif (strcmp(cmd, PASS))
  status = PASSING;
  showFFTFigureConfig.restartAvg = 1;

elseif strcmp(cmd{1}, AVG) && (rows(cmd) > 1)
  showFFTFigureConfig.numAvg = str2num(cmd{2});
  showFFTFigureConfig.restartAvg = 1;

elseif strcmp(cmd{1}, FFT) && (rows(cmd) > 1)
  showFFTFigureConfig.fftSize = str2num(cmd{2});
  showFFTFigureConfig.restartAvg = 1;

elseif strcmp(cmd{1}, GENERATE) && (rows(cmd) > 1)
  status = GENERATING;
  genFreq = str2num(cmd{2});
  % zeroing time
  startingT = 0;
  showFFTFigureConfig.restartAvg = 1;
endif
% clear new command
cmd = NO_CMD;
