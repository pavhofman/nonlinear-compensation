function processInfo(info, dirStruct)
  %info.id = NA;
  %info.time = time();
  %info.status = statusStruct;
  %info.measuredPeaks = measuredPeaks;
  %info.distortPeaks = distortPeaks;
  %info.genAmpl = genAmpl;
  %info.genFreq = genFreq;
  %info.fs = fs;
  %info.cmdDoneID;
  %info.compenCalFiles = compenCalFiles;
  %info.calFreqs;
  %info.direction = direction;
  
  updateStatusTxts(dirStruct, info);
  updateMenu(dirStruct, info);

  [detailsCh1, detailsCh2] = getStatusDetails(info);
  setFieldString(dirStruct.detailTxts{1}, detailsCh1);
  setFieldString(dirStruct.detailTxts{2}, detailsCh2);
  
  updatePlots(dirStruct, info);
  %disp(info);
    
  updateSourceField(dirStruct.sourceTxt, info.sourceStruct);
  updateSinkField(dirStruct.sinkTxt, info.sinkStruct);
endfunction

function updateSourceField(sourceTxt, sourceStruct)
  global PLAYREC_SRC;
  str = sourceStruct.name;
  if sourceStruct.src == PLAYREC_SRC
    str = ['DEV ' str];
  else
    str = ['FILE ' str];
    if ~isna(sourceStruct.filePos)
      str = [str ' ' num2str(ceil(sourceStruct.filePos)) '/' num2str(ceil(sourceStruct.fileLength)) 's'];
    endif
  endif
  setFieldString(sourceTxt, str);
endfunction

function updateSinkField(sinkTxt, sinkStruct)
  global PLAYREC_SINK;
  lines = cell();
  for [detailsStruct, sink] = sinkStruct
    str = detailsStruct.name;
    if strcmp(sink, PLAYREC_SINK)
      str = ['DEV ' str];
    else      
      if ~isna(detailsStruct.recLength)
        str = [str ' ' num2str(ceil(detailsStruct.recLength)) 's'];
      endif
    endif
    lines{end + 1} = str;
  endfor
  setFieldString(sinkTxt, lines);
endfunction


function updateStatusTxts(dirStruct, info)
  persistent GREEN = [0, 0.5, 0];
  persistent RED = [0.5, 0, 0];
  persistent BLACK = [0, 0, 0];
  
  global COMPENSATING;
  statusStr = cell();
  
  statusStruct = info.status;
  global TXT_STATUS_ORDER;
  sortedStatuses = sortStatuses(statusStruct, TXT_STATUS_ORDER);
  
  statusCnt = length(sortedStatuses);
  txtCnt = length(dirStruct.statusTxts);
  if statusCnt > txtCnt
    writeLog('WARN', 'Too many statuses to show in statusTXT fields, showing only first %d', txtCnt);
    statusCnt = txtCnt;
  endif

  for id = 1 : statusCnt;
    status = sortedStatuses{id};
    statusToShow = status;
    
    statusVal = statusStruct.(status);
    if isfield(statusVal, 'msg') && ~isempty(statusVal.msg)
      statusToShow = [statusToShow ': ' statusVal.msg];
    endif
    setFieldString(dirStruct.statusTxts{id}, statusToShow);

    if isfield(statusVal, 'result')
      result = statusVal.result;
      if isResultOK(result)
        color = GREEN;
      else
        color = RED;
      endif
    else
      % indiferent color
      color = BLACK;
    endif
    setFieldColor(dirStruct.statusTxts{id}, color);
  endfor
  % clear the rest
  for id = statusCnt + 1:txtCnt
    setFieldString(dirStruct.statusTxts{id}, '');
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
    detailsCh1 = addDetails(1, status, info, detailsCh1);
    detailsCh2 = addDetails(2, status, info, detailsCh2);
    ++id;
  endfor  
endfunction

% formatting strings for details of channelID
function details = addDetails(channelID, status, info, details)
  global GENERATING;
  global COMPENSATING;
  global ANALYSING;
  global CALIBRATING;
  global DISTORTING;
  
  % empty line before second+ statuses
  if ~isempty(details)
    details{end + 1} = '';
  endif
  
  switch(status)
    case GENERATING
      % showing generator freq and amplitude
      details{end + 1} = 'Gen. Frequencies:';
      details = addPeaksStr(abs(info.genFunds{channelID}), 3, details);
    
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
      calFreqReq = info.calRequest.calFreqReq;
      if ~isempty(calFreqReq)
        calFreqReqCh = calFreqReq{channelID};
        if ~isempty(calFreqReqCh)
          details{end + 1} = 'Calib. Freqs:';
          for id = 1:rows(calFreqReqCh)
            calFreqRow = calFreqReqCh(id, :);
            details{end + 1} = getCalFreqRow(calFreqRow);
          endfor
        endif
      endif

    case DISTORTING
      distortHarmLevels = info.distortHarmLevels;
      if ~isempty(distortHarmLevels)
        details{end + 1} = 'Distortion Levels Added:';
        for id = 1:length(distortHarmLevels)
          level = distortHarmLevels(id);
          if ~isna(level)
            details{end + 1} = ['Harmonics ' num2str(id + 1) ': ' num2str(level) 'dB'];
          endif
        endfor
      endif

  endswitch
  
endfunction

function str = getCalFreqRow(calFreqRow)
  persistent format = '%7.2f';
  str = [num2str(calFreqRow(1, 1)) 'Hz'];
  if ~isna(calFreqRow(2))
    str = [str ' <' num2str(20*log10(calFreqRow(1, 2)), format) ', ' num2str(20*log10(calFreqRow(1, 3)), format) '> dB'];
  endif
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
    % adding only peaks with freq > 0 (i.e. real values)
    if peak(1) > 0
      str{end + 1} = ['  ' num2str(peak(1)) 'Hz   ' num2str(20*log10(abs(peak(2))), format) 'dB'];
    endif
  endwhile
endfunction
