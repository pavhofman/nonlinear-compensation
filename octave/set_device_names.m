% configuring global variables used calibration calfiles names
global recDeviceName;
global playDeviceName;

sourceFile = sourceStruct.file;
if ~isempty(sourceFile)
  % input file
  filename = getBasename(sourceFile);
  recDeviceName = [DEVICE_REC_PREFIX num2str(filename)];
  playDeviceName = recDeviceName;
else
  if direction == DIR_REC
    % used by calibration filenames
    recDeviceName = [DEVICE_REC_PREFIX num2str(playRecConfig.recDeviceID)];
    playDeviceName = [DEVICE_PLAY_PREFIX num2str(playRecConfig.otherDeviceID)];
  else
    recDeviceName = [DEVICE_REC_PREFIX num2str(playRecConfig.otherDeviceID)];
    playDeviceName = [DEVICE_PLAY_PREFIX num2str(playRecConfig.playDeviceID)];
  endif
endif