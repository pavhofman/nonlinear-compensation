pkg load zeromq;
pkg load database;

more off;

function dirStruct = createDirStruct();
  dirStruct = struct();
  dirStruct.plotPanel = NA;
  dirStruct.ax = NA;
  dirStruct.calPlot = NA;
  dirStruct.measPlot = NA;
  dirStruct.statusTxt = NA;
  dirStruct.fundFreqsTxt = NA;
endfunction

function dirStruct = drawDirPanel(fig, x, width, title)
  panel = uipanel(fig, 
            "title", title,
            "position", [x 0 width 1]);
  plotPanel = uipanel(panel, 
            "title", "", 
            "position", [0.1 0 0.3 0.8]);
  dirStruct = createDirStruct();
  dirStruct.plotPanel = plotPanel;
  
  statusTxt = uicontrol (panel,
            "style", "text",
            "units", "normalized",
            "string", "unknown",
            "horizontalalignment", "left",
            "position", [0.05 0.90 1 0.08]);            
  dirStruct.statusTxt = statusTxt;
endfunction

function clbkCalibrateFreqs(src, data)
  % calling scheduler-enabled calibration
  calibrateFreqsSched();
endfunction

function drawMidPanel(fig, x, width)
  
  midPanel = uipanel(fig, "title", "Common", "position", [x, 0, width, 1]);


  btnWidth = 250;
  global HEIGHT;
  global DIR_PANEL_REL_WIDTH;
  global WIDTH;
  
  yPos = HEIGHT - 50;
  uicontrol (midPanel, "string", "Calibrate VD Freqs", "position",[10 yPos btnWidth 30], 'callback', @clbkCalibrateFreqs);

  yPos -= 40;
  uicontrol (midPanel, "string", "Joint-Device Compensate VD", "position",[10 yPos btnWidth 30], 'callback', @clbkCompenVD);

  yPos -= 40;
  uicontrol (midPanel, "string", "Calibrate LPF", "position",[10 yPos btnWidth 30], 'callback', @clbkCalibrateLPF);

  yPos -= 40;
  uicontrol (midPanel, "string", "Joint-Device Compensate LPF", "position",[10 yPos btnWidth 30], 'callback', @clbkCompenLPF);

  yPos -= 40;
  uicontrol (midPanel, "string", "Measure Filter", "position",[10 yPos btnWidth 30], 'callback', @clbkMeasureFilter);

  yPos -= 40;
  uicontrol (midPanel, "string", "Split Calibration", "position",[10 yPos btnWidth 30], 'callback', @clbkSplitCalibrate);

  yPos -= 40;
  uicontrol (midPanel, "string", "Split-Device Compensate Each Side", "position",[10 yPos btnWidth 30], 'callback', @clbkSplitCompen);


  global outBox = uicontrol (midPanel, "style", "edit", "position",[5, 5, (1-2*DIR_PANEL_REL_WIDTH)*WIDTH - 10, 100]);
  % outbox requires configuration
  set(outBox, 'horizontalalignment', 'left');
  set(outBox, 'verticalalignment', 'top');
  set(outBox, 'max', 1000);

endfunction

function dirStruct = initPlot(dirStruct)
  ax = axes ('parent', dirStruct.plotPanel);
  x = zeros(1, 5);
  dirStruct.calPlot = plot(ax, x, 20*log10([0.9 0.8 0.7 0.65 0.6 ]), '>r', 'markerfacecolor', 'r');
  set(ax,'Xtick',[])
  set (ax, "ygrid", "on");
  set(ax, "outerposition",  [0,0, 1, 1])
  dirStruct.ax = ax;
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

global WIDTH = 800;
global HEIGHT = 600;

global DIR_PANEL_REL_WIDTH = 0.3;

global doQuit = false;

function doExit(fig)
  close(fig);
  global doQuit;
  doQuit = true;
endfunction

% create figure and panel on it
fig = figure("toolbar", "none", "menubar", "none",  'position', [100, 100, WIDTH, HEIGHT]);
set(fig, 'DeleteFcn', @(h, e) doExit(fig));

playStruct = drawDirPanel(fig, 0, DIR_PANEL_REL_WIDTH, "Play");
recStruct = drawDirPanel(fig, (1 - DIR_PANEL_REL_WIDTH), DIR_PANEL_REL_WIDTH, "Capture");
drawMidPanel(fig, DIR_PANEL_REL_WIDTH, (1 - 2*DIR_PANEL_REL_WIDTH));

playStruct = initPlot(playStruct);
recStruct = initPlot(recStruct);

% queue for schedItems
global schedQueue = cell();

% loop until doQuit, waiting for client infos
while (~doQuit)
  % process scheduled callbacks, if any applicable at this time
  runScheduled();
  
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
