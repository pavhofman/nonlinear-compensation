#!/usr/bin/octave -qf
% clearing all variables
% note - 'clear' clears only local/global variables, not persistent variables in functions!
% we cannot call 'clear all' since it clears all funcions => also all breakpoints in funcions
clear;

more off;

pkg load miscellaneous;
pkg load control;
pkg load optim;

addpath(fileparts(mfilename('fullpath')));

source 'config.m';

% commands
PAUSE = 'pause';
CALIBRATE = 'cal';
COMPENSATE = 'comp';
PASS = 'pass';
DISTORT = 'distort';
AVG = 'avg';
NO_CMD = '';

% bits for statuses
PAUSED = 0;
PASSING = 1;
CALIBRATING = 2;
ANALYSING = 4;
COMPENSATING = 8;
DISTORTING = 16;


% default initial command
cmd = PAUSE;

fs = 0;

% first run -> restart, reading all files
restartReading = true;
restartCal = true;
restartAnalysis = true;
restartWriting = true;
% unknown frequencies - measured by calibration or by determineFundamentalFreqs() in analysis
freqs = -1;

startingT = 0;

global deviceName;
if exist('wavPath', 'var') && !isempty(wavPath)
    [wavDir, wavName, wavExt] = fileparts(wavPath);
    deviceName = [wavName wavExt];
else
    global playRecConfig;
    deviceName = sprintf('rec%d', playRecConfig.recDeviceID);
end

while(true)
  % checking command file for new commands
  if (exist(cmdFile, 'file'))
    cmd = textread(cmdFile, '%s');
    delete(cmdFile);
  endif;

  % process new command if any
  if (!strcmp(cmd, NO_CMD))
    source 'run_process_cmd.m';  
  endif

%  printf('Status: %d\n', status);
  drawnow();

  if (status == PAUSED)
    % no reading/writing
    pause(0.5);
    % next cycle
    continue;
  endif

  % not stopped, will need data
  if exist('wavPath', 'var') && !isempty(wavPath)
    [buffer, fs] = readData(-1, fs, restartReading);
  else
    [buffer, fs] = readDataPlayrec(-1, restartReading);
  end
  restartReading = false;

  if (bitand(status, DISTORTING) && (bitand(status, PASSING) || bitand(status, COMPENSATING)))
    source 'run_distortion.m';
  endif
  
  if (bitand(status, COMPENSATING))
    source 'run_compensation.m';
  endif
  
  % not stopped, always writing
  writeData(buffer, fs, restartWriting);
  restartWriting = false;
  
  
  % do additional processing - calibration or analysis
  if (status == CALIBRATING)
    source 'run_calibration.m';    
  elseif (bitand(status, ANALYSING))
    source 'run_analysis.m';
  endif
  
  
endwhile
