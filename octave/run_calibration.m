result = calibrate(buffer, fs, restartCal);
restartCal = false;
if (result == 1)
  % finished
  % request compensation
  cmd = COMPENSATE;
endif
