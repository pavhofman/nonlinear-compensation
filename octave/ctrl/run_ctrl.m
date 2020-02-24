pkg load zeromq;
pkg load database;
pkg load optim;

more off;
  
function dirStruct = createDirStruct(dir)
  dirStruct = struct();
  dirStruct.plotPanels = cell(2);
  dirStruct.axes = cell(2);
  dirStruct.calPlots = cell(2);
  dirStruct.measPlots = cell(2);
  dirStruct.statusTxts = NA;
  dirStruct.detailTxts = cell(2);
  
  dirStruct.distortOnMenu = NA;
  dirStruct.distortOffMenu = NA;
  
  dirStruct.genOffMenu = NA;
  
  dirStruct.calSingleMenu = NA;
  dirStruct.calContMenu = NA;
  dirStruct.calOffMenu = NA;
  
  dirStruct.readfileMenu = NA;
  dirStruct.readfileOffMenu = NA;
  dirStruct.recordMenu = NA;
  dirStruct.recordOffMenu = NA;
  dirStruct.storeRecordedMenu = NA;
  
  dirStruct.fftMenu = NA;
  dirStruct.fftOffMenu = NA;
  
  dirStruct.sourceTxt = NA;
  dirStruct.sinkTxt = NA;
  
  dirStruct.dir = dir;
  
endfunction

global cmdFileRec;
cmdFileRec = genDataPath(CMD_FILE_REC, dataDir);
global cmdFilePlay;
cmdFilePlay = genDataPath(CMD_FILE_PLAY, dataDir);

global POS_X = 100;
global POS_Y = 100;

global WIDTH = 1000;
global HEIGHT = 600;


global DIR_PANEL_REL_WIDTH = 0.5;

global CH_DISTANCE_X = 0.3

global doQuit;
doQuit = false;

global ABORT = -1;
% list of currently running task functions
global taskFNames;
taskFNames = {};
% list of task strings to show
global taskLabels;
taskLabels = {};
% fname of task to abort in next runScheduled call
global fNameToAbort;
fNameToAbort = '';

function doExit(fig)
  global doQuit;
  doQuit = true;
endfunction

% create figure and panel on it
fig = figure('position', [100, 100, WIDTH, HEIGHT]);
% menubar must be removed with set, otherwise no menu bar is displayed
set(fig, 'menubar', 'none');
set(fig, "toolbar", "none");

set(fig, 'DeleteFcn', @(h, e) doExit(fig));

global playStruct;
playStruct = createDirStruct(DIR_PLAY);
global recStruct;
recStruct = createDirStruct(DIR_REC);

[playStruct, recStruct] = initMenu(fig, playStruct, recStruct);

% dir panels
DIR_PANEL_HEIGHT = 0.8;
DIR_PANEL_Y = 1 - DIR_PANEL_HEIGHT;
% from the top - i.e. from 1
playStruct = drawDirPanel(fig, 0, DIR_PANEL_Y, DIR_PANEL_REL_WIDTH, DIR_PANEL_HEIGHT, "Playback", playStruct, cmdFilePlay);
recStruct = drawDirPanel(fig, (1 - DIR_PANEL_REL_WIDTH), DIR_PANEL_Y, DIR_PANEL_REL_WIDTH, DIR_PANEL_HEIGHT, "Capture", recStruct, cmdFileRec);



% bottom panel with outBox
outBoxPanel = uipanel(fig,
            "title", 'Messages',
            "position", [0, 0, 0.7, 0.1]);
global outBox;
outBox = uicontrol(outBoxPanel,
            "style", "edit",
             "units", "normalized", 'position', [0, 0, 1, 0.95]);
% outbox requires configuration
set(outBox, 'horizontalalignment', 'left');
set(outBox, 'verticalalignment', 'top');
set(outBox, 'max', 1000);


tasksPanel = uipanel(fig,
            "title", 'Running Tasks',
            "position", [0.7, 0, 0.3, 0.1]);

global taskLabelsBox;
taskLabelsBox = uicontrol(tasksPanel, "style", "text",
            "units", "normalized",
            'position', [0, 0, 0.6, 0.95]);

setFieldColor(taskLabelsBox,  [0, 0.5, 0]);
set(taskLabelsBox, 'horizontalalignment', 'left');
set(taskLabelsBox, 'verticalalignment', 'middle');

global abortTasksButton;
abortTasksButton = uicontrol(tasksPanel, 'style', 'pushbutton',
            'string', 'Abort',
            "units", "normalized",
            'enable', 'off',
            "units", "normalized",
            'callback',  @(h, e) abortLastTask(),
             "position",[0.65 0.2 0.3 0.6]);

% resizing figure to fix painting problems
set(fig, 'position', [POS_X, POS_Y, WIDTH, HEIGHT + 1]);
set(fig, 'position', [POS_X, POS_Y, WIDTH, HEIGHT]);
% queue for schedItems
global schedQueue;
schedQueue = cell();


% create  PAIR sockets
recSock = zmq_socket(ZMQ_PAIR);
playSock = zmq_socket(ZMQ_PAIR);

% bind to corresponding ports
zmq_bind (recSock, ['tcp://*:' num2str(ZEROMQ_PORT_REC)]);
zmq_bind (playSock, ['tcp://*:' num2str(ZEROMQ_PORT_PLAY)]);

global recInfo;
recInfo = [];
global playInfo;
playInfo = [];

% maximum age of received info for processing
% older infos are skipped - flushing the incoming queue
MAX_INFO_AGE = 0.5;

% loop until doQuit, waiting for client infos
while (~doQuit)
  % process scheduled callbacks, if any applicable at this time
  % callbacks can use received info structures
  runScheduled(recInfo, playInfo);
  
  do
    localRecInfo = rcvInfo(recSock);
  until isempty(localRecInfo) || localRecInfo.time > time() - MAX_INFO_AGE
  if isempty(localRecInfo)
    writeLog('TRACE', 'Empty rec info');
  else
    writeLog('TRACE', 'Processing rec info');
    recInfo = localRecInfo;
    processInfo(recInfo, recStruct);
  endif


  do
    localPlayInfo = rcvInfo(playSock);
  until isempty(localPlayInfo) || localPlayInfo.time > time() - MAX_INFO_AGE
  if isempty(localPlayInfo)
    writeLog('TRACE', 'Empty play info');
  else
    writeLog('TRACE', 'Processing play info');
    playInfo = localPlayInfo;
    processInfo(playInfo, playStruct);
  endif

  drawnow();
endwhile