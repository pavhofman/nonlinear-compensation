% Showing lastLine in plot with current levels of curLine. For both channels.
function showLastLine()
  global recStruct;

  for channelID = 1:2
    plotStruct = recStruct.calPlots{channelID};
    % copying current Y values from curLine to lastLine
    curLevels = get(plotStruct.curLine, 'YData');
    if ~isempty(curLevels)
      updateLevelsLine(curLevels, plotStruct.lastLine, 0.5);
    endif
    % zooming
    lowerYLim = min(curLevels)  - 0.5;
    upperYLim = min(curLevels)  + 0.5;
    set(plotStruct.axis, 'ylim', [lowerYLim, upperYLim]);
  endfor
endfunction