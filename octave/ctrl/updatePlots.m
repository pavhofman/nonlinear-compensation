% Updating corresponding calPlots based on info. Reads fundamental amplitudes from calFiles, updates only calLines in dirStruct.
function updatePlots(dirStruct, info)
  global COMPENSATING;
  global CH_DISTANCE_X;
  persistent calFiles = cell(2, 2);
  persistent allCalLevels = cell(2, 2);
  
  isCompensating = isfield(info.status, COMPENSATING);
  direction = info.direction;
  for channelID = 1:2
    plotStruct = dirStruct.calPlots{channelID};
    if isCompensating
      presus = 1;
    endif
    calFile = info.compenCalFiles{channelID};
    if ~strcmp(calFiles{direction, channelID}, calFile) || info.reloadCalFiles
      % change from last run or explicit request to reload calfiles
      if ~isempty(calFile)
        % plot calfile levels
        calLevels = loadCalLevels(calFile);
      else
        calLevels = [];
      endif
      
      % store levels for next run        
      allCalLevels{direction, channelID} = calLevels;
      % store calFile for next run
      calFiles{direction, channelID} = calFile;
      
      % plotting changed calLine
      calX = zeros(rows(calLevels), 1);
      calY = calLevels;
      if columns(calLevels) == 2
        calX = [calX; calX + CH_DISTANCE_X];
        calY = [calLevels(:, 1); calLevels(:, 2)];
      endif

      plotLevels(plotStruct.calLine, calX, calY);
    endif
    
    % determine current levels
    curLevels = [];
    if iscell(info.measuredPeaks)
      measuredPeaksCh = info.measuredPeaks{channelID};
      if ~isempty(measuredPeaksCh)
        curLevels = info.measuredPeaks{channelID}(:, 2);
        curLevels = 20*log10(curLevels);
      endif
    endif
    
    % plotting current levels
    if ~isempty(curLevels)
      updateLevelsLine(curLevels, plotStruct.curLine, 1);
    endif
  endfor
endfunction

function levels = loadCalLevels(calFile)
  global AMPL_IDX;  % = index of fundAmpl1
  if ~exist(calFile, 'file')
    writeLog('WARN', 'The calfile %s does not exist, cannot load into cal plot!', calFile);
    levels = [];
    return;
  endif
  load(calFile);
  if length(calRec.fundFreqs) == 2
    % skipping auxiliary first and last rows
    % fund1 + fund2 ampl columns
    levels = calRec.peaks(2:end - 1, AMPL_IDX:AMPL_IDX + 1);
  else
    % only fund1 ampl column
    levels = calRec.peaks(2:end - 1, AMPL_IDX);
  endif
  % in dB
  levels = 20*log10(levels);
endfunction