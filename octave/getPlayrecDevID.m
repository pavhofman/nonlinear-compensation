% Reading device ID for the given devName from playrec.
% Note: checks only devices not currently open
% If such devName is not found, error is thrown
function devID = getPlayrecDevID(devName, playback)
  devs = playrec('getDevices');
  for id = 1:length(devs)
    % searching for substring in devices for requested direction
    if index(devs(id).name, devName) && ifelse(playback, devs(id).outputChans, devs(id).inputChans)
      devID = devs(id).deviceID;
      return;
    endif
  endfor
  % not found, probably already open
  msg = sprintf('Unknown closed PlayRec device name %s for %s', devName, ifelse(playback, 'playback', 'capture'));
  writeLog('ERROR', msg);
  error(msg);
endfunction