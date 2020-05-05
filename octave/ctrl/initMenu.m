function [playStruct, recStruct] = initMenu(fig, playStruct, recStruct);
  global cmdFileRec;
  global cmdFilePlay;
  
  [playStruct, calOnMenusPlay, calOffMenusPlay] = initDirMenu(fig, playStruct, cmdFilePlay, '&Playback', 'Playback');  
  [recStruct, calOnMenusRec, calOffMenusRec] = initDirMenu(fig, recStruct, cmdFileRec, '&Capture', 'Capture');

  calOnMenusTasks = cell();
  calOffMenusTasks = cell();

  tasksMenu = uimenu (fig, "label", "&Tasks");
  
  uimenu(tasksMenu, "label", "Re-Measure LPF/VD Transfer", 'separator', 'on', 'callback', @clbkRemeasureTransfers);
  
  calOnMenusTasks{end+1} = uimenu(tasksMenu, "label", "Calibrate Joint-Sides: Single Run", 'separator', 'on', "callback", {@clbkJointCalib, false});
  calOnMenusTasks{end+1} = uimenu(tasksMenu, "label", "Calibrate Joint-Sides: Continuously", "callback", {@clbkJointCalib, true});
  calOffMenusTasks{end+1} = uimenu(tasksMenu, "label", "Stop Calibrating", 'separator', 'on', 'enable', 'off', "callback", @clbkCalibOff);
  
  % array of menu items related to calibration start/stop - used to enable/disable all at once
  recStruct.calOnMenus = [cell2mat(calOnMenusPlay), cell2mat(calOnMenusRec), cell2mat(calOnMenusTasks)];
  recStruct.calOffMenus = [cell2mat(calOffMenusPlay), cell2mat(calOffMenusRec), cell2mat(calOffMenusTasks)];
endfunction


function clbkRemeasureTransfers(src, data)
  global maxTransferAge;
  % deleting all transfers first (automatically in getMissingTransferFreqs()) - UGLY
  maxTransferAge = 0;
  % calling scheduler-enabled calibration
  measureTransferSched();
endfunction

function [dirStruct, calOnMenus, calOffMenus] = initDirMenu(fig, dirStruct, cmdFile, label, sideName)
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
  calOnMenus = cell();
  calOffMenus = cell();

  menu = uimenu (fig, "label", label);
  uimenu(menu, "label", "Pass", "callback", {fCmd, PASS, cmdFile});
  
  if dirStruct.dir == DIR_REC
    global COMP_TYPE_REC_SIDE;
    compType = COMP_TYPE_REC_SIDE;
  else
    global COMP_TYPE_PLAY_SIDE;
    compType = COMP_TYPE_PLAY_SIDE;
  endif
  uimenu(menu, "label", ['Compensate Only ' sideName], "callback", {fCmd, [COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(compType)], cmdFile});
  
  if dirStruct.dir == DIR_REC
    calOnMenus{end+1} = uimenu(menu, "label", ['Exact-Level Calibrate Capture Side'], 'separator', 'on', "callback", @clbkExactCalibRec);
    calOnMenus{end+1} = uimenu(menu, "label", ['Range-Calibrate Capture Side'], 'separator', 'on', "callback", @clbkRangeCalibRec);
  else
    calOnMenus{end+1} = uimenu(menu, "label", ['Split-Calibrate Playback Side'], 'separator', 'on', "callback", @clbkSplitCalibPlay);
  endif
  
  uimenu(menu, "label", 'Compensate Joint-Sides', 'separator', 'on', "callback", {fCmd, [COMPENSATE ' ' CMD_COMP_TYPE_PREFIX num2str(COMP_TYPE_JOINT)], cmdFile});  
  calOnMenus{end+1} = uimenu(menu, "label", ['Calibrate Only ' sideName ': Single Run'], 'separator', 'on', "callback", {@clbkCalib, compType, false});
  calOnMenus{end+1} = uimenu(menu, "label", ['Calibrate Only ' sideName ': Continuously'], "callback", {@clbkCalib, compType, true});
  calOffMenus{end+1} = uimenu(menu, "label", "Stop Calibrating", 'enable', 'off', "callback", @clbkCalibOff);
  
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