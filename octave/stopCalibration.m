% clearing calibration freqs
calFreqs = [];
contCal = 0;
% turn off calibration
removeFromStatus(CALIBRATING);
% calibration command finished
cmdDoneID = cmdID;

if numfields(statusStruct) == 0
  cmd = {PASS};
endif
