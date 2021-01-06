if (strcmp(cmd{1}, PAUSE))
  setStatus(PAUSED);
  
elseif (strcmp(cmd{1}, SET_MODE))
  % default = MODE_DUAL
  chMode = findNumInCmd(cmd, CMD_MODE_PREFIX, MODE_DUAL);
  writeLog('INFO', 'Switched to mode %d', chMode);

  % calfiles are specific for each mode - reloading at change
  reloadCalFiles = true;

  % setting mode completes command immediately
  cmdDoneID = cmdID;
  
elseif (strcmp(cmd{1}, CALIBRATE))
    if length(cmd) > 1 && strcmp(cmd{2}, 'off')
    % calibration off
    source 'stop_calibration.m';
  else
    % cal extraCircuit
    % start/restart joint-device calibration
    % add status - e.g. why compensation is running for incremental calibration
    addStatus(CALIBRATING);
    
    % optional continuous calibration, false = default
    contCal = findNumInCmd(cmd, CMD_CONT_PREFIX, false);
    
    % reading optional  extra circuit specifier string (will be stored in cal file name)
    calExtraCircuit = findStringInCmd(cmd, CMD_EXTRA_CIRCUIT_PREFIX);
    
    % optional calibration freqs + levels for both channels to wait for
    calFreqReq = findMatricesInCmd(cmd, CMD_CALFREQS_PREFIX);
    if ~isempty(calFreqReq)
      % filling calFreqReq for each channel by copying last channel values up to channelCnt - must be columns!
      calFreqReq(end + 1: channelCnt) = calFreqReq{end};
    end
    
    % default = PLAY_CH_ID
    playChannelID = findNumInCmd(cmd, CMD_CHANNEL_ID_PREFIX, PLAY_CH_ID);
    
    % default = COMP_TYPE_JOINT
    compType = findNumInCmd(cmd, CMD_COMP_TYPE_PREFIX, COMP_TYPE_JOINT);
    
    % optional number of averating calibration runs, 10 = default
    calRuns = findNumInCmd(cmd, CMD_CALRUNS_PREFIX, CAL_RUNS);
    
    % joint compType should pass current playback amplitudes for storing into the calfile
    playAmpls = findMatricesInCmd(cmd, CMD_PLAY_AMPLS_PREFIX, cell(channelCnt));

        
    % building calibration request struct
    calRequest = initCalRequest(calFreqReq, compType, playChannelID, playAmpls, calExtraCircuit, contCal, calRuns);

    % clearing calibration buffer
    restartCal = true;
    showFFTCfg.restartAvg = 1;
  end

elseif (strcmp(cmd{1}, COMPENSATE))
  % comp calDeviceName extraCircuit  
  addStatus(COMPENSATING);
  removeFromStatus(PASSING);
  addStatus(ANALYSING);

  % reading optional extraCircuit string
  compExtraCircuit = findStringInCmd(cmd, CMD_EXTRA_CIRCUIT_PREFIX);
  % default = COMP_TYPE_JOINT
  compType = findNumInCmd(cmd, CMD_COMP_TYPE_PREFIX, COMP_TYPE_JOINT);
  compRequest = initCompRequest(compType, PLAY_CH_ID, compExtraCircuit);
  
  reloadCalFiles = true;
  showFFTCfg.restartAvg = 1;

  % compensating completes command immediately
  % TODO - really?
  cmdDoneID = cmdID;
  

elseif strcmp(cmd{1}, DISTORT)
  if length(cmd) > 1 && strcmp(cmd{2}, 'off')
    % distortion off
    distortHarmAmpls = [];
    removeFromStatus(DISTORTING);
  else
    distortHarmAmpls = findAmplsInCmd(cmd, CMD_AMPLS_PREFIX, defaultValue = [1e-06, 1e-06], defaultMsg = 'No distortion harmonic levels found in command, using 2nd@-120dB, 3rd@-120dB');
    % enable distortion
    addStatus(DISTORTING);
  end
  % distorting completes command immediately
  cmdDoneID = cmdID;

elseif (strcmp(cmd{1}, PASS))
  addStatus(PASSING);
  removeFromStatus(COMPENSATING);
  % keep analysis running all the time (without generating distortion peaks)
  addStatus(ANALYSING);
  compRequest = NA;

  showFFTCfg.restartAvg = 1;
  % passing completes command immediately
  cmdDoneID = cmdID;
  % passing never fails
  setStatusResult(PASSING, RUNNING_OK_RESULT);

elseif (strcmp(cmd{1}, READFILE))
  if length(cmd) > 1 && strcmp(cmd{2}, 'off')
    % reading file off
    source 'stop_reading_file.m';
  else
    % READFILE filename
    % start/restart reading samples from filename    
    sourceStruct.file = findStringInCmd(cmd, CMD_FILEPATH_PREFIX, NA, 'No source audio file found in READFILE command, ignoring');
    if ~isempty(sourceStruct.file)
      % start reading file inputFile
      source 'start_reading_file.m';
    end
  end
  % processing READFILE completes the command immediately
  cmdDoneID = cmdID;

elseif (strcmp(cmd{1}, RECORD))
  if length(cmd) > 1 && strcmp(cmd{2}, 'off')
    % writing file off
    source 'stop_recording.m';
  else
    % start/restart recodring samples to memory
    source 'start_recording.m';
  end
  % processing WRITEFILE completes the command immediately
  cmdDoneID = cmdID;

elseif (strcmp(cmd{1}, STORE_RECORDED))
  % STORE_RECORDED filename
  % write recorded samples to filename
  sinkStruct = addFieldToStruct(sinkStruct, MEMORY_SINK);
  sinkStruct.(MEMORY_SINK).file = findStringInCmd(cmd, CMD_FILEPATH_PREFIX, NA, 'No sink audio file found in command STORE_RECORDED');
  if ~isempty(sinkStruct.(MEMORY_SINK).file)
    source 'store_recorded_data.m';
  end
  % processing WRITEFILE completes the command immediately
  cmdDoneID = cmdID;
  
elseif strcmp(cmd{1}, SHOW_FFT)
  if length(cmd) > 1 && strcmp(cmd{2}, 'off')
    % disable showing fftoff
    closeFFTFigure();
  else
    showFFTCfg.enabled = true;
    showFFTCfg.numAvg = findNumInCmd(cmd, CMD_FFTAVG_PREFIX, 0);
    showFFTCfg.fftSize = findNumInCmd(cmd, CMD_FFTSIZE_PREFIX, 2^16);
    showFFTCfg.restartAvg = 1;    
  end
  % processing SHOWFFT completes the command immediately
  cmdDoneID = cmdID;

elseif strcmp(cmd{1}, GENERATE)
  if length(cmd) > 1 && strcmp(cmd{2}, 'off')
    % distortion off
    genFunds = [];
    removeFromStatus(GENERATING);
  else
    % gen freq
    % start generating sine at freq, at genAmpl level
    genFunds = findMatricesInCmd(cmd, CMD_CHANNEL_FUND_PREFIX, defaultValue = {[1000, db2mag(-3)]}, defaultMsg = 'No generator fundamentals found in command, using 1000Hz@-3dB');
    % zeroing time
    genStartingT = 0;
    
    addStatus(GENERATING);
    % keep analysis running all the time (without generating distortion peaks)
    addStatus(ANALYSING);
    showFFTCfg.restartAvg = 1;
  end
  % generating completes command immediately
  cmdDoneID = cmdID;

end
% clear new command
cmd = cellstr(NO_CMD);
