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
  %info.cmdDoneID
  %info.direction = direction;
  
  %dirStruct.statusTxt = NA;
  %dirStruct.detailTxts = cell(2);

  [statusStr, detailsCh1, detailsCh2] = getStatusesStrings(info);
  set(dirStruct.statusTxt, 'string', statusStr);
  set(dirStruct.detailTxts{1}, 'string', detailsCh1);
  set(dirStruct.detailTxts{2}, 'string', detailsCh2);
  
  
  
  disp(info);
endfunction

function [statusStr, detailsCh1, detailsCh2] = getStatusesStrings(info)
  statusStr = cell();
  detailsCh1 = cell();
  detailsCh2 = cell();
  
  statusStruct = info.status;
  
  id = 1;
  for [statusVal, status] = statusStruct
    statusToShow = status;
    if isfield(statusVal, 'result')
      result = statusVal.result;
      if isResultOK(result)
        how = 'OK';
      else
        how = 'BAD';
      endif
      statusToShow = [statusToShow ' ' how];
    endif
    if isfield(statusVal, 'msg')
      statusToShow = [statusToShow ' ' statusVal.msg];
    endif
      
    statusStr{end + 1} = statusToShow;
    detailsCh1 = addDetails(1, status, id, info, detailsCh1);
    detailsCh2 = addDetails(2, status, id, info, detailsCh2);
    ++id;
  endfor  
endfunction

% formatting strings for details of channelID
function details = addDetails(channelID, status, id, info, details)
  global GENERATING;
  global COMPENSATING;
  global ANALYSING;
  
  % empty line before second+ statuses
  if id > 1
    details{end + 1} = '';
  endif
  
  switch(status)
    case GENERATING
      % showing generator freq and amplitude
      details{end + 1} = 'Frequencies:';
      details{end + 1 } = [int2str(info.genFreq) 'Hz ' num2str(20*log10(info.genAmpl), 1) 'dB'];
    
    case COMPENSATING
      details{end + 1} = 'Compen. Distorts:';
      % sorting distortPeaks by amplitude
      peaks = info.distortPeaks{channelID};
      if ~isempty(peaks)
        peaks = sortrows(info.distortPeaks{channelID}, -2);
        details = addPeaksStr(peaks, 1, details);
      endif
      
    case ANALYSING
      details{end + 1} = 'Measured Funds:';
      details = addPeaksStr(info.measuredPeaks{channelID}, 3, details);      
  endswitch
  
endfunction

function str = addPeaksStr(peaksCh, decimals, str)
  format = ['%7.' int2str(decimals) 'f'];
  for id = 1:rows(peaksCh)
    peak = peaksCh(id, :);
    str{end + 1} = ['  ' num2str(peak(1)) 'Hz ' num2str(20*log10(peak(2)), format) 'dB'];
  endfor
endfunction
