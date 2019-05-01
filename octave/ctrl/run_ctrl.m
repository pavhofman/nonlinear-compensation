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
  
  dirStruct.chModeGroup = NA;
  dirStruct.modeRadios = cell(3);
  
  dirStruct.dir = dir;
  
endfunction

global cmdFileRec = genDataPath(CMD_FILE_REC, dataDir);
global cmdFilePlay = genDataPath(CMD_FILE_PLAY, dataDir);

global fs = 48000;
global freq = 3000;

global POS_X = 100;
global POS_Y = 100;

global WIDTH = 1000;
global HEIGHT = 600;


global DIR_PANEL_REL_WIDTH = 0.5;

global CH_DISTANCE_X = 0.3
global TXT_FIELD_HEIGHT = 0.026

global doQuit = false;

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

global playStruct = createDirStruct(DIR_PLAY);
global recStruct = createDirStruct(DIR_REC);

[playStruct, recStruct] = initMenu(fig, playStruct, recStruct);

playStruct = drawDirPanel(fig, 0, DIR_PANEL_REL_WIDTH, "Playback", playStruct, cmdFilePlay);
recStruct = drawDirPanel(fig, (1 - DIR_PANEL_REL_WIDTH), DIR_PANEL_REL_WIDTH, "Capture", recStruct, cmdFileRec);



% buttom panel with outBox
global outBox = uicontrol(fig, "style", "edit", "units", "normalized", 'position', [0, 0, 1, 0.1]);
% outbox requires configuration
set(outBox, 'horizontalalignment', 'left');
set(outBox, 'verticalalignment', 'top');
set(outBox, 'max', 1000);

% resizing figure to fix painting problems
set(fig, 'position', [POS_X, POS_Y, WIDTH, HEIGHT + 1]);
set(fig, 'position', [POS_X, POS_Y, WIDTH, HEIGHT]);
% queue for schedItems
global schedQueue = cell();


% create  PAIR sockets
recSock = zmq_socket(ZMQ_PAIR);
playSock = zmq_socket(ZMQ_PAIR);

% bind to corresponding ports
zmq_bind (recSock, ['tcp://*:' num2str(ZEROMQ_PORT_REC)]);
zmq_bind (playSock, ['tcp://*:' num2str(ZEROMQ_PORT_PLAY)]);

global recInfo = [];
global playInfo = [];

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