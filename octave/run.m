#!/usr/bin/octave -qf
% clearing all variables
% note - 'clear' clears only local/global variables, not persistent variables in functions!
% we cannot call 'clear all' since it clears all funcions => also all breakpoints in funcions
clear;

pkg load miscellaneous;
pkg load control;


addpath(fileparts(mfilename('fullpath')));

source 'config.m';

% commands
PAUSE = 'pause';
CALIBRATE = 'cal';
COMPENSATE = 'comp';
PASS = 'pass';
DISTORT = 'distort';
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



compHarmonics = [];
compenReference = [];
compenPos = 1;
fs = 0;

% first run -> restart
restartReading = true;
restartCal = true;
restartAnalysis = true;
restartWriting = true;

% at first we do not know how many samples to read. readData will determine
readCnt = -1;

while(true)
  % checking command file for new commands
  if (exist(cmdFile, 'file'))
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
    
    % distortion allowed only for status PASSING and COMPENSATING
    elseif (strcmp(cmd, DISTORT) && (bitand(status, PASSING) || bitand(status, COMPENSATING)))
      % enable distortion
      status = bitor(status, DISTORTING);

    elseif (strcmp(cmd, PASS))
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
  
  if (bitand(status, DISTORTING))
    % introduce distortion to buffer
    buffer = polyval(distortPolynom, buffer);
  endif
  
  if (bitand(status, COMPENSATING))
    % compensation running
    bufLen = length(buffer) + 1;
    compenLen = length(compenReference) + 1;
    bufPos = 1;
    while bufPos < bufLen
        bufRem = bufLen - bufPos;
        compenRem = compenLen - compenPos;
        step = min(bufRem, compenRem);
        buffer(bufPos:bufPos+step-1) += compenReference(compenPos:compenPos+step-1);
        bufPos += step;
        compenPos += step;
        if step == compenRem
            compenPos = 1;
        end
    endwhile
  endif
  % not stopped, always writing
  writeData(buffer, fs, restartWriting);
  restartWriting = false;
  
  
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
    compenPos = 1;
    restartAnalysis = false;
    if (result == 1)
      % finished
      % from now on only compensation
      status = COMPENSATING;
      % or could start new analysis right away
      % status = bitor(COMPENSATING, ANALYSING);
    endif
  endif
  
  
endwhile
