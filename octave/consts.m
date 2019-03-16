pkg load control;

% CONSTANTS and DEFAULTS

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

% reading/writing audio file
global READFILE = 'readfile';
global WRITEFILE = 'writefile';

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

% continuous calibration ( cal #CONT1): 1 = yes, 0 = no (default)
global CMD_CONT_PREFIX = '#CONT';

global CMD_FILEPATH_PREFIX = '#FILE#';

% direction cmd.info files
global CMD_FILE_REC = 'cmd.info';
global CMD_FILE_PLAY = 'cmd-play.info';

% prefices for device names (used in calibration file names)
DEVICE_REC_PREFIX = 'rec';
DEVICE_PLAY_PREFIX = 'play';


FILE_SRC = 1;
PLAYREC_SRC = 2;

FILE_SINK = 1;
PLAYREC_SINK = 2;


ZEROMQ_PORT_REC = 5555;
ZEROMQ_PORT_PLAY = 5556;

% length of one loop cycle in secs. 
% Intentionally chosen time which is not integer multiple of standard measuring frequencies/harmonics. Integer multiple (e.g. 200ms) hides errors in calculations.
CYCLE_LENGTH = 0.211;

% minimum level of distortion peaks to be included into calibration profile
% depends largely on soundcard performance
global MIN_DISTORT_LEVEL = db2mag(-138);

global showFFTCfg = struct();
showFFTCfg.numAvg = 0;
showFFTCfg.restartAvg = 0;
showFFTCfg.fftSize = 2^16;

% array of specific channel numbers from/to audio file or empty = all channels in input
global FILE_CHAN_LIST = [];

# show FFT charts in direction - array of DIR_REC, DIR_PLAY or empty
global showFFT = [];

global sourceStruct = struct();
sourceStruct.file = '';
% default - no source
sourceStruct.src = NA;
sourceStruct.name = '';

global sinkStruct = struct();
sinkStruct.file = '';
% default - no sinks
sinkStruct.sinks = [];
sinkStruct.names = cell();
