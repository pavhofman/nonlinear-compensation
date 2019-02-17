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

% order of statuses shown in statusTxt fields. Not listed statuses go last.
global TXT_STATUS_ORDER = {
GENERATING
PASSING
ANALYSING
DISTORTING
COMPENSATING 
CALIBRATING 
};

% order of statuses shown in detailsTxt fields. Not listed statuses go last.
global DETAILS_STATUS_ORDER = {
CALIBRATING
GENERATING
ANALYSING
DISTORTING
COMPENSATING
};

%directions
global DIR_REC = 1;
global DIR_PLAY = 2;

% results
% good results - positive
% bad results - negative
% running results - even
% finished resulsts - odd
global NOT_FINISHED_RESULT = 2; % running, good
global RUNNING_OK_RESULT = 4; % running, good
global FINISHED_RESULT = 1; % finished, good
% e.g. calibration cannot detect stable freq
global FAILING_RESULT = -2; % running, bad
% e.g. failed calibration
global FAILED_RESULT = -1; % finished, bad


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
% format for generator
%CH[1000,0.85;2000,0.85]
global CMD_CHANNEL_FUND_PREFIX = 'CH';
% format for distortion - HL = Harmonic Level
%HL[-120,NA,-130]
global CMD_HARM_LEVELS_PREFIX = 'HL';


% direction cmd.info files
global CMD_FILE_REC = 'cmd.info';
global CMD_FILE_PLAY = 'cmd-play.info';

% prefices for device names (used in calibration file names)
DEVICE_REC_PREFIX = 'rec';
DEVICE_PLAY_PREFIX = 'play';

ZEROMQ_PORT_REC = 5555;
ZEROMQ_PORT_PLAY = 5556;

% minimum level of distortion peaks to be included into calibration profile
% depends largely on soundcard performance
global MIN_DISTORT_LEVEL = db2mag(-135);