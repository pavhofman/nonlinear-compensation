function [playStruct, recStruct] = initMenu(fig, playStruct, recStruct);
  global cmdFileRec;
  global cmdFilePlay;

  playStruct = initDirMenu(fig, playStruct, cmdFilePlay, '&Playback', 'Playback');
  recStruct = initDirMenu(fig, recStruct, cmdFileRec, '&Capture', 'Capture');
  
  tasksMenu = uimenu (fig, "label", "&Tasks");
  
  uimenu(tasksMenu, "label", "Split-Calibrate", 'callback', @clbkSplitCalibrate);
  uimenu(tasksMenu, "label", "Calibrate VD Freqs", 'callback', @clbkCalibrateFreqs);
  uimenu(tasksMenu, "label", "Joint-Dev. Compen. VD", 'callback', @clbkCompenVD);
  uimenu(tasksMenu, "label", "Joint-Dev. Compen. LPF", 'callback', @clbkCompenLPF);
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
  
  fCmd = @(src, data, cmd, cmdFile) writeCmd(cmd, cmdFile);

  menu = uimenu (fig, "label", label);
  uimenu(menu, "label", "Pass", "callback", {fCmd, PASS, cmdFile});
  uimenu(menu, "label", "Compensate", "callback", {fCmd, COMPENSATE, cmdFile});
  if (dirStruct.dir == DIR_REC)
    dirStruct.calSingleMenu = uimenu(menu, "label", "Calibrate Single Run", "callback", {@clbkCalib, false});
    dirStruct.calContMenu = uimenu(menu, "label", "Calibrate Continuously", "callback", {@clbkCalib, true});
    dirStruct.calOffMenu = uimenu(menu, "label", "Stop Calibrating", 'visible', 'off', "callback", @clbkCalibOff);
  endif
  uimenu(menu, "label", "Generate", 'separator', 'on', "callback", {@clbkGenerate, ['Generate on ' sideName ' Side'], cmdFile});
  dirStruct.genOffMenu = uimenu(menu, "label", "Stop Generating", 'visible', 'off', "callback", {@clbkCmdOff, GENERATE, cmdFile});  

  dirStruct.distortOnMenu = uimenu(menu, "label", "Distort", "callback", {@clbkDistort, ['Distort on ' sideName ' Side'], cmdFile});
  dirStruct.distortOffMenu = uimenu(menu, "label", "Stop Distorting", 'visible', 'off', "callback", {@clbkCmdOff, DISTORT, cmdFile});

  dirStruct.readfileMenu = uimenu(menu, "label", "Read from Audiofile", 'separator', 'on', "callback", {@clbkReadFile, cmdFile});
  dirStruct.readfileOffMenu = uimenu(menu, "label", "Stop File Reading", 'enable', 'off', "callback", {@clbkCmdOff, READFILE, cmdFile});

  dirStruct.recordMenu = uimenu(menu, "label", "Start Recording to Memory", 'separator', 'on', "callback", {fCmd, RECORD, cmdFile});
  dirStruct.recordOffMenu = uimenu(menu, "label", "Stop Recording", 'enable', 'off', "callback", {@clbkCmdOff, RECORD, cmdFile});
  dirStruct.storeRecordedMenu = uimenu(menu, "label", "Store Recording to File", 'enable', 'off', "callback", {@clbkStoreRec, cmdFile});

  dirStruct.fftMenu = uimenu(menu, "label", "Show FFT Chart", 'separator', 'on', "callback", {fCmd, SHOW_FFT, cmdFile});
  dirStruct.fftOffMenu = uimenu(menu, "label", "Close FFT Chart", 'enable', 'off', "callback", {@clbkCmdOff, SHOW_FFT, cmdFile});
  
endfunction