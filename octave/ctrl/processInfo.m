function processInfo(info, dirStruct)
  %info.id = NA;
  %info.time = time();
  %info.status = status;
  %info.measuredPeaks = measuredPeaks;
  %info.fundPeaks = fundPeaks;
  %info.distortPeaks = distortPeaks;
  %info.genAmpl = genAmpl;
  %info.genFreq = genFreq;
  %info.fs = fs;
  %info.direction = direction;
    
  set(dirStruct.statusTxt, 'string', getStatusString(info));
  disp(info);  
endfunction

function str = getStatusString(info)
  str = cell();
  for id = 1:length(info.status)
    status = info.status(id);
    str{end + 1} = getSingleStatusString(info, status);
  endfor  
endfunction

% formatting string for each status
function str = getSingleStatusString(info, status)
  global STATUS_NAMES;
  global GENERATING;
  str = STATUS_NAMES{status};
  
  switch(status)
    case GENERATING
      str = [str ' ' int2str(info.genFreq) 'Hz' ' @ ' num2str(20*log10(info.genAmpl)) 'dB'];
  endswitch
  
endfunction
