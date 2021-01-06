% sending calibration command to rec side + showing lastLines in the plots
function clbkCalib(src, data, compType, contCalib, extraCmd = '')
  global cmdFileRec;
  global CALIBRATE;
  global CMD_CONT_PREFIX;
  global CMD_COMP_TYPE_PREFIX;
    
  cmd = [CALIBRATE ' ' CMD_COMP_TYPE_PREFIX num2str(compType)];
  
  if contCalib
    cmd = [cmd ' ' CMD_CONT_PREFIX '1'];
    % continuous calibration shows plot line with last measured values (values of curLine)
    showLastLine();
  end

  if ~isempty(extraCmd)
    cmd = [cmd ' ' extraCmd];
  end
  
  writeCmd(cmd, cmdFileRec);
end
