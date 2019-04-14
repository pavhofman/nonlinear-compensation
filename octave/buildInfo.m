% building info struct from global variables
function info = buildInfo()
  info = struct();
  global statusStruct;
  global measuredPeaks;
  global distortPeaks;

  global fs;
  global direction;
  global cmdDoneID;
  global compenCalFiles;
  global reloadCalFiles;
  global sourceStruct;
  global sinkStruct;
  global showFFTCfg;
  

  info.id = NA;
  info.time = time();
  
  info.status = statusStruct;
  for [val, statusItem ] = statusStruct
    info = addStatusDetails(statusItem, info);
  endfor
  
  info.measuredPeaks = measuredPeaks;
  info.distortPeaks = distortPeaks;
  info.compenCalFiles = compenCalFiles;
  info.reloadCalFiles = reloadCalFiles;
  
  info.sourceStruct = sourceStruct;
  info.sinkStruct = sinkStruct;
  
  info.showingFFT = showFFTCfg.enabled;

  info.fs = fs;
  info.cmdDoneID = cmdDoneID;
  info.direction = direction;
endfunction


% adding details for each status item, if any
function info = addStatusDetails(status, info)
  global GENERATING;
  global CALIBRATING;
  global DISTORTING;
  
  switch status
    case GENERATING
      global genFunds;
      info.genFunds = genFunds;
      
    case CALIBRATING
      global calRequest;
      info.calRequest = calRequest;

    case DISTORTING
      global distortHarmLevels;
      info.distortHarmLevels = distortHarmLevels;
      
  endswitch
endfunction