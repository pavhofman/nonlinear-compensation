pkg load control;

% CONSTANTS and DEFAULTS

% commands
global PAUSE = 'pause';
global CALIBRATE = 'cal';
global COMPENSATE = 'comp';
global PASS = 'pass';
global DISTORT = 'distort';
% show fft chart ('off' to disable)
global SHOW_FFT = 'showfft';
% sine generator
global GENERATE = 'gen';

% reading from audio file
global READFILE = 'readfile';
% record output data
global RECORD = 'rec';
% store recorded output data into audio file
global STORE_RECORDED = 'storerec';

% set mode + mode value
global SET_MODE = 'mode';

NO_CMD = '';

% statuses
global PAUSED = 'Paused';
global PASSING = 'Passing';
global CALIBRATING = 'Calibrating';
global ANALYSING = 'Analysing';
global COMPENSATING = 'Compensating';
global DISTORTING = 'Distorting';
global GENERATING = 'Generating';

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
global CMD_ID_PREFIX = "#ID#";

% format for setting mode
global CMD_MODE_PREFIX = "#MODE#";

% format for calibration frequency info
% #CHCF#[F1,minAmpl,maxAmpl;F2,minAmpl,maxAmpl] CHCF[F1,NA,NA; F2,NA,NA]
global CMD_CALFREQS_PREFIX = '#CHCF#';

% format for play amplitude levels - info for calibration
%PAMPL[0.5,0.5]
global CMD_PLAY_AMPLS_PREFIX = '#PAMPL#';

% number of calibration runs for averaging
% #CALR#10
global CMD_CALRUNS_PREFIX = '#CALR#';

%ECfilter
global CMD_EXTRA_CIRCUIT_PREFIX = '#EC#';

% format for generator
%CH[1000,0.85;2000,0.85]
global CMD_CHANNEL_FUND_PREFIX = '#CH#';

% format for distortion - AMPL = Harmonic Level
%AMPL[0.00001,NA,0.000001]
global CMD_AMPLS_PREFIX = '#AMPL#';


% continuous calibration ( cal #CONT1): 1 = yes, 0 = no (default)
global CMD_CONT_PREFIX = '#CONT#';

% channel ID (e.g. play-side channel ID for calibration
global CMD_CHANNEL_ID_PREFIX = '#CHID#';

% compensation type ID - see consts.m
global CMD_COMP_TYPE_PREFIX = '#CT#';

% for READFILE and STORE_RECORDED
global CMD_FILEPATH_PREFIX = '#FILE#';

% for SHOW_FFT - number of averages: #AVG#100
global CMD_FFTAVG_PREFIX = '#AVG#';
% for SHOW_FFT - fftsize: #SIZE#65536
global CMD_FFTSIZE_PREFIX = '#SIZE#';

% direction cmd.info files
global CMD_FILE_REC = 'cmd.info';
global CMD_FILE_PLAY = 'cmd-play.info';


% prefices for device names (used in calibration file names)
DEVICE_REC_PREFIX = 'rec';
DEVICE_PLAY_PREFIX = 'play';

% source - numerical values
global FILE_SRC = 1;
global PLAYREC_SRC = 2;

% sinks are fields of dynamic structs, must be strings
global MEMORY_SINK = 'MEM';
global PLAYREC_SINK = 'PR';

% compensation types
global COMP_TYPE_JOINT = 0;
global COMP_TYPE_PLAY_SIDE = 1;
global COMP_TYPE_REC_SIDE = 2;

% operation modes
% values = index of corresponding radio buttons in CTRL!
% dual/unbalanced/separate L, R
global MODE_DUAL = 1;
% id of channel to keep in MODE_BAL and MODE_SINGLE
% RIGHT
global KEEP_CHANNEL_ID = 1;

% balanced - PLAY: L = -R(equalized), R = R
%            REC: R = R - L(equalized)/2, L = R - L(equalized)/2
global MODE_BAL = 2;
% single channel - PLAY: L = 0, R = R
%                  REC: R = R - L, L = R - L
global MODE_SINGLE = 3;


global showFFTCfg = struct();
showFFTCfg.fig = NA;
showFFTCfg.enabled = false;
showFFTCfg.numAvg = 0;
showFFTCfg.restartAvg = 0;
showFFTCfg.fftSize = 2^16;

%%%%%%%%%%%%%%%%%%%%%%%
% configurable consts %
%%%%%%%%%%%%%%%%%%%%%%%

ZEROMQ_PORT_REC = 5555;
ZEROMQ_PORT_PLAY = 5556;

% length of one loop cycle in secs. 
% Intentionally chosen time which is not integer multiple of standard measuring frequencies/harmonics. Integer multiple (e.g. 200ms) hides errors in calculations.
CYCLE_LENGTH = 0.211;

% period size (soundcard fragment size)
global PERIOD_SIZE = 20000;

% minimum level of distortion peaks to be included into calibration profile
% depends largely on soundcard performance
% low number raises CPU load - more harmonics to be compensated
% too high number causes a harmonic is not included in split-sides compensation, even if playback-side distortion is rather high
% keep as low as the CPU allows.
global MIN_DISTORT_LEVEL = db2mag(-155);

% maximum number of detected distortions
global MAX_DISTORT_ID = 100;

% array of specific channel numbers from/to audio file or empty = all channels in input
global FILE_CHAN_LIST = [];

% should send info (i.e. use zeroMQ library)
useZeroMQ = true;

global MIN_LOG_LEVEL = 'DEBUG';

% default mode
global chMode = MODE_DUAL;

% calPeaks constants
% calPeaks: time, fundPhaseDiff1, fundPhaseDiff2, playFundAmpl1, playFundAmpl2, fundAmpl1, fundAmpl2, f1, f2, f3...... where f1, f2,... are distortion freqs in the same order as freqs
% index of fundAmpl1
global AMPL_IDX = 6;
% index of fundAmpl1 of playback side for COMP_TYPE_JOINT
global PLAY_AMPL_IDX = 4;
global PEAKS_START_IDX = 8;
global PHASEDIFF_IDX = 2;
% fund amplitude within +/- AMPL_TO_REPLACE_TOLERANCE considered same
global AMPL_TO_REPLACE_TOLERANCE = db2mag(0.01);

% maximum fund ampl. difference between subsequent runs to consider stable fundPeaks
% use the lowest value your soundcard stability allows
global MAX_AMPL_DIFF = db2mag(-100);


% ID of output channel used for split calibration
% the most logical setting is using the same channel as in MODE_SINGLE and MODE_BALANCED
global PLAY_CH_ID = KEEP_CHANNEL_ID;

% analysed input ch goes through LP or VD, the other input channel is direct
global ANALYSED_CH_ID = 2;

global EXTRA_CIRCUIT_VD = 'vd';
global EXTRA_CIRCUIT_LP1 = 'lp1';  
global EXTRA_TRANSFER_DIR = 'transfer';  


% transfer file/record maximum age to be accepted - 3 days
global MAX_TRANSFER_AGE_DAYS = 3;
global MAX_TRANSFER_AGE = 60 * 60 * 24 * MAX_TRANSFER_AGE_DAYS;

% directory for calibration and cmd files - must be writable by current user, files will be generated by calibrate.m
global dataDir = 'data';

% configuration of audio interface
global playRecConfig = struct();
playRecConfig.pageBufCount = 5;
playRecConfig.recChanList = [1 2];
playRecConfig.playChanList = [1 2];