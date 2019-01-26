pkg load zeromq;
pkg load database;

more off;

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

% create figure and panel on it
f = figure("toolbar", "none", "menubar", "none",  'position', [100, 100, 800, 600]);

btnWidth = 250;
yPos = 500;
uicontrol (f, "string", "Calibrate VD Freqs", "position",[10 yPos btnWidth 30], 'callback', @clbkCalibrateFreqs);

yPos -= 40;
uicontrol (f, "string", "Joint-Device Compensate VD", "position",[10 yPos btnWidth 30], 'callback', @clbkCompenVD);

yPos -= 40;
uicontrol (f, "string", "Calibrate LPF", "position",[10 yPos btnWidth 30], 'callback', @clbkCalibrateLPF);

yPos -= 40;
uicontrol (f, "string", "Joint-Device Compensate LPF", "position",[10 yPos btnWidth 30], 'callback', @clbkCompenLPF);

yPos -= 40;
uicontrol (f, "string", "Measure Filter", "position",[10 yPos btnWidth 30], 'callback', @clbkMeasureFilter);

yPos -= 40;
uicontrol (f, "string", "Split Calibration", "position",[10 yPos btnWidth 30], 'callback', @clbkSplitCalibrate);

yPos -= 40;
uicontrol (f, "string", "Split-Device Compensate Each Side", "position",[10 yPos btnWidth 30], 'callback', @clbkSplitCompen);


global outBox = uicontrol (f, "style", "edit", "position",[300 10 400 500]);
% outbox requires configuration
set(outBox, 'horizontalalignment', 'left');
set(outBox, 'verticalalignment', 'top');
set(outBox, 'max', 1000);


%fp = plot(x, 20*log10([0.9 0.8 0.7 0.65 0.6 ]), '>r', 'markerfacecolor', 'r');
%set(gca,'Xtick',[])


% loop forever, waiting for client infos
while (true)
  recInfo = rcvInfo(recSock);
  disp(recInfo);
  playInfo = rcvInfo(playSock);
  disp(playInfo);
endwhile
