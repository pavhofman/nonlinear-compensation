% configuring global variables used calibration calfiles names
global inputDeviceName;
global outputDeviceName;
global jointDeviceName;

sourceFile = sourceStruct.file;
if ~isempty(sourceFile)
  % input file
  filename = getBasename(sourceFile);
  inputDeviceName = [DEVICE_REC_PREFIX num2str(filename)];
  outputDeviceName = inputDeviceName;
  jointDeviceName = inputDeviceName;
else
  % playrec devices - used by calibration/compensation, ids correspond to REC side
  if direction == DIR_REC
    outputDeviceID = playRecConfig.playDeviceID;
    inputDeviceID = playRecConfig.recDeviceID;
   else
    % PLAY side - devices are flipped
    outputDeviceID = playRecConfig.recDeviceID;
    inputDeviceID = playRecConfig.playDeviceID;
   endif

  inputDeviceName = [DEVICE_REC_PREFIX num2str(inputDeviceID)];
  outputDeviceName = [DEVICE_PLAY_PREFIX num2str(outputDeviceID)];
  jointDeviceName = [DEVICE_REC_PREFIX num2str(inputDeviceID) '_' DEVICE_PLAY_PREFIX num2str(outputDeviceID)];
endif