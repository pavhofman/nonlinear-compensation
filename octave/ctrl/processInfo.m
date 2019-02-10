function processInfo(info, dirStruct)
  %info.id = NA;
  %info.time = time();
  %info.status = statusStruct;
  %info.measuredPeaks = measuredPeaks;
  %info.fundPeaks = fundPeaks;
  %info.distortPeaks = distortPeaks;
  %info.genAmpl = genAmpl;
  %info.genFreq = genFreq;
  %info.fs = fs;
  %info.cmdDoneID;
  %info.compenCalFiles = compenCalFiles;
  %info.calFreqs;
  %info.direction = direction;
  
  %dirStruct.statusTxt = NA;
  %dirStruct.detailTxts = cell(2);

  
  updateStatusTxts(dirStruct, info);

  [detailsCh1, detailsCh2] = getStatusDetails(info);
  updateFieldString(dirStruct.detailTxts{1}, detailsCh1);
  updateFieldString(dirStruct.detailTxts{2}, detailsCh2);
  
  updatePlots(dirStruct, info);
  disp(info);
endfunction

function updateFieldString(field, newText)
  shownText = get(field, 'string');
  if ~isequal(shownText, newText)
    set(field, 'string', newText);
  endif
endfunction

function updateFieldColor(field, newColor)
  shownColor = get(field, 'foregroundcolor');
  if ~isequal(shownColor, newColor)
    set(field, 'foregroundcolor', newColor);
  endif
endfunction

function updateStatusTxts(dirStruct, info)
  persistent GREEN = [0, 0.5, 0];
  persistent RED = [0.5, 0, 0];
  
  global COMPENSATING;
  statusStr = cell();
  
  statusStruct = info.status;
  global TXT_STATUS_ORDER;
  sortedStatuses = sortStatuses(statusStruct, TXT_STATUS_ORDER);
  
  cnt = length(sortedStatuses);
  if cnt > 4
    printf('Too many statuses to show in statusTXT fields, showing only first 4\n');
    cnt = 4;
  endif

  for id = 1 : cnt;
    status = sortedStatuses{id};
    statusToShow = status;
    
    statusVal = statusStruct.(status);
    if isfield(statusVal, 'msg') && ~isempty(statusVal.msg)
      statusToShow = [statusToShow ': ' statusVal.msg];
    endif
    updateFieldString(dirStruct.statusTxts{id}, statusToShow);

    if isfield(statusVal, 'result')
      result = statusVal.result;
      if isResultOK(result)
        color = GREEN;
      else
        color = RED;
      endif
      updateFieldColor(dirStruct.statusTxts{id}, color);
    endif
  endfor
  % clear the rest
  for id = cnt + 1:length(dirStruct.statusTxts)
    updateFieldString(dirStruct.statusTxts{id}, '');
  endfor
endfunction
  
function [detailsCh1, detailsCh2] = getStatusDetails(info)  
  statusStruct = info.status;
  global DETAILS_STATUS_ORDER;
  sortedStatuses = sortStatuses(statusStruct, DETAILS_STATUS_ORDER);
  
  detailsCh1 = cell();
  detailsCh2 = cell();
  for id = 1 : length(sortedStatuses)
    status = sortedStatuses{id};
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
  global CALIBRATING;
  
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
      % sorting distortPeaks by amplitude
      peaks = info.distortPeaks{channelID};
      if ~isempty(peaks)
        details{end + 1} = 'Compen. Distorts:';
        if ~isempty(info.compenCalFiles{channelID})
          details{end + 1} = info.compenCalFiles{channelID};
        endif
        peaks = sortrows(info.distortPeaks{channelID}, -2);
        details = addPeaksStr(peaks, 1, details);
      endif
      
    case ANALYSING
      details{end + 1} = 'Measured Funds:';
      details = addPeaksStr(info.measuredPeaks{channelID}, 3, details);
      
    case CALIBRATING
      calFreqs = info.calFreqs;
      if ~isempty(calFreqs)
        details{end + 1} = 'Calib. Freqs:';
        freqsStr = '';
        for id = 1:length(calFreqs)
          calFreq = calFreqs(id);
          freqsStr = [freqsStr ' ' num2str(calFreq) 'Hz'];
        endfor
        details{end + 1} = freqsStr;
      endif

  endswitch
  
endfunction

function str = addPeaksStr(peaksCh, decimals, str)
  % consts
  persistent MAX_LINES = 20;
  format = ['%7.' int2str(decimals) 'f'];
  cnt = rows(peaksCh);
  id = 0;
  while id < cnt
    ++id;
    if id > MAX_LINES
      % enough lines, add ...
      str{end + 1} = ['... + ' num2str(cnt - id + 1) ' peaks'];
      % quit loop
      break
    endif
    peak = peaksCh(id, :);
    str{end + 1} = ['  ' num2str(peak(1)) 'Hz ' num2str(20*log10(peak(2)), format) 'dB'];
  endwhile
endfunction

