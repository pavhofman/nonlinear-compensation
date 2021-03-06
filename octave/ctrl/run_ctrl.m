pkg load zeromq;
pkg load database;
pkg load optim;
pkg load instrument-control;

more off;
  
function dirStruct = createDirStruct(direction)
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
  
  dirStruct.direction = direction;
  
end

global cmdFileRec;
cmdFileRec = getFilePath(CMD_FILE_REC, commDir);
global cmdFilePlay;
cmdFilePlay = getFilePath(CMD_FILE_PLAY, commDir);

global POS_X;
POS_X = 100;
global POS_Y;
POS_Y = 100;

global WIDTH;
WIDTH = 1000;
global HEIGHT;
HEIGHT = 600;


global DIR_PANEL_REL_WIDTH;
DIR_PANEL_REL_WIDTH = 0.5;

global CH_DISTANCE_X;
CH_DISTANCE_X = 0.3;

global doQuit;
doQuit = false;

global ABORT;
ABORT = -1;

% list of currently running task functions
global taskFNames;
taskFNames = {};
% list of task strings to show
global taskLabels;
taskLabels = {};
% fname of task to abort in next runScheduledTask call
global taskFNameToAbort;
taskFNameToAbort = '';

global maxTransferAge;
maxTransferAge = 0;

function doExit()
  global doQuit;
  doQuit = true;
  % the DeleteBtn stops all processes
  stopAll();
end

% create figure and panel on it
fig = figure(
  'name','CleanSine',
  'numbertitle', 'off',
  'menubar', 'none',
  'toolbar', 'none',
  'position', [100, 100, WIDTH, HEIGHT],
  'DeleteFcn', @(h, e) doExit());

global playStruct;
playStruct = createDirStruct(DIR_PLAY);
global recStruct;
recStruct = createDirStruct(DIR_REC);

[playStruct, recStruct] = initMenu(fig, playStruct, recStruct);

% direction panels
DIR_PANEL_HEIGHT = 0.8;
DIR_PANEL_Y = 1 - DIR_PANEL_HEIGHT;
% from the top - i.e. from 1
playStruct = drawDirPanel(fig, 0, DIR_PANEL_Y, DIR_PANEL_REL_WIDTH, DIR_PANEL_HEIGHT, "Playback", playStruct, cmdFilePlay);
recStruct = drawDirPanel(fig, (1 - DIR_PANEL_REL_WIDTH), DIR_PANEL_Y, DIR_PANEL_REL_WIDTH, DIR_PANEL_HEIGHT, "Capture", recStruct, cmdFileRec);

% panel with adapter settings
ADAPTER_PANEL_HEIGHT = 0.1;
ADAPTER_PANEL_Y = DIR_PANEL_Y - ADAPTER_PANEL_HEIGHT;

% button panel with fast-access buttons
BTN_PANEL_WIDTH = 0.25;
drawBtnPanel(fig, 0, ADAPTER_PANEL_Y, BTN_PANEL_WIDTH, ADAPTER_PANEL_HEIGHT);

global adapterStruct;
initAdapterStruct();

drawAdapterPanel(fig, BTN_PANEL_WIDTH, ADAPTER_PANEL_Y, 1 - BTN_PANEL_WIDTH, ADAPTER_PANEL_HEIGHT);

% bottom panel with outBox
% all the way to adapter panel
BOTTOM_PANEL_HEIGHT = ADAPTER_PANEL_Y - 0;
OUTBOX_WIDTH = 0.7;
outBoxPanel = uipanel(fig,
            "title", 'Messages',
            "position", [0, 0, OUTBOX_WIDTH, BOTTOM_PANEL_HEIGHT]);
global outBox;
outBox = uicontrol(outBoxPanel,
            "style", "edit",
             "units", "normalized",
             'position', [0, 0, 1, 0.95]);
% outbox requires configuration
set(outBox, 'horizontalalignment', 'left');
set(outBox, 'verticalalignment', 'top');
set(outBox, 'max', 1000);

TASKS_WIDTH = 1 - OUTBOX_WIDTH;
tasksPanel = uipanel(fig,
            "title", 'Running Tasks',
            "position", [OUTBOX_WIDTH, 0, TASKS_WIDTH, BOTTOM_PANEL_HEIGHT]);

global taskLabelsBox;
taskLabelsBox = uicontrol(tasksPanel, "style", "text",
            "units", "normalized",
            'foregroundcolor', [0, 0.5, 0],
            'horizontalalignment', 'left',
            'verticalalignment', 'middle',
            'position', [0, 0, 0.6, 0.95]);


global abortTasksBtn;
abortTasksBtn = uicontrol(tasksPanel, 'style', 'pushbutton',
            'string', 'Abort',
            "units", "normalized",
            'visible', 'off',
            "units", "normalized",
            'callback',  @(h, e) abortLastTask(),
             "position",[0.65 0.2 0.3 0.6]);

% resizing figure to fix painting problems
set(fig, 'position', [POS_X, POS_Y, WIDTH, HEIGHT + 1]);
set(fig, 'position', [POS_X, POS_Y, WIDTH, HEIGHT]);
% queue for schedTasks
global schedTasksQueue;
schedTasksQueue = cell();


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

% display interval of received infos (not processing in scheduled tasks!) has lower limit to avoid useless refreshes
lastDisplayedRecInfoTime = 0;
lastDisplayedPlayInfoTime = 0;
MIN_INFO_DISPLAY_INTERVAL = 0.1;

% loop until doQuit, waiting for client infos
while (~doQuit)
  % process scheduled callbacks, if any applicable at this time
  % callbacks can use received info structures
  runScheduledTask(recInfo, playInfo);
  % Leds, switches, etc.
  adapterStruct.updateIOFunc(recInfo, playInfo);
  
  do
    localRecInfo = rcvInfo(recSock);
  until isempty(localRecInfo) || localRecInfo.time > time() - MAX_INFO_AGE
  if isempty(localRecInfo)
    writeLog('TRACE', 'Empty rec infoStruct');
  else
    recInfo = localRecInfo;
    writeLog('TRACE', 'Processing rec infoStruct with ID %d', recInfo.id);

    % displaying
    if lastDisplayedRecInfoTime + MIN_INFO_DISPLAY_INTERVAL < recInfo.time
      displayInfo(recInfo, recStruct);
      lastDisplayedRecInfoTime = recInfo.time;
    else
      writeLog('TRACE', 'Skipped displaying recInfo');
    end
  end


  do
    localPlayInfo = rcvInfo(playSock);
  until isempty(localPlayInfo) || localPlayInfo.time > time() - MAX_INFO_AGE
  if isempty(localPlayInfo)
    writeLog('TRACE', 'Empty play infoStruct');
  else
    playInfo = localPlayInfo;
    writeLog('TRACE', 'Processing play infoStruct with ID %d', playInfo.id);

    % displaying
    if lastDisplayedPlayInfoTime + MIN_INFO_DISPLAY_INTERVAL < playInfo.time
      displayInfo(playInfo, playStruct);
      lastDisplayedPlayInfoTime = playInfo.time;
    else
      writeLog('TRACE', 'Skipped displaying playInfo');
    end
  end

  drawnow();
end