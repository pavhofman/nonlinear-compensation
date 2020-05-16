% configuring global variables used calibration calfiles names
global recCalDevName;
global playCalDevName;

sourceFile = sourceStruct.file;
if ~isempty(sourceFile)
  % input file
  filename = getBasename(sourceFile);
  recCalDevName = [DEVICE_REC_PREFIX num2str(filename)];
  playCalDevName = recCalDevName;
else
  if direction == DIR_REC
    % used by calibration filenames
    recCalDevName = [DEVICE_REC_PREFIX num2str(playRecConfig.recDeviceID)];
    playCalDevName = [DEVICE_PLAY_PREFIX num2str(playRecConfig.otherDeviceID)];
  else
    recCalDevName = [DEVICE_REC_PREFIX num2str(playRecConfig.otherDeviceID)];
    playCalDevName = [DEVICE_PLAY_PREFIX num2str(playRecConfig.playDeviceID)];
  endif
endif