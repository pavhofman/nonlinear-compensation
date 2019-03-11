% sending calibration command to rec side + showing lastLines in the plots
function clbkCalib(src, data, contCalib)
  global cmdFileRec;
  global CALIBRATE;
  global CMD_CONT_PREFIX;
  if contCalib
    writeCmd([CALIBRATE ' ' CMD_CONT_PREFIX '1'], cmdFileRec);
    % continuous calibration shows plot line with last measured values (values of curLine)
    showLastLine();
  else
    writeCmd(CALIBRATE, cmdFileRec);
  endif
endfunction
