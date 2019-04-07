pkg load zeromq;
pkg load database;

more off;
  
function dirStruct = createDirStruct(dir);
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

function dirStruct = drawDirPanel(fig, x, width, title, dirStruct)
  global CHANNEL_REL_HEIGHT;
  persistent STATUS_TXT_CNT = 5;
  global TXT_FIELD_HEIGHT;
  
  panel = uipanel(fig, 
            "title", title,
            "position", [x, 0.1, width, 0.9]);
  % from the top
  devPanelHeight = 2 * TXT_FIELD_HEIGHT + 0.05;
  maxFigY = 0.99;
  
  devPanelY = maxFigY - devPanelHeight;
  inDevPanel = uipanel(panel, 
            "title", 'IN',
            "position", [0, devPanelY, 0.5, devPanelHeight]);
  maxDevPanelY = 0.88;
  sourceTxt = uicontrol (inDevPanel,
            "style", "text",
            "units", "normalized",
            "horizontalalignment", "left",
            "verticalalignment", "top",
            "position", [0.01, 0.01, 1, maxDevPanelY]
            );

  dirStruct.sourceTxt = sourceTxt;

  outDevPanel = uipanel(panel, 
            "title", 'OUT',
            "position", [0.5, devPanelY, 0.5, devPanelHeight]);
            
  sinkTxt = uicontrol (outDevPanel,
            "style", "text",
            "units", "normalized",
            "horizontalalignment", "left",
            "verticalalignment", "top",
            "position", [0.01, 0.01, 1, maxDevPanelY]
            );
  dirStruct.sinkTxt = sinkTxt;          
  
  % initializing status txt fields
  statusTxts = cell(STATUS_TXT_CNT, 1);
  for i = 1:STATUS_TXT_CNT
    statusTxts{i} = drawStatusTxt(i, panel, devPanelY - 0.03); 
  endfor
  dirStruct.statusTxts = statusTxts;
  
  dirStruct = drawChannelPlot(1, 0.01, 0.12, CHANNEL_REL_HEIGHT, 'Left', panel, dirStruct);
  dirStruct = drawChannelPlot(2, 0.87, 0.12, CHANNEL_REL_HEIGHT, 'Right', panel, dirStruct);
  
  
  dirStruct.detailTxts{1} = drawDetailTxt(1, 0.14, 0.35, CHANNEL_REL_HEIGHT, panel);
  dirStruct.detailTxts{2} = drawDetailTxt(2, 0.50, 0.35, CHANNEL_REL_HEIGHT, panel);  
endfunction


function dirStruct = drawChannelPlot(channelID, x, width, height, title, panel, dirStruct)
  plotPanel = uipanel(panel, 
            "title", title, 
            "position", [x, 0, width, height]);
  dirStruct.plotPanels{channelID} = plotPanel;
  dirStruct.calPlots{channelID} = initPlot(plotPanel);  
endfunction

function detailTxt = drawDetailTxt(channelID, x, width, height, panel, dirStruct)
    detailTxt = uicontrol (panel,
            "style", "text",
            "units", "normalized",
            "horizontalalignment", "left",
            "verticalalignment", "top",
            "position", [x, 0, width, height]);
endfunction


function statusTxt = drawStatusTxt(id, panel, topY)
  global TXT_FIELD_HEIGHT;
  statusTxt = uicontrol (panel,
            "style", "text",
            "units", "normalized",
            "fontweight", "demi", 
            "horizontalalignment", "left",
            "verticalalignment", "top",
            "position", [0.01, topY - (TXT_FIELD_HEIGHT * (id - 1)), 1, TXT_FIELD_HEIGHT]
            );
endfunction

function [plotStruct] = initPlot(plotPanel)
  axis = axes ('parent', plotPanel);
  x = [];
  % 2 lines - calibration levels, current levels
  lines = plot(axis, 0, 0, '>r', 'markerfacecolor', 'r', 1, 0, '<r', 'markerfacecolor', 'b', 0.5, 0, '<r', 'markerfacecolor', 'g');
  % fixed limit
  set(axis, 'ylim', [-20,0]);
  calLine = lines(1);
  curLine = lines(2);
  lastLine = lines(3);
  set(calLine, 'visible', 'off');
  set(curLine, 'visible', 'off');
  set(lastLine, 'visible', 'off');
  
  set(axis,'Xtick',[])
  set(axis, "ygrid", "on");
  set(axis, "outerposition",  [0, 0, 1, 1])
  set(axis, "outerposition",  [0, 0, 1, 1])
  
  plotStruct = struct();
  plotStruct.axis = axis;
  % line with calibration level points
  plotStruct.calLine = calLine;
  % line with current level points
  plotStruct.curLine = curLine;
  % line with last level points before calibration
  plotStruct.lastLine = lastLine;
endfunction


global cmdFileRec = genDataPath(CMD_FILE_REC);
global cmdFilePlay = genDataPath(CMD_FILE_PLAY);

global fs = 48000;
global freq = 3000;

global POS_X = 100;
global POS_Y = 100;

global WIDTH = 1000;
global HEIGHT = 600;

% relative height of the channel block (plot, detailTxt)
global CHANNEL_REL_HEIGHT = 0.75;

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

playStruct = drawDirPanel(fig, 0, DIR_PANEL_REL_WIDTH, "Playback", playStruct);
recStruct = drawDirPanel(fig, (1 - DIR_PANEL_REL_WIDTH), DIR_PANEL_REL_WIDTH, "Capture", recStruct);



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
    recInfo = rcvInfo(recSock);
  until isempty(recInfo) || recInfo.time > time() - MAX_INFO_AGE
  if isempty(recInfo)
    writeLog('DEBUG', 'Empty rec info');
  else
    writeLog('DEBUG', 'Processing rec info');
    processInfo(recInfo, recStruct);
  endif


  do
    playInfo = rcvInfo(playSock);
  until isempty(playInfo) || playInfo.time > time() - MAX_INFO_AGE
  if isempty(playInfo)
    writeLog('DEBUG', 'Empty play info');
  else
    writeLog('DEBUG', 'Processing play info');
    processInfo(playInfo, playStruct);
  endif

  drawnow();
endwhile