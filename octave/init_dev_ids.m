% converting dev names from config files to dev IDs in playrecConfig + determining the other-side main device ID

playRecConfig.recDeviceID = getPlayrecDevID(playRecConfig.recDevice, false);
playRecConfig.playDeviceID = getPlayrecDevID(playRecConfig.playDevice, true);
% storing executive device to file
mainDevID = ifelse(direction == DIR_PLAY, playRecConfig.playDeviceID, playRecConfig.recDeviceID);
save(getDevIDFilepath(direction), 'mainDevID');

% must be a function since playRecConfig is global
function devName = readOtherDevFromConfig(direction)
  global DIR_PLAY;
  % must be LOCAL playRecConfig, used only for reading the conf file here
  playRecConfig = struct();
  if direction == DIR_PLAY
    % the other side
    source 'configRec.m'
    devName = playRecConfig.recDevice;
  else
    source 'configPlay.m'
    devName = playRecConfig.playDevice;
  endif
endfunction

% reading executive device ID from the other side
% Playrec does not list devices being already used. When the other side has its main device already open,
% function readOtherDevFromConfig() will throw an error
% and other side ID must be read from other dev ID file created by the other side.

% first trying from the other-side config
otherDev = readOtherDevFromConfig(direction);
try
  % converting to device ID - needs playrec list which may be missing the already open device.
  playRecConfig.otherDeviceID = getPlayrecDevID(otherDev, direction == DIR_REC);
catch err
  writeLog('DEBUG', 'Failed reading other-side main device ID, the device is probably already used, trying main dev file of the other side')
  % if the file does not exist, we cannot continue anyway, no reason to catch any error here
  load(getDevIDFilepath(ifelse(direction == DIR_PLAY, DIR_REC, DIR_PLAY)));
  playRecConfig.otherDeviceID = mainDevID;
end_try_catch
