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
  setStatus(COMPENSATING);
  addStatus(ANALYSING);
  % reading optional deviceName string
  calDeviceName = findStringInCmd(cmd, CMD_DEVICE_NAME_PREFIX, jointDeviceName);
  % reading optional extraCircuit string
  compExtraCircuit = findStringInCmd(cmd, CMD_EXTRA_CIRCUIT_PREFIX);
  
  reloadCalFiles = true;
  showFFTFigureConfig.restartAvg = 1;

% distortion allowed only for status PASSING and COMPENSATING
elseif (strcmp(cmd{1}, DISTORT) && (statusContains(PASSING) || statusContains(COMPENSATING)))
  % enable distortion
  addStatus(DISTORTING);

elseif (strcmp(cmd{1}, PASS))
  setStatus(PASSING);
  % keep analysis running all the time (without generating distortion peaks)
  addStatus(ANALYSING);
  calDeviceName = "";
  compExtraCircuit = "";

  showFFTFigureConfig.restartAvg = 1;
  % passing completes command immediately
  cmdDoneID = cmdID;

elseif strcmp(cmd{1}, AVG) && (rows(cmd) > 1)
  showFFTFigureConfig.numAvg = str2num(cmd{2});
  showFFTFigureConfig.restartAvg = 1;

elseif strcmp(cmd{1}, FFT) && (rows(cmd) > 1)
  showFFTFigureConfig.fftSize = str2num(cmd{2});
  showFFTFigureConfig.restartAvg = 1;

elseif strcmp(cmd{1}, GENERATE) && (rows(cmd) > 1)
  % gen freq
  % start generating sine at freq, at genAmpl level
  genFreq = findNumInCmd(cmd, CMD_FREQ_PREFIX, 1000, 'No generator frequency found in command, using 1000Hz');
  genAmpl = findNumInCmd(cmd, CMD_AMPL_PREFIX, db2mag(-3), 'No generator amplitude found in command, using -3dB');
  setStatus(GENERATING);
  % zeroing time
  startingT = 0;
  showFFTFigureConfig.restartAvg = 1;
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
