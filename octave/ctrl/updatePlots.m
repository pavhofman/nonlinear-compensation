% Updating corresponding calPlots based on info. Reads fundamental amplitudes from calFiles, updates only calLines in dirStruct.
function updatePlots(dirStruct, info)
  global COMPENSATING;
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
    if ~strcmp(calFiles{direction, channelID}, calFile)
      % change from last run
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
        calX = [calX; calX + 0.1];
        calY = [calLevels(:, 1); calLevels(:, 2)];
      endif

      plotLevels(plotStruct.calLine, calX, calY);
    endif
    
    % determine current levels
    measuredPeaksCh = info.measuredPeaks{channelID};
    if ~isempty(measuredPeaksCh)
      curLevels = info.measuredPeaks{channelID}(:, 2);
      curLevels = 20*log10(curLevels);
    else
      curLevels = [];
    endif
    
    % plotting current levels
    if ~isempty(curLevels)
      curX = ones(rows(curLevels), 1);
      curY = curLevels;
      if length(curLevels) == 2
        curX(2) += 0.1;
      endif
      plotLevels(plotStruct.curLine, curX, curY);
    endif
    set(plotStruct.axis, 'ylim', [-20,1]);
  endfor
endfunction

function levels = loadCalLevels(calFile)
  persistent AMPL_IDX = 4;  % = index of fundAmpl1
  
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

function plotLevels(line, x, y)
  isVisible = strcmp(get(line, 'visible'), 'on');
  if ~isempty(y)
    shownX = get(line, 'XData');    
    if ~isequal(shownX, x)
      set(line, 'XData', x);
    endif
    shownY = get(line, 'YData');
    if ~isequal(shownY, y)
      set(line, 'YData', y);
    endif
    if ~isVisible
      set(line, 'visible', 'on');
    endif
  else
    % hide 
    if isVisible
      set(line, 'visible', 'off');
    endif
  endif
endfunction