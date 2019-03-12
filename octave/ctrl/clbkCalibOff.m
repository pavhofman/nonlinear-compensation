% sending cal off cmd + hiding lastLines in plots
function clbkCalibOff(src, data)
  global cmdFileRec;
  global CALIBRATE;
  global recStruct;
  
  clbkCmdOff(src, data, CALIBRATE, cmdFileRec);

  % hiding lastLines
  for channelID = 1:2
    plotStruct = recStruct.calPlots{channelID};
    setVisible(plotStruct.lastLine, false);
    % resetting plot scale
    set(plotStruct.axis, 'ylim', [-20,0]);
  endfor
endfunction
