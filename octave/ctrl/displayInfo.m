function displayInfo(infoStruct, dirStruct)
  %infoStruct.id = NA;
  %infoStruct.time = time();
  %infoStruct.status = statusStruct;
  %infoStruct.measuredPeaks = measuredPeaks;
  %infoStruct.distortPeaks = distortPeaks;
  %infoStruct.genAmpl = genAmpl;
  %infoStruct.genFreq = genFreq;
  %infoStruct.fs = fs;
  %infoStruct.cmdDoneID;
  %infoStruct.compenCalFiles = compenCalFiles;
  %infoStruct.calFreqs;
  %infoStruct.direction = direction;

  updatePanelTitle(dirStruct, infoStruct);
  updateStatusTxts(dirStruct, infoStruct);
  updateMenu(dirStruct, infoStruct);

  [detailsCh1, detailsCh2] = getStatusDetails(infoStruct);
  setFieldString(dirStruct.detailTxts{1}, detailsCh1);
  setFieldString(dirStruct.detailTxts{2}, detailsCh2);
  
  updatePlots(dirStruct, infoStruct);
  %disp(infoStruct);
    
  updateSourceField(dirStruct.sourceTxt, infoStruct.sourceStruct);
  updateSinkField(dirStruct.sinkTxt, infoStruct.sinkStruct);
end

function updateSourceField(sourceTxt, sourceStruct)
  global PLAYREC_SRC;
  str = sourceStruct.name;
  if sourceStruct.src == PLAYREC_SRC
    str = ['DEV ' str];
  else
    str = ['FILE ' str];
    if ~isna(sourceStruct.filePos)
      str = [str ' ' num2str(ceil(sourceStruct.filePos)) '/' num2str(ceil(sourceStruct.fileLength)) 's'];
    end
  end
  setFieldString(sourceTxt, str);
end

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
      end
    end
    lines{end + 1} = str;
  end
  setFieldString(sinkTxt, lines);
end


function updateStatusTxts(dirStruct, infoStruct)
  persistent GREEN = [0, 0.5, 0];
  persistent RED = [0.5, 0, 0];
  persistent BLACK = [0, 0, 0];
  
  statusStr = cell();
  
  statusStruct = infoStruct.status;
  global TXT_STATUS_ORDER;
  sortedStatuses = sortStatuses(statusStruct, TXT_STATUS_ORDER);
  
  statusCnt = length(sortedStatuses);
  txtCnt = length(dirStruct.statusTxts);
  if statusCnt > txtCnt
    writeLog('WARN', 'Too many statuses to show in statusTXT fields, showing only first %d', txtCnt);
    statusCnt = txtCnt;
  end

  for id = 1 : statusCnt;
    status = sortedStatuses{id};
    statusToShow = getStatusToShow(status, infoStruct);
    
    statusVal = statusStruct.(status);    
    if isfield(statusVal, 'msg') && ~isempty(statusVal.msg)
      statusToShow = [statusToShow ': ' statusVal.msg];
    end
    setFieldString(dirStruct.statusTxts{id}, statusToShow);

    if isfield(statusVal, 'result')
      result = statusVal.result;
      if isResultOK(result)
        color = GREEN;
      else
        color = RED;
      end
    else
      % indiferent color
      color = BLACK;
    end
    setFieldColor(dirStruct.statusTxts{id}, color);
  end
  % clear the rest
  for id = statusCnt + 1:txtCnt
    setFieldString(dirStruct.statusTxts{id}, '');
  end
end

function statusToShow = getStatusToShow(status, infoStruct)
  global COMPENSATING;
  global CALIBRATING;
  
  statusToShow = status;
  switch(status)
      case COMPENSATING
        statusToShow = [statusToShow ' ' getCompTypeStr(infoStruct.compRequest)];
        
      case CALIBRATING
        statusToShow = [statusToShow ' ' getCompTypeStr(infoStruct.calRequest)];
    end
end

function typeStr = getCompTypeStr(compRequest)
  global COMP_TYPE_JOINT;
  global COMP_TYPE_PLAY_SIDE;
  global COMP_TYPE_REC_SIDE;
  
  switch(compRequest.compType)
    case COMP_TYPE_JOINT
      typeStr = 'Joint-Sides';
    
    case COMP_TYPE_PLAY_SIDE
      typeStr = 'Only Playback';
    
    case COMP_TYPE_REC_SIDE
      typeStr = 'Only Capture';
  end
  
  if ~isempty(compRequest.extraCircuit)
    typeStr = [typeStr ' (' compRequest.extraCircuit ')'];
  end
end

    
function [detailsCh1, detailsCh2] = getStatusDetails(infoStruct)
  statusStruct = infoStruct.status;
  global DETAILS_STATUS_ORDER;
  sortedStatuses = sortStatuses(statusStruct, DETAILS_STATUS_ORDER);
  
  detailsCh1 = cell();
  detailsCh2 = cell();
  for id = 1 : length(sortedStatuses)
    status = sortedStatuses{id};
    detailsCh1 = addDetails(1, status, infoStruct, detailsCh1);
    detailsCh2 = addDetails(2, status, infoStruct, detailsCh2);
    ++id;
  end
end

% formatting strings for details of channelID
function details = addDetails(channelID, status, infoStruct, details)
  global GENERATING;
  global COMPENSATING;
  global ANALYSING;
  global CALIBRATING;
  global DISTORTING;

  % empty line before second+ statuses
  if ~isempty(details)
    details{end + 1} = '';
  end
  
  switch(status)
    case GENERATING
      % showing generator freq and amplitude
      details{end + 1} = 'Gen. Frequencies:';
      details = addPeaksStr(abs(infoStruct.genFunds{channelID}), 3, details, infoStruct.nonInteger);
    
    case COMPENSATING
      % consts
      persistent COMP_DECIMALS = 1;
      persistent COMP_DECIMALS_MULTIPLIER = 10^COMP_DECIMALS;

      % cached results - linux octave is VERY inefficient!
      persistent compAmpls = cell(2, 2);
      persistent compDetails = cell(2, 2);


      % sorting distortPeaks by amplitude
      peaks = infoStruct.distortPeaks{channelID};
      if ~isempty(peaks)
        details{end + 1} = 'Compen. Distorts:';
        if ~isempty(infoStruct.compenCalFiles{channelID})
          details{end + 1} = infoStruct.compenCalFiles{channelID};
        end
        peaks = sortrows(infoStruct.distortPeaks{channelID}, -2);
        % replacing log ampl values
        peaks(:, 2) = floor(20*log10(abs(peaks(:, 2))) * COMP_DECIMALS_MULTIPLIER)/COMP_DECIMALS_MULTIPLIER;
        if ~isequal(peaks(:, 2), compAmpls{infoStruct.direction, channelID})
          % determining fundamental frequency for harmonic ID calculation in addLogPeaksStr
          fundPeaksCh = infoStruct.measuredPeaks{channelID};
          % showing harmonic ID makes sense only for one fundamental freq
          if rows(fundPeaksCh) == 1            
            fundFreq = fundPeaksCh(1, 1);
          else
            fundFreq = NA;
          end
          
          % log values changed, recalculating/generatingg string details
          compDetails{infoStruct.direction, channelID} = addLogPeaksStr(peaks, COMP_DECIMALS, {}, infoStruct.nonInteger, fundFreq);
          compAmpls{infoStruct.direction, channelID} = peaks(:, 2);
        end
        % adding comp details
        details = [details, compDetails{infoStruct.direction, channelID}];
      end
      
    case ANALYSING
      details{end + 1} = 'Measured Funds:';
      details = addPeaksStr(infoStruct.measuredPeaks{channelID}, 4, details, infoStruct.nonInteger);
      
    case CALIBRATING
      calFreqReq = infoStruct.calRequest.calFreqReq;
      if ~isempty(calFreqReq)
        calFreqReqCh = calFreqReq{channelID};
        if ~isempty(calFreqReqCh)
          details{end + 1} = 'Calib. Freqs:';
          for id = 1:rows(calFreqReqCh)
            calFreqRow = calFreqReqCh(id, :);
            % append all rows to details
            details = {details{:}, getCalFreqStrs(calFreqRow){:}};
          end
        end
      end

    case DISTORTING
      distortHarmAmpls = infoStruct.distortHarmAmpls;
      if ~isempty(distortHarmAmpls)
        details{end + 1} = 'Distortion Levels Added:';
        for id = 1:length(distortHarmAmpls)
          level = distortHarmAmpls(id);
          if ~isna(level)
            level = 20 * log10(level);
            details{end + 1} = ['Harmonics ' num2str(id + 1) ': ' num2str(level) 'dB'];
          end
        end
      end

  end
  
end

function strs = getCalFreqStrs(calFreqRow)
  strs = cell();
  persistent FORMAT = '%7.3f';
  str = [num2str(calFreqRow(1, 1)) 'Hz'];
  if columns(calFreqRow) >= 4 && ~isna(calFreqRow(1, 4))
    % exact level
    str = [str '@' num2str(20*log10(calFreqRow(1, 4)), FORMAT) 'dB'];
  end
  strs{end + 1} = str;

  if ~isna(calFreqRow(1, 2))
    str = [' <' num2str(20*log10(calFreqRow(1, 2)), FORMAT) ', ' num2str(20*log10(calFreqRow(1, 3)), FORMAT) '> dB'];
    strs{end + 1} = str;
  end
end

function str = addPeaksStr(peaksCh, logDecimals, str, nonInteger)
  if ~isempty(peaksCh)
    peaksCh(:, 2) = 20*log10(abs(peaksCh(:, 2)));
    str = addLogPeaksStr(peaksCh, logDecimals, str, nonInteger);
  end
end

function str = addLogPeaksStr(peaksCh, logDecimals, str, nonInteger, fundFreq = NA)
  % consts
  persistent MAX_LINES = 20;
  persistent BEFORE_DECIMALS = 5;

  peakFmt = [' %8' getFreqDecimals(nonInteger) 'fHz  %*.*fdB'];
  harmPeakFmt = ['%2d:' peakFmt];
  % number of positions before logDecimals: -120.
  width = BEFORE_DECIMALS + logDecimals;
  cnt = rows(peaksCh);  
  id = 0;
  
  while id < cnt
  %while false
    ++id;
    if id > MAX_LINES
      % enough lines, add ...
      str{end + 1} = ['... + ' num2str(cnt - id + 1) ' peaks'];
      % quit loop
      break
    end
    
    peak = peaksCh(id, :);
    % adding only peaks with freq > 0 (i.e. real values)
    if peak(1) > 0
      freq = peak(1);
      ampl = peak(2);
      if ~isna(fundFreq)
        % adding harmonic ID
        harmID = peak(1) ./ fundFreq;
        str{end + 1} = sprintf(harmPeakFmt, harmID, freq, width, logDecimals, ampl);
      else
        str{end + 1} = sprintf(peakFmt, freq, width, logDecimals, ampl);
      end
    end
    
  end
end

function decimalsStr = getFreqDecimals(nonInteger)
  if nonInteger
    decimalsStr = '.3';
  else
    decimalsStr = '.0';
  end
end
