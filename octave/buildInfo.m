% building info struct from global variables
function info = buildInfo(channelCnt, statusStruct, measuredPeaks, distortPeaks, fs, direction, cmdDoneID, compenCalFiles, reloadCalFiles,
    sourceStruct, sinkStruct, showFFTCfg, chMode, equalizer, nonInteger, playCalDevName, recCalDevName)
  info = struct();

  info.id = NA;
  info.time = time();

  info.channelCnt = channelCnt;
  info.status = statusStruct;
  for [val, statusItem ] = statusStruct
    info = addStatusDetails(statusItem, info);
  end
  
  info.chMode = chMode;
  info.equalizer = equalizer;
  
  info.measuredPeaks = measuredPeaks;
  info.distortPeaks = distortPeaks;
  info.compenCalFiles = compenCalFiles;
  info.reloadCalFiles = reloadCalFiles;
  
  info.sourceStruct = sourceStruct;
  info.sinkStruct = sinkStruct;

  info.playCalDevName = playCalDevName;
  info.recCalDevName = recCalDevName;

  info.showingFFT = showFFTCfg.enabled;

  info.fs = fs;
  info.cmdDoneID = cmdDoneID;
  info.nonInteger = nonInteger;
  info.direction = direction;
  % current process PID is needed for restarting/monitoring from CTRL
  info.pid = getpid();
end


% adding details for each status item, if any
function info = addStatusDetails(status, info)
  global GENERATING;
  global CALIBRATING;
  global DISTORTING;
  global COMPENSATING;
  
  switch status
    case GENERATING
      global genFunds;
      info.genFunds = genFunds;
      
    case CALIBRATING
      global calRequest;
      info.calRequest = calRequest;

    case COMPENSATING
      global compRequest;
      info.compRequest = compRequest;
      
    case DISTORTING
      global distortHarmAmpls;
      info.distortHarmAmpls = distortHarmAmpls;
      
  endswitch
end