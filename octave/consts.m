% CONSTANTS
% commands
PAUSE = 'pause';
CALIBRATE = 'cal';
COMPENSATE = 'comp';
PASS = 'pass';
DISTORT = 'distort';
AVG = 'avg';
FFT = 'fft';
NO_CMD = '';

% bits for statuses
PAUSED = 0;
PASSING = 1;
CALIBRATING = 2;
ANALYSING = 4;
COMPENSATING = 8;
DISTORTING = 16;


%directions
DIR_REC = 1;
DIR_PLAY = 2;

% direction cmd.info files
CMD_FILE_REC = 'cmd.info';
CMD_FILE_PLAY = 'cmd-play.info';
