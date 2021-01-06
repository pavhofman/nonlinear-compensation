% if play side is generating, sends generator off cmd. 
% if rec side is calibration, sends calibrate off cmd
% returns cmdIDs of the commands sent (empty, one or two cmdIDs)
function cmdIDs = sendAllOffCmds()
  global playInfo;
  global recInfo;
  global cmdFileRec;
  global CALIBRATING;
  global GENERATING;
  global CALIBRATE;

  cmdIDs = [];

  if isfield(playInfo.status, GENERATING)
    cmdIDPlay = sendStopGeneratorCmd();
    cmdIDs = [cmdIDs, cmdIDPlay];
  end
  if isfield(recInfo.status, CALIBRATING)
    cmdIDRec = writeCmd([CALIBRATE ' ' 'off'], cmdFileRec);
    cmdIDs = [cmdIDs, cmdIDRec];
  end
end
