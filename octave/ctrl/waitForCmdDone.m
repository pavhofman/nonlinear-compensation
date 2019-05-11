% scheduler-eanbled wait for incoming cmdDoneID message with timeout
% if recInfo or playInfo has cmdDoneID, return nextLabel. If timout reached, return timeoutLabel
function waitForCmdDone(cmdDoneIDs, nextLabel, timeout, timeoutLabel, callingFName);
  global schedQueue;
  reqTime = time() + timeout;
  getLabel = @(curTime, recInfo, playInfo, schedItem) decideLabelFor(curTime,  reqTime, nextLabel, timeoutLabel, recInfo, playInfo, schedItem);
  schedItem = createSchedItem(callingFName, getLabel);
  schedItem.remainingCmdIDs = cmdDoneIDs;
  schedQueue{end + 1} = schedItem;
endfunction

% determine label: if recInfo or playInfo has cmdDoneID, return nextLabel. If timout reached, return timeoutLabel
function schedItem = decideLabelFor(curTime,  reqTime, nextLabel, timeoutLabel, recInfo, playInfo, schedItem)
  % removing this cmdDoneID from the remaining ids
  schedItem.remainingCmdIDs(schedItem.remainingCmdIDs == getCmdDoneID(recInfo)) = [];
  schedItem.remainingCmdIDs(schedItem.remainingCmdIDs == getCmdDoneID(playInfo)) = [];
  if isempty(schedItem.remainingCmdIDs)
    % all commands done, go to nextLabel
    schedItem.newLabel = nextLabel;
  elseif curTime > reqTime
    % timeout occured
    schedItem.newLabel = timeoutLabel;
  endif
  % else keep waiting
endfunction

function cmdDoneID = getCmdDoneID(info)
  if ~isempty(info)
    cmdDoneID = info.cmdDoneID;
  else
    cmdDoneID = NA;
  endif
endfunction