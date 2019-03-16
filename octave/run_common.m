% script runs common code for mainRec/Play and mainCtrl. Defines global device names, creates required dirs, etc.
% Requires loaded config.m files


if !exist(dataDir, 'dir')
  mkdir(dataDir);
endif


global deviceName;

if exist('sourceFile', 'var') && !isempty(sourceFile)
    deviceName = getBasename(sourceFile);
else
    global playRecConfig;
    if (direction == DIR_PLAY)
      deviceName = [DEVICE_PLAY_PREFIX num2str(playRecConfig.playDeviceID)];
      % output/input device IDs - needed for storing calib files
      outputDeviceID = playRecConfig.playDeviceID;
      inputDeviceID = playRecConfig.otherDirectionDeviceID;
    else
      deviceName = [DEVICE_REC_PREFIX num2str(playRecConfig.recDeviceID)];
      outputDeviceID = playRecConfig.otherDirectionDeviceID;
      inputDeviceID = playRecConfig.recDeviceID;      
    endif
end

global inputDeviceName = [DEVICE_REC_PREFIX num2str(inputDeviceID)];
global outputDeviceName = [DEVICE_PLAY_PREFIX num2str(outputDeviceID)];
global jointDeviceName = [DEVICE_REC_PREFIX num2str(inputDeviceID) '_' DEVICE_PLAY_PREFIX num2str(outputDeviceID)];
