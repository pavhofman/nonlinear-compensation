% sending cal off cmd + hiding lastLines in plots
function clbkCalibOff(src, data)
  global cmdFileRec;
  global CALIBRATE;
  
  clbkCmdOff(src, data, CALIBRATE, cmdFileRec);

  closeCalibPlot();
end
