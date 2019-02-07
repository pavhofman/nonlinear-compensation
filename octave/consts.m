pkg load control;

% CONSTANTS
% commands
global PAUSE = 'pause';
global CALIBRATE = 'cal';
global COMPENSATE = 'comp';
global PASS = 'pass';
global DISTORT = 'distort';
AVG = 'avg';
FFT = 'fft';
% sine generator
global GENERATE = 'gen';
% measure transfer at frequency and channel
global MEASURE = 'meas';
% splitting joint calibration to DAC and ADC components
global SPLIT = 'split';
global SPLIT2 = 'split2';
NO_CMD = '';

% statuses
global PAUSED = 'Paused';
global PASSING = 'Passing';
global CALIBRATING = 'Calibrating';
global ANALYSING = 'Analysing';
global COMPENSATING = 'Compensating';
global DISTORTING = 'Distorting';
global GENERATING = 'Generating';
global MEASURING = 'Measuring';
global SPLITTING = 'Splitting';


%directions
global DIR_REC = 1;
global DIR_PLAY = 2;

% results
global NOT_FINISHED_RESULT = 0;
global FINISHED_RESULT = 1;
% e.g. failed calibration
global FAILED_RESULT = 2;


% CMD prefices
% format: ID25
global CMD_ID_PREFIX = "ID";
% F3000
global CMD_FREQ_PREFIX = 'F';
%A0.8945
global CMD_AMPL_PREFIX = 'A';
%ECfilter
global CMD_EXTRA_CIRCUIT_PREFIX = 'EC';
%DNrec8
global CMD_DEVICE_NAME_PREFIX = 'DN';

% direction cmd.info files
global CMD_FILE_REC = 'cmd.info';
global CMD_FILE_PLAY = 'cmd-play.info';

% prefices for device names (used in calibration file names)
DEVICE_REC_PREFIX = 'rec';
DEVICE_PLAY_PREFIX = 'play';

ZEROMQ_PORT_REC = 5555;
ZEROMQ_PORT_PLAY = 5556;