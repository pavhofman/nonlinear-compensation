function closeCalibPlot()
  global recStruct;
  
  % hiding lastLines
  for channelID = 1:2
    plotStruct = recStruct.calPlots{channelID};
    setVisible(plotStruct.lastLine, false);    
    setVisible(plotStruct.rangePatch, false);
    % resetting plot scale
    set(plotStruct.axis, 'ylim', [-20,0]);    
  end
end
