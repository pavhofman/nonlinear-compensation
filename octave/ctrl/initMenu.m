function [playStruct, recStruct] = initMenu(fig, playStruct, recStruct);
  global cmdFileRec;
  global cmdFilePlay;

  playStruct = initDirMenu(fig, playStruct, cmdFilePlay, '&Playback', 'Playback');
  recStruct = initDirMenu(fig, recStruct, cmdFileRec, '&Capture', 'Capture');
  
  tasksMenu = uimenu (fig, "label", "&Tasks");
  
  uimenu(tasksMenu, "label", "Calibrate Complete Split", 'callback', @clbkSplitCalibrate);
  recStruct.calSingleMenu = uimenu(tasksMenu, "label", "Calibrate Joint-Sides: Single Run", 'separator', 'on', "callback", {@clbkCalib, false});
  recStruct.calContMenu = uimenu(tasksMenu, "label", "Calibrate Joint-Sides: Continuously", "callback", {@clbkCalib, true});
  recStruct.calOffMenu = uimenu(tasksMenu, "label", "Stop Calibrating", 'enable', 'off', "callback", @clbkCalibOff);
  
  uimenu(tasksMenu, "label", "Calibrate VD Freqs", 'callback', @clbkCalibrateFreqs);
endfunction


function clbkCalibrateFreqs(src, data)
  % calling scheduler-enabled calibration
  calibrateFreqsSched();
endfunction

function clbkSplitCalibrate(src, data)
  % calling scheduler-enabled calibration
  splitCalibrateSched();
endfunction

function dirStruct = initDirMenu(fig, dirStruct, cmdFile, label, sideName)
  global COMPENSATE;
  global PASS;
  global DISTORT;
  global GENERATE;
  global READFILE;
  global RECORD;
  global STORE_RECORDED;
  global SHOW_FFT;
  global DIR_REC;
  global COMP_TYPE_JOINT;
  global CMD_COMP_TYPE_PREFIX;
  
  fCmd = @(src, data, cmd, cmdFile) writeCmd(cmd, cmdFile);

  menu = uimenu (fig, "label", label);
  uimenu(menu, "label", "Pass", "callback", {fCmd, PASS, cmdFile});
  
  if (dirStruct.dir == DIR_REC)
    global COMP_TYPE_REC_SIDE;
    compType = COMP_TYPE_REC_SIDE;
  else
    global COMP_TYPE_PLAY_SIDE;
    compType = COMP_TYPE_PLAY_SIDE;
  endif
  uimenu(menu, "label", ['Compensate Split ' sideName], "callback", {fCmd, [COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(compType)], cmdFile});
  
  uimenu(menu, "label", 'Compensate Joint-Sides', "callback", {fCmd, [COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_JOINT)], cmdFile});

  uimenu(menu, "label", "Generate", 'separator', 'on', "callback", {@clbkGenerate, ['Generate on ' sideName ' Side'], cmdFile});
  dirStruct.genOffMenu = uimenu(menu, "label", "Stop Generating", 'enable', 'off', "callback", {@clbkCmdOff, GENERATE, cmdFile});  

  dirStruct.distortOnMenu = uimenu(menu, "label", "Distort", "callback", {@clbkDistort, ['Distort on ' sideName ' Side'], cmdFile});
  dirStruct.distortOffMenu = uimenu(menu, "label", "Stop Distorting", 'enable', 'off', "callback", {@clbkCmdOff, DISTORT, cmdFile});

  dirStruct.readfileMenu = uimenu(menu, "label", "Read from Audiofile", 'separator', 'on', "callback", {@clbkReadFile, cmdFile});
  dirStruct.readfileOffMenu = uimenu(menu, "label", "Stop File Reading", 'enable', 'off', "callback", {@clbkCmdOff, READFILE, cmdFile});

  dirStruct.recordMenu = uimenu(menu, "label", "Start Recording to Memory", 'separator', 'on', "callback", {fCmd, RECORD, cmdFile});
  dirStruct.recordOffMenu = uimenu(menu, "label", "Stop Recording", 'enable', 'off', "callback", {@clbkCmdOff, RECORD, cmdFile});
  dirStruct.storeRecordedMenu = uimenu(menu, "label", "Store Recording to File", 'enable', 'off', "callback", {@clbkStoreRec, cmdFile});

  dirStruct.fftMenu = uimenu(menu, "label", "Show FFT Chart", 'separator', 'on', "callback", {fCmd, SHOW_FFT, cmdFile});
  dirStruct.fftOffMenu = uimenu(menu, "label", "Close FFT Chart", 'enable', 'off', "callback", {@clbkCmdOff, SHOW_FFT, cmdFile});
  
endfunction