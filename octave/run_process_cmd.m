if (strcmp(cmd, PAUSE))
  status = PAUSED;
  
elseif (strcmp(cmd, CALIBRATE))    
  % start/restart calibration
  status = CALIBRATING;
  % clearing calibration buffer
  restartCal = true;

elseif (strcmp(cmd, COMPENSATE))
  % start/restart analysis
  status = ANALYSING;
  restartAnalysis = true;

% distortion allowed only for status PASSING and COMPENSATING
elseif (strcmp(cmd, DISTORT) && (bitand(status, PASSING) || bitand(status, COMPENSATING)))
  % enable distortion
  status = bitor(status, DISTORTING);

elseif (strcmp(cmd, PASS))
  status = PASSING;

endif
% clear new command
cmd = NO_CMD;