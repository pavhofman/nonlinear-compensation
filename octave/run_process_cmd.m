if (strcmp(cmd{1}, PAUSE))
  setStatus(PAUSED);
  
elseif (strcmp(cmd{1}, CALIBRATE))
  % cal extraCircuit
  % start/restart joint-device calibration
  % add status - e.g. why compensation is running for incremental calibration
  addStatus(CALIBRATING);
  % reading optional  extra circuit specifier string (will be stored in cal file name)
  calExtraCircuit = findStringInCmd(cmd, CMD_EXTRA_CIRCUIT_PREFIX);
  
  % optional calibration freqs (both channels) to wait for
  calFreqs = findNumInCmd(cmd, CMD_FREQ_PREFIX);
  % calFreqs must be asc-sorted row
  if size(calFreqs, 1) > 1
    % in rows, transpose to columns
    calFreqs = transpose(calFreqs);
  endif
  if length(calFreqs) > 1
    calFreqs = sort(calFreqs);
  endif

  % clearing calibration buffer
  restartCal = true;
  showFFTFigureConfig.restartAvg = 1;

elseif (strcmp(cmd{1}, COMPENSATE))
  % comp calDeviceName extraCircuit  
  addStatus(COMPENSATING);
  removeFromStatus(PASSING);
  addStatus(ANALYSING);
  % reading optional deviceName string
  calDeviceName = findStringInCmd(cmd, CMD_DEVICE_NAME_PREFIX, jointDeviceName);
  % reading optional extraCircuit string
  compExtraCircuit = findStringInCmd(cmd, CMD_EXTRA_CIRCUIT_PREFIX);
  
  reloadCalFiles = true;
  showFFTFigureConfig.restartAvg = 1;

elseif strcmp(cmd{1}, DISTORT)
  if length(cmd) > 1 && strcmp(cmd{2}, 'off')
    % distortion off
    distortHarmLevels = [];
    distortPoly = [];
    removeFromStatus(DISTORTING);
  else
    distortHarmLevels = findLevelsInCmd(cmd, CMD_HARM_LEVELS_PREFIX, defaultValue = [-120, -120], defaultMsg = 'No distortion harmonic levels found in command, using 2nd@-120dB, 3rd@-120dB');
    distortPoly = genDistortPoly(distortHarmLevels);
    % enable distortion
    addStatus(DISTORTING);
  endif
  % distorting completes command immediately
  cmdDoneID = cmdID;

elseif (strcmp(cmd{1}, PASS))
  addStatus(PASSING);
  removeFromStatus(COMPENSATING);
  % keep analysis running all the time (without generating distortion peaks)
  addStatus(ANALYSING);
  calDeviceName = "";
  compExtraCircuit = "";

  showFFTFigureConfig.restartAvg = 1;
  % passing completes command immediately
  cmdDoneID = cmdID;
  % passing never fails
  setStatusResult(PASSING, RUNNING_OK_RESULT);

elseif strcmp(cmd{1}, AVG) && (rows(cmd) > 1)
  showFFTFigureConfig.numAvg = str2num(cmd{2});
  showFFTFigureConfig.restartAvg = 1;

elseif strcmp(cmd{1}, FFT) && (rows(cmd) > 1)
  showFFTFigureConfig.fftSize = str2num(cmd{2});
  showFFTFigureConfig.restartAvg = 1;

elseif strcmp(cmd{1}, GENERATE)
  if length(cmd) > 1 && strcmp(cmd{2}, 'off')
    % distortion off
    genFunds = [];
    removeFromStatus(GENERATING);
  else
    % gen freq
    % start generating sine at freq, at genAmpl level
    genFunds = findFundInCmd(cmd, CMD_CHANNEL_FUND_PREFIX, defaultValue = {[1000, db2mag(-3)]}, defaultMsg = 'No generator fundamentals found in command, using 1000Hz@-3dB');
    % zeroing time
    genStartingT = 0;
    
    addStatus(GENERATING);
    % keep analysis running all the time (without generating distortion peaks)
    addStatus(ANALYSING);
    showFFTFigureConfig.restartAvg = 1;
  endif
  % generating completes command immediately
  cmdDoneID = cmdID;
  
elseif strcmp(cmd{1}, MEASURE) && (rows(cmd) > 2)
  % meas freq channelID
  % measure transfer of channelID against the other channel at freq, store to transf.dat
  setStatus(MEASURING);
  transfer.freq = str2num(cmd{2});
  % channel ID for transfer measurement. The other channel receives the original signal
  transfer.channel = str2num(cmd{3});
  restartMeasuring = true;
    
elseif (strcmp(cmd{1}, SPLIT))
  % split joint-device calibration to DAC/ADC sides. Requires direct cal file, filter cal file at same freq, measured filter transfer file containing freq harmonics
  setStatus(SPLITTING);
  
endif
% clear new command
cmd = cellstr(NO_CMD);
