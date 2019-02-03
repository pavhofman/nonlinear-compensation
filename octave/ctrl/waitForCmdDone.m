% scheduler-eanbled wait for incoming cmdDoneID message with timeout
% if recInfo or playInfo has cmdDoneID, return nextLabel. If timout reached, return timeoutLabel
function waitForCmdDone(cmdDoneID, nextLabel, timeout, timeoutLabel, fname);
  global schedQueue;
  reqTime = time() + timeout;
  getLabel = @(curTime, recInfo, playInfo) decideLabelFor(curTime,  reqTime, cmdDoneID, nextLabel, timeoutLabel, recInfo, playInfo);
  schedQueue{end + 1} =  createSchedItem(getLabel, fname);
endfunction

% determine label: if recInfo or playInfo has cmdDoneID, return nextLabel. If timout reached, return timeoutLabel
function newLabel = decideLabelFor(curTime,  reqTime, cmdDoneID, nextLabel, timeoutLabel, recInfo, playInfo);
  if hasCmdDone(recInfo, cmdDoneID) || hasCmdDone(playInfo, cmdDoneID)
    % command done, go to nextLabel
    newLabel = nextLabel;  
  elseif curTime > reqTime
    % timeout occured
    newLabel = timeoutLabel;
  else
    % keep waiting, no label
    newLabel = NA;
  endif
endfunction

function result = hasCmdDone(info, cmdDoneID)
  result = ~isempty(info) && strcmp(info.cmdDoneID, cmdDoneID)
endfunction