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

source 'config.m';

if direction == DIR_PLAY
  % overriden playback config values
  source 'configPlay.m';
  cmdFile = genDataPath(CMD_FILE_PLAY);
else
  cmdFile = genDataPath(CMD_FILE_REC);
endif

transferFile = genDataPath('transf.dat');
% default initial command - PASS
cmd = cellstr(PASS);

% command ID
cmdID = '';
% ID of finished/done command
global cmdDoneID = '';

global statusStruct = struct()
setStatus(PASSING);
global measuredPeaks = NA;
global fundLevels = NA;
global distortPeaks = NA;

global genFunds = NA;
global distortHarmLevels = [];

global fs = NA;

global compenCalFiles = NA;
global calFreqs = NA;

transfer = struct();


% first run -> restart, reading all files
restartReading = true;
restartCal = true;
global reloadCalFiles = false;
restartWriting = true;
restartMeasuring = true;

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
    % next cycle
    continue;
  endif

  % not stopped, will need data
  if exist('wavPath', 'var') && !isempty(wavPath)
    [buffer, fs] = readData(-1, fs, restartReading);
  else
    % reading/writing to soundcards
    [buffer, fs] = readWritePlayrec(-1, buffer, restartReading);
  end
  restartReading = false;
  
  % we already know channel count, initialize compenCalFiles
  if firstCycle
    compenCalFiles = cell(columns(buffer), 1);
    firstCycle = false;
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
  
  if (statusContains(CALIBRATING))
    source 'run_calibration.m';
  endif

  
  if (statusContains(COMPENSATING))
    %id = tic();
    source 'run_compensation.m';
    %printf('Compensation took %f\n', toc(id));
  else
    % for all other statuses - clear compenCalFiles
    compenCalFiles = cell(columns(buffer), 1);
  endif

  % not stopped, always writing
  writeData(buffer, fs, restartWriting);
  restartWriting = false;
  
  if (isStatus(MEASURING))
    source 'run_measuring.m';
  endif
  
  if (isStatus(SPLITTING))
    source 'run_splitting.m';
  endif

  sendInfo(buildInfo(), zeromqPort);
endwhile
