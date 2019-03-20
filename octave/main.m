#!/usr/bin/octave -qf
% clearing all variables
% note - 'clear' clears only local/global variables, not persistent variables in functions!


more off;

pkg load miscellaneous;
pkg load optim;
pkg load zeromq;
pkg load database;

currDir = fileparts(mfilename('fullpath'));
addpath(currDir);
statusDir = [currDir filesep() 'status'];
addpath(statusDir);
statusDir = [currDir filesep() 'status'];
addpath(statusDir);
internalDir = [currDir filesep() 'internal'];
addpath(internalDir);

source 'config.m';

if direction == DIR_PLAY
  % overriden playback config values
  source 'configPlay.m';
  cmdFile = genDataPath(CMD_FILE_PLAY);
  zeromqPort = ZEROMQ_PORT_PLAY;
else
  cmdFile = genDataPath(CMD_FILE_REC);
  zeromqPort = ZEROMQ_PORT_REC;
endif

transferFile = genDataPath('transf.dat');
% default initial command - PASS


source 'init_sourcestruct.m';
source 'init_sinkstruct.m';


if sourceStruct.src == PLAYREC_SRC
  cmd = cellstr(PASS);
else
  cmd = cellstr(PAUSE);
endif

% command ID
cmdID = '';
% ID of finished/done command
global cmdDoneID = '';

global statusStruct = struct()

global measuredPeaks = NA;
global fundLevels = NA;
global distortPeaks = NA;

global genFunds = NA;
global distortHarmLevels = [];

global fs = NA;

channelCnt = NA;
global compenCalFiles = NA;

global calFreqs = NA;
prevFundPeaks = NA;
calBuffer = [];
calibrationSize = NA;
% continuous calibration. Default - false
contCal = false;

recordedData = [];

transfer = struct();

global reloadCalFiles = false;
% first run -> restart, reading all files
source 'restart_chain.m';

startingT = 0;
buffer = [0];

source 'run_common.m';

firstCycle = true;

while(true)
  % checking command file for new commands
  if (exist(cmdFile, 'file'))    
    lines = textread(cmdFile, '%s');
    % first line could be command ID if starts with ID
    if length(lines) > 1 && strncmp(lines{1}, CMD_ID_PREFIX, length(CMD_ID_PREFIX))
      cmdID = lines{1};
      cmd = lines(2:end);
    else
      % no cmd ID as first item
      cmd = lines;
    endif
    delete(cmdFile);
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
    printf('Paused\n');
    % next cycle
    continue;
  endif

  % not stopped, will need data
  source 'read_data.m';

  % we already know channel count, initialize compenCalFiles
  if firstCycle
    channelCnt = columns(buffer);
    compenCalFiles = cell(channelCnt, 1);
    prevFundPeaks = cell(channelCnt, 1);
    firstCycle = false;
    calibrationSize = fs; % 1 second, resolution 1Hz
  endif

  if (statusContains(GENERATING))
    source 'run_generator.m';
  endif
 

  if (statusContains(ANALYSING))
    %id = tic();
    source 'run_analysis.m';
    %printf('Analysis took %f\n', toc(id));
  endif

  if statusContains(DISTORTING)
    source 'run_distortion.m';
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
  
  % recording to memory if enabled
  if structContains(sinkStruct, MEMORY_SINK)
    source 'record_data.m';
  endif
    
  if showFFTCfg.enabled
    % should show FFT figure for this direction
    showFFTFigure(buffer, fs, direction)
  endif
  
  if (isStatus(MEASURING))
    source 'run_measuring.m';
  endif
  
  if (isStatus(SPLITTING))
    source 'run_splitting.m';
  endif

  if useZeroMQ
    sendInfo(buildInfo(), zeromqPort);
  endif
endwhile
