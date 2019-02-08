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

function dirStruct = drawChannelPlot(channelID, x, width, title, panel, dirStruct)
  plotPanel = uipanel(panel, 
            "title", title, 
            "position", [x, 0, width, 0.90]);
  dirStruct.plotPanels{channelID} = plotPanel;
  [dirStruct.calPlots{channelID}, dirStruct.axes{channelID}] = initPlot(plotPanel);  
endfunction

function dirStruct = drawDetailTxt(channelID, x, width, panel, dirStruct)
    dirStruct.detailTxts{channelID} = uicontrol (panel,
            "style", "text",
            "units", "normalized",
            "string", "unknown",
            "horizontalalignment", "left",
            "verticalalignment", "top",
            "position", [x, 0, width, 0.90]);
endfunction

function dirStruct = drawDirPanel(fig, x, width, title)
  dirStruct = createDirStruct();
  panel = uipanel(fig, 
            "title", title,
            "position", [x 0 width 1]);
  dirStruct = drawChannelPlot(1, 0.01, 0.15, 'Left', panel, dirStruct);
  dirStruct = drawChannelPlot(2, 0.84, 0.15, 'Right', panel, dirStruct);
  
  
  statusTxt = uicontrol (panel,
            "style", "text",
            "units", "normalized",
            "fontweight", "demi", 
            "string", "unknown",
            "horizontalalignment", "left",
            "verticalalignment", "top",
            "position", [0.05 0.90 1 0.08]);
  dirStruct.statusTxt = statusTxt;
  
  dirStruct = drawDetailTxt(1, 0.16, 0.33, panel, dirStruct);
  dirStruct = drawDetailTxt(2, 0.50, 0.33, panel, dirStruct);  
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

function [calPlot, axis] = initPlot(plotPanel)
  axis = axes ('parent', plotPanel);
  x = zeros(1, 5);
  calPlot = plot(axis, x, 20*log10([0.9 0.8 0.7 0.65 0.6 ]), '>r', 'markerfacecolor', 'r');
  set(axis,'Xtick',[])
  set(axis, "ygrid", "on");
  set(axis, "outerposition",  [0, 0, 1, 1])
endfunction

% create  PAIR sockets
recSock = zmq_socket(ZMQ_PAIR);
playSock = zmq_socket(ZMQ_PAIR);

% bind to corresponding ports
zmq_bind (recSock, ['tcp://*:' num2str(ZEROMQ_PORT_REC)]);
zmq_bind (playSock, ['tcp://*:' num2str(ZEROMQ_PORT_PLAY)]);
  

global cmdFileRec = genDataPath(CMD_FILE_REC);
global cmdFilePlay = genDataPath(CMD_FILE_PLAY);

global fs = 48000;
global freq = 3000;

global WIDTH = 1000;
global HEIGHT = 600;

global DIR_PANEL_REL_WIDTH = 0.4;

global doQuit = false;

function doExit(fig)
  global doQuit;
  doQuit = true;
endfunction

% create figure and panel on it
fig = figure("toolbar", "none", "menubar", "none",  'position', [100, 100, WIDTH, HEIGHT]);
set(fig, 'DeleteFcn', @(h, e) doExit(fig));

playStruct = drawDirPanel(fig, 0, DIR_PANEL_REL_WIDTH, "Play");
recStruct = drawDirPanel(fig, (1 - DIR_PANEL_REL_WIDTH), DIR_PANEL_REL_WIDTH, "Capture");
drawMidPanel(fig, DIR_PANEL_REL_WIDTH, (1 - 2*DIR_PANEL_REL_WIDTH));

% queue for schedItems
global schedQueue = cell();

recInfo = [];
playInfo = [];
% loop until doQuit, waiting for client infos
while (~doQuit)
  % process scheduled callbacks, if any applicable at this time
  % callbacks can use received info structures
  runScheduled(recInfo, playInfo);
  
  recInfo = rcvInfo(recSock);
  if isempty(recInfo)
    printf('Empty rec info\n');
  else
    processInfo(recInfo, recStruct);
  endif

  playInfo = rcvInfo(playSock);
  if isempty(playInfo)
    printf('Empty play info\n');
  else
    processInfo(playInfo, playStruct);
  endif

  drawnow();
endwhile