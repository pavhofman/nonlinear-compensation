% building info struct from global variables
function infoStruct = buildInfo(channelCnt, statusStruct, measuredPeaks, distortPeaks, fs, direction, cmdDoneID, compenCalFiles, reloadCalFiles,
    sourceStruct, sinkStruct, showFFTCfg, chMode, equalizer, nonInteger, playCalDevName, recCalDevName)
  infoStruct = struct();

  infoStruct.id = NA;
  infoStruct.time = time();

  infoStruct.channelCnt = channelCnt;
  infoStruct.status = statusStruct;
  for [val, statusItem ] = statusStruct
    infoStruct = addStatusDetails(statusItem, infoStruct);
  end
  
  infoStruct.chMode = chMode;
  infoStruct.equalizer = equalizer;
  
  infoStruct.measuredPeaks = measuredPeaks;
  infoStruct.distortPeaks = distortPeaks;
  infoStruct.compenCalFiles = compenCalFiles;
  infoStruct.reloadCalFiles = reloadCalFiles;
  
  infoStruct.sourceStruct = sourceStruct;
  infoStruct.sinkStruct = sinkStruct;

  infoStruct.playCalDevName = playCalDevName;
  infoStruct.recCalDevName = recCalDevName;

  infoStruct.showingFFT = showFFTCfg.enabled;

  infoStruct.fs = fs;
  infoStruct.cmdDoneID = cmdDoneID;
  infoStruct.nonInteger = nonInteger;
  infoStruct.direction = direction;
  % current process PID is needed for restarting/monitoring from CTRL
  infoStruct.pid = getpid();
end


% adding details for each status item, if any
function infoStruct = addStatusDetails(status, infoStruct)
  global GENERATING;
  global CALIBRATING;
  global DISTORTING;
  global COMPENSATING;
  
  switch status
    case GENERATING
      global genFunds;
      infoStruct.genFunds = genFunds;
      
    case CALIBRATING
      global calRequest;
      infoStruct.calRequest = calRequest;

    case COMPENSATING
      global compRequest;
      infoStruct.compRequest = compRequest;
      
    case DISTORTING
      global distortHarmAmpls;
      infoStruct.distortHarmAmpls = distortHarmAmpls;
      
  endswitch
end