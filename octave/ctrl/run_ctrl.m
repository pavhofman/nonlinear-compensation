pkg load zeromq;
pkg load database;

more off;
  
function dirStruct = createDirStruct();
  dirStruct = struct();
  dirStruct.plotPanels = cell(2);
  dirStruct.axes = cell(2);
  dirStruct.calPlots = cell(2);
  dirStruct.measPlots = cell(2);
  dirStruct.statusTxts = NA;
  dirStruct.detailTxts = cell(2);
  dirStruct.distortOnMenu = NA;
  dirStruct.distortOffMenu = NA;
  dirStruct.genOnMenu = NA;
  dirStruct.genOffMenu = NA;
  
endfunction

function dirStruct = drawDirPanel(fig, x, width, title, dirStruct)
  global CHANNEL_REL_HEIGHT;
  panel = uipanel(fig, 
            "title", title,
            "position", [x, 0.1, width, 0.9]);
  dirStruct = drawChannelPlot(1, 0.01, 0.12, CHANNEL_REL_HEIGHT, 'Left', panel, dirStruct);
  dirStruct = drawChannelPlot(2, 0.87, 0.12, CHANNEL_REL_HEIGHT, 'Right', panel, dirStruct);
  
  % initializing status txt fields - 4
  statusTxts = cell(4, 1);
  for i = 1:4
    statusTxts{i} = drawStatusTxt(i, panel); 
  endfor
  dirStruct.statusTxts = statusTxts;
  
  
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


function statusTxt = drawStatusTxt(id, panel)
  persistent TXT_HEIGHT = 0.026;
  statusTxt = uicontrol (panel,
            "style", "text",
            "units", "normalized",
            "fontweight", "demi", 
            "horizontalalignment", "left",
            "verticalalignment", "top",
            "position", [0.02, 0.96 - (TXT_HEIGHT * (id - 1)), 1, TXT_HEIGHT]
            );
endfunction

function clbkCalibrateFreqs(src, data)
  % calling scheduler-enabled calibration
  calibrateFreqsSched();
endfunction

function [plotStruct] = initPlot(plotPanel)
  axis = axes ('parent', plotPanel);
  x = [];
  calLevels = [];
  curLevels = [];
  % 2 lines - calibration levels, current levels
  lines = plot(axis, 0, 0, '>r', 'markerfacecolor', 'r', 1, 0, '<r', 'markerfacecolor', 'b');
  % fixed limit
  set(axis, 'ylim', [-20,1]);
  calLine = lines(1);
  curLine = lines(2);
  set(calLine, 'visible', 'off');
  set(curLine, 'visible', 'off');
  
  set(axis,'Xtick',[])
  set(axis, "ygrid", "on");
  set(axis, "outerposition",  [0, 0, 1, 1])
  
  plotStruct = struct();
  plotStruct.axis = axis;
  % line with calibration level points
  plotStruct.calLine = calLine;
  % line with current level points
  plotStruct.curLine = curLine;
endfunction

function [playStruct, recStruct] = initMenu(fig, playStruct, recStruct);
  global cmdFileRec;
  global cmdFilePlay;
  global CALIBRATE;
  global COMPENSATE;
  global PASS;
  global DISTORT;
  global GENERATE;

  fPass = @(src, data, cmdFile) writeCmd(PASS, cmdFile);
  fComp = @(src, data, cmdFile) writeCmd(COMPENSATE, cmdFile);

  playMenu = uimenu (fig, "label", "&Playback");
  uimenu(playMenu, "label", "Pass", "callback", {fPass, cmdFilePlay});
  uimenu(playMenu, "label", "Compensate", "callback", {fComp, cmdFilePlay});
  playStruct.genOnMenu = uimenu(playMenu, "label", "Generate", 'separator', 'on', "callback", {@clbkGenerate, 'Generate on Playback Side', cmdFilePlay});
  playStruct.genOffMenu = uimenu(playMenu, "label", "Stop Generating", 'separator', 'on', 'visible', 'off', "callback", {@clbkCmdOff, GENERATE, cmdFilePlay});  
  playStruct.distortOnMenu = uimenu(playMenu, "label", "Distort", "callback", {@clbkDistort, 'Distort on Playback Side', cmdFilePlay});
  playStruct.distortOffMenu = uimenu(playMenu, "label", "Stop Distorting", 'visible', 'off', "callback", {@clbkCmdOff, DISTORT, cmdFilePlay});

  fRecCal = @(src, data) writeCmd(CALIBRATE, cmdFileRec);
  
  recMenu = uimenu (fig, "label", "&Capture");
  uimenu(recMenu, "label", "Pass", "callback", {fPass, cmdFileRec});
  uimenu(recMenu, "label", "Compensate", "callback", {fComp, cmdFileRec});
  uimenu(recMenu, "label", "Calibrate", "callback", fRecCal);
  recStruct.genOnMenu = uimenu(recMenu, "label", "Generate", 'separator', 'on', "callback", {@clbkGenerate, 'Generate on Capture Side', cmdFileRec});
  recStruct.genOffMenu = uimenu(recMenu, "label", "Stop Generating", 'separator', 'on', 'visible', 'off', "callback", {@clbkCmdOff, GENERATE, cmdFileRec});  
  recStruct.distortOnMenu = uimenu(recMenu, "label", "Distort", "callback", {@clbkDistort, 'Distort on Capture Side', cmdFileRec});
  recStruct.distortOffMenu = uimenu(recMenu, "label", "Stop Distorting", 'visible', 'off', "callback", {@clbkCmdOff, DISTORT, cmdFileRec});
  
  tasksMenu = uimenu (fig, "label", "&Tasks");
  
  uimenu(tasksMenu, "label", "Calibrate VD Freqs", 'callback', @clbkCalibrateFreqs);
  uimenu(tasksMenu, "label", "Joint-Dev. Compen. VD", 'callback', @clbkCompenVD);
  uimenu(tasksMenu, "label", "Calibrate LPF", 'callback', @clbkCalibrateLPF);
  uimenu(tasksMenu, "label", "Joint-Dev. Compen. LPF", 'callback', @clbkCompenLPF);
  uimenu(tasksMenu, "label", "Measure Filter", 'callback', @clbkMeasureFilter);
  uimenu(tasksMenu, "label", "Split Calibration", 'callback', @clbkSplitCalibrate);
  uimenu(tasksMenu, "label", "Split-Dev. Compen. Sides", 'callback', @clbkSplitCompen);
endfunction


global cmdFileRec = genDataPath(CMD_FILE_REC);
global cmdFilePlay = genDataPath(CMD_FILE_PLAY);

global fs = 48000;
global freq = 3000;

global WIDTH = 1000;
global HEIGHT = 600;

% relative height of the channel block (plot, detailTxt)
global CHANNEL_REL_HEIGHT = 0.85;

global DIR_PANEL_REL_WIDTH = 0.5;

global CH_DISTANCE_X = 0.3

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

playStruct = createDirStruct();
recStruct = createDirStruct();

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
set(fig, 'position', [100, 100, WIDTH, HEIGHT + 1]);
set(fig, 'position', [100, 100, WIDTH, HEIGHT]);
% queue for schedItems
global schedQueue = cell();


% create  PAIR sockets
recSock = zmq_socket(ZMQ_PAIR);
playSock = zmq_socket(ZMQ_PAIR);

% bind to corresponding ports
zmq_bind (recSock, ['tcp://*:' num2str(ZEROMQ_PORT_REC)]);
zmq_bind (playSock, ['tcp://*:' num2str(ZEROMQ_PORT_PLAY)]);

recInfo = [];
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
    printf('Empty rec info\n');
  else
    printf('Processing rec info\n');
    processInfo(recInfo, recStruct);
  endif


  do
    playInfo = rcvInfo(playSock);
  until isempty(playInfo) || playInfo.time > time() - MAX_INFO_AGE
  if isempty(playInfo)
    printf('Empty play info\n');
  else
    printf('Processing play info\n');
    processInfo(playInfo, playStruct);
  endif

  drawnow();
endwhile