#!/usr/bin/octave -qf
% clearing all variables
% note - 'clear' clears only local/global variables, not persistent variables in functions!


more off;

pkg load miscellaneous;
pkg load optim;

addpath(fileparts(mfilename('fullpath')));

source 'config.m';

if !exist(dataDir, 'dir')
  mkdir(dataDir);
endif


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
status = PASSING;

fs = 0;
genFreq = 0;

transfer = struct();


% first run -> restart, reading all files
restartReading = true;
restartCal = true;
restartAnalysis = true;
restartWriting = true;
restartMeasuring = true;
% unknown frequencies - measured by calibration or by determineFundamentalFreqs() in analysis
freqs = -1;

startingT = 0;
buffer = [0];

source 'run_device_names.m';

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

%  printf('Status: \n');
%  disp(status);
  drawnow();

  if (statusIs(status, PAUSED))
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

  if (statusContains(status, DISTORTING) && (statusContains(status, PASSING) || statusContains(status, COMPENSATING)))
    source 'run_distortion.m';
  endif
  
  if (statusContains(status, COMPENSATING))
    source 'run_compensation.m';
  endif
  
  if (statusIs(status, GENERATING))
    source 'run_generator.m';
  endif
  
  % not stopped, always writing
  writeData(buffer, fs, restartWriting);
  restartWriting = false;
  
  
  % do additional read-only processing on samples
  if (statusContains(status, CALIBRATING))
    source 'run_calibration.m';
  endif
  
  if (status == MEASURING)
    source 'run_measuring.m';
  endif

  if (statusContains(status, ANALYSING))
    source 'run_analysis.m';
  endif
  
  if (status == SPLITTING)
    source 'run_splitting.m';
  endif

endwhile
