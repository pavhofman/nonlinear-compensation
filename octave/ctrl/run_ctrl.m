global cmdFileRec = genDataPath(CMD_FILE_REC);
global cmdFilePlay = genDataPath(CMD_FILE_PLAY);

% create figure and panel on it
f = figure("toolbar", "none", "menubar", "none",  'position', [100, 100, 800, 600]);
% create a button (default style)
b1 = uicontrol (f, "string", "Measure Filter", "position",[10 200 100 30], 'callback', @clbkMeasureFilter);
b2 = uicontrol (f, "string", "Calibrate Freqs", "position",[10 160 100 30], 'callback', @clbkCalibrateFreqs);

global outBox = uicontrol (f, "style", "edit", "position",[150 160 300 200]);
% outbox requires configuration
set(outBox, 'horizontalalignment', 'left');
set(outBox, 'verticalalignment', 'top');
set(outBox, 'max', 1000);

uiwait(f);