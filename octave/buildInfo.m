% building info struct from global variables
function info = buildInfo()
  info = struct();
  global status;
  global measuredPeaks;
  global fundPeaks;
  global distortPeaks;
  global genAmpl;
  global genFreq;
  global fs;
  global direction;

  info.id = NA;
  info.time = time();
  info.status = status;
  info.measuredPeaks = measuredPeaks;
  info.fundPeaks = fundPeaks;
  info.distortPeaks = distortPeaks;
  info.genAmpl = genAmpl;
  info.genFreq = genFreq;
  info.fs = fs;
  info.direction = direction;
endfunction