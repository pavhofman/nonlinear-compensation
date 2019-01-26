pkg load control;

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
% splitting joint calibration to DAC and ADC components
SPLIT = 'split';
SPLIT2 = 'split2';
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
SPLITTING = 8;

%directions
DIR_REC = 1;
DIR_PLAY = 2;

% results
global NOT_FINISHED_RESULT = 0;
global FINISHED_RESULT = 1;


% direction cmd.info files
global CMD_FILE_REC = 'cmd.info';
global CMD_FILE_PLAY = 'cmd-play.info';

% prefices for device names (used in calibration file names)
DEVICE_REC_PREFIX = 'rec';
DEVICE_PLAY_PREFIX = 'play';

ZEROMQ_PORT_REC = 5555;
ZEROMQ_PORT_PLAY = 5556;

% fixed generator amplitude for now - used when generating sine (genSine) and calculating split calibration (run_split)
genAmpl = db2mag(-3);