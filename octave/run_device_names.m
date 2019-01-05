% script defines global device names, requires loaded config.m files
global deviceName;
if exist('wavPath', 'var') && !isempty(wavPath)
    [wavDir, wavName, wavExt] = fileparts(wavPath);
    deviceName = [wavName wavExt];
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

global jointDeviceName = [DEVICE_REC_PREFIX num2str(inputDeviceID) '_' DEVICE_PLAY_PREFIX num2str(outputDeviceID)];
