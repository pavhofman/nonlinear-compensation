function [playStruct, recStruct] = initMenu(fig, playStruct, recStruct);
  global cmdFileRec;
  global cmdFilePlay;

  playStruct = initDirMenu(fig, playStruct, cmdFilePlay, '&Playback', 'Playback');
  recStruct = initDirMenu(fig, recStruct, cmdFileRec, '&Capture', 'Capture');
  
  tasksMenu = uimenu (fig, "label", "&Tasks");
  
  uimenu(tasksMenu, "label", "Calibrate VD Freqs", 'callback', @clbkCalibrateFreqs);
  uimenu(tasksMenu, "label", "Joint-Dev. Compen. VD", 'callback', @clbkCompenVD);
  uimenu(tasksMenu, "label", "Calibrate LPF", 'callback', @clbkCalibrateLPF);
  uimenu(tasksMenu, "label", "Joint-Dev. Compen. LPF", 'callback', @clbkCompenLPF);
  uimenu(tasksMenu, "label", "Measure Filter", 'callback', @clbkMeasureFilter);
  uimenu(tasksMenu, "label", "Split Calibration", 'callback', @clbkSplitCalibrate);
  uimenu(tasksMenu, "label", "Split-Dev. Compen. Sides", 'callback', @clbkSplitCompen);
endfunction


function clbkCalibrateFreqs(src, data)
  % calling scheduler-enabled calibration
  calibrateFreqsSched();
endfunction

function dirStruct = initDirMenu(fig, dirStruct, cmdFile, label, sideName)
  global COMPENSATE;
  global PASS;
  global DISTORT;
  global GENERATE;
  global DIR_REC;
  
  fPass = @(src, data, cmdFile) writeCmd(PASS, cmdFile);
  fComp = @(src, data, cmdFile) writeCmd(COMPENSATE, cmdFile);

  menu = uimenu (fig, "label", label);
  uimenu(menu, "label", "Pass", "callback", {fPass, cmdFile});
  uimenu(menu, "label", "Compensate", "callback", {fComp, cmdFile});
  if (dirStruct.dir == DIR_REC)
    dirStruct.calSingleMenu = uimenu(menu, "label", "Calibrate Single Run", "callback", {@clbkCalib, false});
    dirStruct.calContMenu = uimenu(menu, "label", "Calibrate Continuously", "callback", {@clbkCalib, true});
    dirStruct.calOffMenu = uimenu(menu, "label", "Stop Calibrating", 'visible', 'off', "callback", @clbkCalibOff);
  endif
  uimenu(menu, "label", "Generate", 'separator', 'on', "callback", {@clbkGenerate, ['Generate on ' sideName ' Side'], cmdFile});
  dirStruct.genOffMenu = uimenu(menu, "label", "Stop Generating", 'visible', 'off', "callback", {@clbkCmdOff, GENERATE, cmdFile});  
  dirStruct.distortOnMenu = uimenu(menu, "label", "Distort", "callback", {@clbkDistort, ['Distort on ' sideName ' Side'], cmdFile});
  dirStruct.distortOffMenu = uimenu(menu, "label", "Stop Distorting", 'visible', 'off', "callback", {@clbkCmdOff, DISTORT, cmdFile});
endfunction