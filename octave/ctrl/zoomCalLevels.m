function zoomCalLevels(calFreqReq, targetLevels)
  global recStruct;
  
  targetLevels = 20*log10(targetLevels);
  
  if ~isempty(calFreqReq)
    % must have at least 2 channels
    for channelID = 1:2
      plotStruct = recStruct.calPlots{channelID};
      calFreqReqCh = calFreqReq{channelID};
      targetLevelsCh = targetLevels(channelID);      
      % TODO - somehow show both frequencies
      % only first freq for now
      if ~isempty(calFreqReqCh) && any(~isna(calFreqReqCh(1, 2)))
        % cal freqs not empty and the first specifies amplitude limit
        minAmpl = 20*log10(calFreqReqCh(1, 2));
        maxAmpl = 20*log10(calFreqReqCh(1, 3));
        xVertices = [0.1 0.9 0.9 0.1];
        yVertices = [minAmpl minAmpl maxAmpl maxAmpl];
        rangePatch = plotStruct.rangePatch;
        set(rangePatch, 'xdata', xVertices)
        set(rangePatch, 'ydata', yVertices)
        setVisible(rangePatch, true);
        
        % zooming around target levels
        lowerYLim = min(targetLevelsCh)  - 0.5;
        upperYLim = min(targetLevelsCh)  + 0.5;
        set(plotStruct.axis, 'ylim', [lowerYLim, upperYLim]);
      endif

      % updating target levels, if any
      if ~isna(targetLevelsCh)
        % update
        updateLevelsLine(targetLevelsCh, plotStruct.lastLine, 0.5);
      else
        % none, hide
        setVisible(plotStruct.lastLine, false);
      endif
      
    endfor
  endif
endfunction

% true if any freq in calFreqReqCh has specified min/max amplitudes (i.e. level limits)
function result = hasLimits(calFreqReqCh)
  result = any(isna(calFreqReqCh(:, 2)));
endfunction

