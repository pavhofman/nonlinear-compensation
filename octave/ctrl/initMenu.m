function [playStruct, recStruct] = initMenu(fig, playStruct, recStruct);
  global cmdFileRec;
  global cmdFilePlay;
  
  [playStruct, calOnMenusPlay, calOffMenusPlay] = initDirMenu(fig, playStruct, cmdFilePlay, '&Playback', 'Playback');  
  [recStruct, calOnMenusRec, calOffMenusRec] = initDirMenu(fig, recStruct, cmdFileRec, '&Capture', 'Capture');

  calOnMenusTasks = cell();
  calOffMenusTasks = cell();

  jointSidesMenu = uimenu (fig, "label", "&Joint Sides");
  
  calOnMenusTasks{end+1} = uimenu(jointSidesMenu, "label", "Calibrate Joint-Sides: Single Run", "callback", {@clbkJointCalib, false});
  calOnMenusTasks{end+1} = uimenu(jointSidesMenu, "label", "Calibrate Joint-Sides: Continuously", "callback", {@clbkJointCalib, true});
  calOffMenusTasks{end+1} = uimenu(jointSidesMenu, "label", "Stop Calibrating", 'separator', 'on', 'enable', 'off', "callback", @clbkCalibOff);

  uimenu(jointSidesMenu, "label", "Re-Measure LPF/VD Transfer", 'separator', 'on', 'callback', @clbkRemeasureTransfers);


  controlMenu = uimenu (fig, "label", "C&ontrol");
  uimenu(controlMenu, "label", 'Delete all calibration files', "callback", @clbkDeleteCalFiles);

  uimenu(controlMenu, "label", 'View logs for Control', 'separator', 'on', "callback", {@clbkViewLogfile, 'ctrl'});
  uimenu(controlMenu, "label", 'Restart Control', "callback", @(src, data) killProcess(getpid(), 'Control'));
  % TERM signal
  uimenu(controlMenu, "label", 'Quit all CleanSine processes', "callback", @(src, data) kill(getppid(), 15));

  aboutMenu = uimenu (fig, "label", "&About");
  uimenu(aboutMenu, "label", 'View GIT version', "callback", @clbkViewVersion);
  uimenu(aboutMenu, "label", 'Update to latest GIT version', "callback", @clbkUpdateGit);
  % array of menu items related to calibration start/stop - used to enable/disable all at once
  recStruct.calOnMenus = [cell2mat(calOnMenusPlay), cell2mat(calOnMenusRec), cell2mat(calOnMenusTasks)];
  recStruct.calOffMenus = [cell2mat(calOffMenusPlay), cell2mat(calOffMenusRec), cell2mat(calOffMenusTasks)];
endfunction

function clbkDeleteCalFiles(src, data)
  global dataDir;
  files = glob([dataDir filesep() '*.dat']);
  for idx = 1:length(files)
    filename = files{idx};
    writeLog('DEBUG', 'Deleting calibration file %s', filename);
    delete(filename);
  endfor
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

  uimenu(menu, "label", ['View logs for ' sideName], 'separator', 'on', "callback", {@clbkViewLogfile, ifelse(dirStruct.dir == DIR_REC, 'rec', 'play')});
  uimenu(menu, "label", ['Edit config file for ' sideName], "callback", {@clbkEditConfig, ifelse(dirStruct.dir == DIR_REC, 'Rec', 'Play')});
  uimenu(menu, "label", ['Restart ' sideName ' process'], "callback", {@clbkKillSide, dirStruct.dir, sideName});
endfunction

% killing process PLAY or REC
function clbkKillSide(src, data, direction, sideName)
  global DIR_PLAY;

  if direction == DIR_PLAY
    global playInfo;
    pid = playInfo.pid;
  else
    global recInfo;
    pid = recInfo.pid;
  endif
  killProcess(pid, sideName);
endfunction

% killing process PLAY or REC
function killProcess(pid, sideName)
  % TERM
  persistent SIGNAL = 15;

  writeLog('DEBUG', 'Sending signal %d to process %s', SIGNAL, sideName);
  kill(pid, SIGNAL);
endfunction

function clbkViewLogfile(src, data, logName)
  global logDir;

  open(sprintf("%s%s%s.log", logDir, filesep(), logName));
endfunction

function clbkEditConfig(src, data, dirSuffix)
  global currDir;

  open(sprintf("%s%sconfig%s.conf", currDir, filesep(), dirSuffix));
endfunction

function clbkViewVersion(src, data)
  global binDir;
  persistent TMP_FILE = "/tmp/cleansine_version.txt";

  gitCmd = sprintf("%s%sgit_version.sh > %s 2>&1", binDir, filesep(), TMP_FILE);
  system (gitCmd);
  open(TMP_FILE);
endfunction

function clbkUpdateGit(src, data)
  global binDir;
  persistent TMP_FILE = "/tmp/git_update_output.txt";

  gitCmd = sprintf("%s%sgit_update.sh > %s  2>&1", binDir, filesep(), TMP_FILE);
  system (gitCmd);
  open(TMP_FILE);
endfunction
