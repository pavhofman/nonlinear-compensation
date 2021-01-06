% converting dev names from config files to dev IDs in playrecConfig + determining the other-side main device ID

playRecConfig.recDeviceID = getPlayrecDevID(playRecConfig.recDevice, false);
playRecConfig.playDeviceID = getPlayrecDevID(playRecConfig.playDevice, true);
% storing executive device to file
mainDevID = ifelse(direction == DIR_PLAY, playRecConfig.playDeviceID, playRecConfig.recDeviceID);
save(getDevIDFilepath(direction), 'mainDevID');

% Must be a function since playRecConfig is global because the function requires the load() function to create local disposable playRecConfig variable
function devName = readOtherDevFromConfig(direction)
  global DIR_PLAY;
  global confDir;
  % must be LOCAL playRecConfig, used only for reading the conf file here
  playRecConfig = struct();
  if direction == DIR_PLAY
    % the other side
    source(sprintf('%s%sconfigRec.conf', confDir, filesep()));
    devName = playRecConfig.recDevice;
  else
    source(sprintf('%s%sconfigPlay.conf', confDir, filesep()));
    devName = playRecConfig.playDevice;
  end
end

% Reading executive device ID from the other side
% The other side ID is read from other dev ID file created by the other side.
% If the file does not exist yet, trying to read devname from the config + conversion to ID by playrec.
% If playrec does not know the ID (e.g. the device is already open), throwing error to quit.

try
  load(getDevIDFilepath(ifelse(direction == DIR_PLAY, DIR_REC, DIR_PLAY)));
  playRecConfig.otherDeviceID = mainDevID;
catch err
  writeLog('DEBUG', 'Failed reading other-side main device ID, the device is probably already used, trying main dev file of the other side')
  % trying from the other-side config
  otherDev = readOtherDevFromConfig(direction);
  % converting to device ID - needs which may be missing the already open device.
  playRecConfig.otherDeviceID = getPlayrecDevID(otherDev, direction == DIR_REC);
  % if playrec list does not contain the ID, we cannot continue anyway, no reason to catch an error thrown by getPlayrecDevID
end
