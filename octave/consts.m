% CONSTANTS
% commands
PAUSE = 'pause';
CALIBRATE = 'cal';
COMPENSATE = 'comp';
PASS = 'pass';
DISTORT = 'distort';
AVG = 'avg';
FFT = 'fft';
% sine generator
GENERATE = 'gen';
% measure transfer at frequency and channel
MEASURE = 'meas';
NO_CMD = '';

% bits for statuses
PAUSED = 0;
PASSING = 1;
CALIBRATING = 2;
ANALYSING = 3;
COMPENSATING = 4;
DISTORTING = 5;
GENERATING = 6;
MEASURING = 7;

%directions
DIR_REC = 1;
DIR_PLAY = 2;

% direction cmd.info files
CMD_FILE_REC = 'cmd.info';
CMD_FILE_PLAY = 'cmd-play.info';
