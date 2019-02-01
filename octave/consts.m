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
global PAUSED = 1;
global PASSING = 2;
global CALIBRATING = 3;
global ANALYSING = 4;
global COMPENSATING = 5;
global DISTORTING = 6;
global GENERATING = 7;
global MEASURING = 8;
global SPLITTING = 9;


global STATUS_NAMES = cell();
STATUS_NAMES{PAUSED} = 'Paused';
STATUS_NAMES{PASSING} = 'Passing';
STATUS_NAMES{CALIBRATING} = 'Calibrating';
STATUS_NAMES{ANALYSING} = 'Analysing';
STATUS_NAMES{COMPENSATING} = 'Compensating';
STATUS_NAMES{DISTORTING} = 'Distorting';
STATUS_NAMES{GENERATING} = 'Generating';
STATUS_NAMES{MEASURING} = 'Measuring';
STATUS_NAMES{SPLITTING} = 'Splitting';


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
global genAmpl = db2mag(-3);