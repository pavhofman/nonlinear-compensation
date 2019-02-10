pkg load zeromq;
pkg load database;

more off;
  
function dirStruct = createDirStruct();
  dirStruct = struct();
  dirStruct.plotPanels = cell(2);
  dirStruct.axes = cell(2);
  dirStruct.calPlots = cell(2);
  dirStruct.measPlots = cell(2);
  dirStruct.statusTxt = NA;
  dirStruct.detailTxts = cell(2);
endfunction

function dirStruct = drawDirPanel(fig, x, width, title)
  global CHANNEL_REL_HEIGHT;
  dirStruct = createDirStruct();
  panel = uipanel(fig, 
            "title", title,
            "position", [x 0 width 1]);
  dirStruct = drawChannelPlot(1, 0.01, 0.15, CHANNEL_REL_HEIGHT, 'Left', panel, dirStruct);
  dirStruct = drawChannelPlot(2, 0.84, 0.15, CHANNEL_REL_HEIGHT, 'Right', panel, dirStruct);
  
  % initializing status txt fields - 4
  statusTxts = cell(4, 1);
  for i = 1:4
    statusTxts{i} = drawStatusTxt(i, panel); 
  endfor
  dirStruct.statusTxts = statusTxts;
  
  
  dirStruct.detailTxts{1} = drawDetailTxt(1, 0.16, 0.33, CHANNEL_REL_HEIGHT, panel);
  dirStruct.detailTxts{2} = drawDetailTxt(2, 0.50, 0.33, CHANNEL_REL_HEIGHT, panel);  
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
  persistent HEIGHT = 0.025;
  statusTxt = uicontrol (panel,
            "style", "text",
            "units", "normalized",
            "fontweight", "demi", 
            "horizontalalignment", "left",
            "verticalalignment", "top",
            "position", [0.05, 0.96 - (HEIGHT * (id - 1)), 1, HEIGHT]
            );
endfunction

function clbkCalibrateFreqs(src, data)
  % calling scheduler-enabled calibration
  calibrateFreqsSched();
endfunction

function drawMidPanel(fig, x, width)
  
  midPanel = uipanel(fig, "title", "Common", "position", [x, 0, width, 1]);


  btnWidth = 180;
  global HEIGHT;
  global DIR_PANEL_REL_WIDTH;
  global WIDTH;
  
  yPos = HEIGHT - 50;
  uicontrol (midPanel, "string", "Calibrate VD Freqs", "position",[10 yPos btnWidth 30], 'callback', @clbkCalibrateFreqs);

  yPos -= 40;
  uicontrol (midPanel, "string", "Joint-Dev. Compen. VD", "position",[10 yPos btnWidth 30], 'callback', @clbkCompenVD);

  yPos -= 40;
  uicontrol (midPanel, "string", "Calibrate LPF", "position",[10 yPos btnWidth 30], 'callback', @clbkCalibrateLPF);

  yPos -= 40;
  uicontrol (midPanel, "string", "Joint-Dev. Compen. LPF", "position",[10 yPos btnWidth 30], 'callback', @clbkCompenLPF);

  yPos -= 40;
  uicontrol (midPanel, "string", "Measure Filter", "position",[10 yPos btnWidth 30], 'callback', @clbkMeasureFilter);

  yPos -= 40;
  uicontrol (midPanel, "string", "Split Calibration", "position",[10 yPos btnWidth 30], 'callback', @clbkSplitCalibrate);

  yPos -= 40;
  uicontrol (midPanel, "string", "Split-Dev. Compen. Sides", "position",[10 yPos btnWidth 30], 'callback', @clbkSplitCompen);


  global outBox = uicontrol (midPanel, "style", "edit", "position",[5, 5, (1-2*DIR_PANEL_REL_WIDTH)*WIDTH - 10, 100]);
  % outbox requires configuration
  set(outBox, 'horizontalalignment', 'left');
  set(outBox, 'verticalalignment', 'top');
  set(outBox, 'max', 1000);

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

function initMenu(fig)
  global cmdFileRec;
  global cmdFilePlay;
  global CALIBRATE = 'cal';
  global COMPENSATE = 'comp';
  global PASS = 'pass';

  fPlayPass = @(src, data) writeCmd(PASS, cmdFilePlay);
  fPlayComp = @(src, data) writeCmd(COMPENSATE, cmdFilePlay);

  playMenu = uimenu (fig, "label", "&Playback", "accelerator", "c");
  uimenu (playMenu, "label", "Pass", "callback", fPlayPass);
  uimenu (playMenu, "label", "Compensate", "callback", fPlayComp);

  fRecPass = @(src, data) writeCmd(PASS, cmdFileRec);
  fRecCal = @(src, data) writeCmd(CALIBRATE, cmdFileRec);
  fRecComp = @(src, data) writeCmd(COMPENSATE, cmdFileRec);
  
  recMenu = uimenu (fig, "label", "&Capture", "accelerator", "c");
  uimenu (recMenu, "label", "Pass", "callback", fRecPass);
  uimenu (recMenu, "label", "Compensate", "callback", fRecComp);
  uimenu (recMenu, "label", "Calibrate", "callback", fRecCal);
endfunction


global cmdFileRec = genDataPath(CMD_FILE_REC);
global cmdFilePlay = genDataPath(CMD_FILE_PLAY);

global fs = 48000;
global freq = 3000;

global WIDTH = 1000;
global HEIGHT = 600;

% relative height of the channel block (plot, detailTxt)
global CHANNEL_REL_HEIGHT = 0.85;

global DIR_PANEL_REL_WIDTH = 0.4;

global CH_DISTANCE_X = 0.3

global doQuit = false;

function doExit(fig)
  global doQuit;
  doQuit = true;
endfunction

% create figure and panel on it
fig = figure("toolbar", "none", "menubar", "figure",  'position', [100, 100, WIDTH, HEIGHT]);
set(fig, 'DeleteFcn', @(h, e) doExit(fig));

initMenu(fig);

playStruct = drawDirPanel(fig, 0, DIR_PANEL_REL_WIDTH, "Playback");
recStruct = drawDirPanel(fig, (1 - DIR_PANEL_REL_WIDTH), DIR_PANEL_REL_WIDTH, "Capture");
drawMidPanel(fig, DIR_PANEL_REL_WIDTH, (1 - 2*DIR_PANEL_REL_WIDTH));

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
  
  recInfo = rcvInfo(recSock);
  if isempty(recInfo)
    printf('Empty rec info\n');
  elseif recInfo.time < time() - MAX_INFO_AGE
    printf('Outdated rec info, flushing\n');
  else
    printf('Processing rec info\n');
    processInfo(recInfo, recStruct);
  endif

  playInfo = rcvInfo(playSock);
  if isempty(playInfo)
    printf('Empty play info\n');
  elseif playInfo.time < time() - MAX_INFO_AGE
    printf('Outdated play info, flushing\n');
  else
    printf('Processing play info\n');
    processInfo(playInfo, playStruct);
  endif

  drawnow();
endwhile