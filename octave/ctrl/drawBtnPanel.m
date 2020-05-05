function drawBtnPanel(fig, x, y, width, height)
  btnPanel = uipanel(fig,
              'title', 'Run',
              "position", [x, y, width, height]);

  global loopSplitCalib = false;

  CLEARANCE = 0.01;
  LOOP_CHCKBX_X = 0.03;
  LOOP_CHCKBX_WIDTH = 0.24;

  BTN_Y = 0.1;
  BTN_WIDTH = 0.35;
  BTN_HEIGHT = 0.8;
  loopSplitCalibCheckbox = uicontrol (btnPanel,
                             'style', 'checkbox',
                             'units', 'normalized',
                             'string', 'Loop',
                             'value', 0,
                             'verticalalignment', 'middle',
                             'callback', @clbkLoopSplitCalib,
                             'position', [LOOP_CHCKBX_X, 0, LOOP_CHCKBX_WIDTH, 1]);


  global splitCalibBtn;
  splitBtnX = LOOP_CHCKBX_X + LOOP_CHCKBX_WIDTH + CLEARANCE;
  splitCalibBtn = uicontrol (btnPanel,
                                  'style', 'pushbutton',
                                  'units', 'normalized',
                                  'string', "Split-Calib\nPlayback",
                                  'verticalalignment', 'middle',
                                  'horizontalalignment', 'center',
                                  %'backgroundcolor', 'yellow',
                                  'callback', @clbkSplitCalibPlay,
                                  'position', [splitBtnX,  BTN_Y, BTN_WIDTH, BTN_HEIGHT]);

  global rangeCalibRecBtn;
  rangeCalibRecBtn = uicontrol (btnPanel,
                                  'style', 'pushbutton',
                                  'units', 'normalized',
                                  'string', "Exact-Calib\nCapture",
                                  'verticalalignment', 'middle',
                                  'horizontalalignment', 'center',
                                  %'backgroundcolor', 'yellow',
                                  'callback', @clbkExactCalibRec,
                                  'position', [splitBtnX + BTN_WIDTH + CLEARANCE,  BTN_Y, BTN_WIDTH, BTN_HEIGHT]);
endfunction

function clbkLoopSplitCalib(src, data)
  % just setting the global variable
  global loopSplitCalib;
  loopSplitCalib = get(src, 'value');
endfunction
