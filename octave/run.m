#!/usr/bin/octave -qf
% clearing all variables
% note - 'clear' clears only local/global variables, not persistent variables in functions!
% we cannot call 'clear all' since it clears all funcions => also all breakpoints in funcions
clear;

addpath(fileparts(mfilename('fullpath')));

source 'config.m';

% commands
PAUSE = 'pause';
CALIBRATE = 'cal';
COMPENSATE = 'comp';
PASS = 'pass';
NO_CMD = '';

% bits for statuses
PAUSED = 0;
PASSING = 1;
CALIBRATING = 2;
ANALYSING = 4;
COMPENSATING = 8;


% default initial command
cmd = PAUSE;


% global variables in functions

global calRec = struct;
global periodLength = 0;
% end global vars

compHarmonics = [];
compenReference = [];
fs = 0;

% first run -> restart
restartReading = true;
restartCal = true;
restartAnalysis = true;

% at first we do not know how many samples to read. readData will determine
readCnt = -1;

while(true)
  % checking command file for new commands
  if (exist(cmdFile))
    cmd = textread(cmdFile, '%s');
    delete(cmdFile);
  endif;

  % process new command if any
  if (!strcmp(cmd, NO_CMD))
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
      
    elseif (strcmp(cmd, PASS) && status != PASSING)
      status = PASSING;
    endif
    % clear new command
    cmd = NO_CMD;
  endif

  printf('Status: %d\n', status);
  
  if (status == PAUSED)
    % no reading/writing
    pause(0.5);
    % next cycle
    continue;
  endif

  % not stopped, will need data
  [buffer, fs] = readData(readCnt, fs, restartReading);
  restartReading = false;
  readCnt = length(buffer);
  if (bitand(status, COMPENSATING))
    % compensation running
    if (length(buffer) == length(compenReference))
      buffer = buffer + compenReference;
    else
      printf("WARN: buffer length differes from compHarmonics: %d vs. %d", length(buffer), length(compHarmonics));
    endif
  endif
  % not stopped, always writing
  writeData(buffer);
  
  
  % do additional processing - calibration or analysis
  if (status == CALIBRATING)
    result = calibrate(buffer, fs, restartCal);
    restartCal = false;
    if (result == 1)
      % finished
      % request compensation
      cmd = COMPENSATE;
    endif 
  elseif (bitand(status, ANALYSING))
    [compenReference, result] = analyse(buffer, fs, restartAnalysis);
    restartAnalysis = false;
    if (result == 1)
      % finished
      % from now on only compensation
      status = COMPENSATING;
      % next buffer length must match compenReference - the two vectors are added!
      readCnt = length(compenReference);
      % or could start new analysis right away
      % status = COMPENSATING | ANALYSING;
    endif
  endif
  
  
endwhile
