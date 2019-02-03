% building info struct from global variables
function info = buildInfo()
  info = struct();
  global status;
  global measuredPeaks;
  global fundPeaks;
  global distortPeaks;

  global fs;
  global direction;
  global cmdDoneID;

  info.id = NA;
  info.time = time();
  
  info.status = status;
  for id = 1: length(status)
    statusItem = status(id);
    info = addStatusDetails(statusItem, info);
  endfor
  
  info.measuredPeaks = measuredPeaks;
  info.fundPeaks = fundPeaks;
  info.distortPeaks = distortPeaks;

  info.fs = fs;
  info.cmdDoneID = cmdDoneID;
  info.direction = direction;
endfunction


% adding details for each status item, if any
function info = addStatusDetails(status, info)
  global GENERATING;
  switch status
    case GENERATING
      global genAmpl;
      info.genAmpl = genAmpl;
      global genFreq;
      info.genFreq = genFreq;
  endswitch
endfunction