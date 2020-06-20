#!/usr/bin/octave -qf
% clearing all variables
% note - 'clear' clears only local/global variables, not persistent variables in functions!


more off;

pkg load miscellaneous;
pkg load optim;
pkg load zeromq;
pkg load database;

source 'run_common.m';

addpath(currDir);
statusDir = [currDir filesep() 'status'];
addpath(statusDir);
internalDir = [currDir filesep() 'internal'];
addpath(internalDir);

% contains samplerate config, loaded for both sides
source(sprintf('%s%sconfigRec.conf', confDir, filesep()));

global nonInteger;
if direction == DIR_PLAY
  % overriden playback config values
  source(sprintf('%s%sconfigPlay.conf', confDir, filesep()));
  cmdFile = getFilePath(CMD_FILE_PLAY, commDir);
  zeromqPort = ZEROMQ_PORT_PLAY;
else
  cmdFile = getFilePath(CMD_FILE_REC, commDir);
  zeromqPort = ZEROMQ_PORT_REC;
endif

source 'init_dev_ids.m';

if direction == DIR_PLAY
  % support for non-integer frequencies - by default off on playback side
  nonInteger = false;
else
  % support for non-integer frequencies on rec side - depends if the same device is used on playback side
  nonInteger = (playRecConfig.recDeviceID ~= playRecConfig.otherDeviceID);
endif

global fs;
fs = playRecConfig.sampleRate;

global maxAmplDiff;

if nonInteger
  cycleLength = CYCLE_LENGTH_NONINTEGER;
  periodSize = PERIOD_SIZE_NONINTEGER;
  maxAmplDiff = MAX_AMPL_DIFF_NONINTEGER;
  calBufferSize = NONINTEGER_MAX_FFT_FS_MULTIPLE * fs;
else
  cycleLength = CYCLE_LENGTH_INTEGER;
  periodSize = PERIOD_SIZE_INTEGER;
  maxAmplDiff = MAX_AMPL_DIFF_INTEGER;
  % integer Hz, i.e. FFT at INTEGER_FS_FFT_MULTIPLE*fs length
  calBufferSize = INTEGER_FS_FFT_MULTIPLE * fs;
endif

% default initial command - PASS


source 'init_sourcestruct.m';
source 'init_sinkstruct.m';


if sourceStruct.src == PLAYREC_SRC
  cmd = cellstr(PASS);
else
  cmd = cellstr(PAUSE);
endif

% command ID
cmdID = NA;
% ID of finished/done command
global cmdDoneID;
cmdDoneID = '';

global statusStruct;
statusStruct = struct();

global measuredPeaks;
measuredPeaks = NA;
global fundLevels;
fundLevels = NA;
global distortPeaks;
distortPeaks = NA;

global genFunds;
genFunds = NA;
global distortHarmAmpls;
distortHarmAmpls = [];

channelCnt = NA;
global compenCalFiles;
compenCalFiles = NA;

calBuffer = [];

global calRequest;
calRequest = NA;
global compRequest;
compRequest = NA;

% row of equalizer coeffs for each channel - initialized at first run when channel count is known
global equalizer;
equalizer = NA;

% count of clipped samples in one cycle
global clippedCnt;
clippedCnt = 0;

recordedData = [];

global reloadCalFiles;
reloadCalFiles = false;
restartAnalysis = false;

% first run -> restart, reading all files
source 'restart_chain.m';

startingTs = NA;
buffer = [0];

source 'set_caldev_names.m';

firstCycle = true;

while(true)
  % resetting clipped counter
  clippedCnt = 0;
  
  % checking command file for new commands
  if (exist(cmdFile, 'file'))
    lines = textscan(fopen(cmdFile), '%s');
    lines = lines{1};
    % first line could be command ID if starts with ID
    cmdID = findNumInCmd(lines, CMD_ID_PREFIX, defaultValue = NA);
    if isna(cmdID)
      % no command id
      cmd = lines;
    else
      cmd = lines(2:end);
    endif
    deleteFile(cmdFile);
  endif;

  % process new command if any
  if (!strcmp(cmd, NO_CMD))
    source 'run_process_cmd.m';  
  endif

%  printf('Status: \n');
%  disp(status);
  drawnow();

  if (isStatus(PAUSED))
    % no reading/writing
    pause(0.5);
    writeLog('DEBUG', 'Paused');
    % next cycle
    continue;
  endif

  % not stopped, will need data
  source 'read_data.m';

  % we already know channel count, initialize compenCalFiles
  if firstCycle
    channelCnt = columns(buffer);
    compenCalFiles = cell(channelCnt, 1);
    prevMeasuredPeaks = cell(channelCnt, 1);
    firstCycle = false;

    % ones
    equalizer = ones(1, channelCnt);
  endif

  if (statusContains(GENERATING))
    source 'run_generator.m';
  endif
  

  source 'pre_process_stream.m';
 

  if (statusContains(ANALYSING))
    %id = tic();
    source 'run_analysis.m';
    %printf('Analysis took %f\n', toc(id));
  endif

  % calibration - updating calBuffer in every cycle
  source 'run_calibration.m';

    if (statusContains(COMPENSATING))
    %id = tic();
    source 'run_compensation.m';
    %printf('Compensation took %f\n', toc(id));
  else
    % for all other statuses - clear compenCalFiles
    compenCalFiles = cell(columns(buffer), 1);
  endif

  if statusContains(DISTORTING)
    source 'run_distortion.m';
  endif
  
  
  source 'post_process_stream.m';

  % recording to memory if enabled
  if structContains(sinkStruct, MEMORY_SINK)
    source 'record_data.m';
  endif
    
  if showFFTCfg.enabled
    % should show FFT figure for this direction
    showFFTFigure(buffer, fs, direction)
  endif

  if useZeroMQ
    sendInfo(buildInfo(channelCnt, statusStruct, measuredPeaks, distortPeaks, fs, direction, cmdDoneID, compenCalFiles, reloadCalFiles,
      sourceStruct, sinkStruct, showFFTCfg, chMode, equalizer, nonInteger, playCalDevName, recCalDevName), zeromqPort);
  endif
endwhile
