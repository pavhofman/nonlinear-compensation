% scheduler-eanbled wait for incoming cmdDoneID message with timeout
% if recInfo or playInfo has cmdDoneID, return nextLabel. If timout reached, return timeoutLabel
function waitForCmdDone(cmdDoneIDs, nextLabel, timeout, timeoutLabel, callingFName);
  global schedTasksQueue;
  reqTime = time() + timeout;
  fGetLabel = @(curTime, recInfo, playInfo, schedTask) decideLabelFor(curTime,  reqTime, nextLabel, timeoutLabel, recInfo, playInfo, schedTask);
  schedTask = createSchedTask(callingFName, fGetLabel);
  schedTask.remainingCmdIDs = cmdDoneIDs;
  schedTasksQueue{end + 1} = schedTask;
end

% determine label: if recInfo or playInfo has cmdDoneID, return nextLabel. If timout reached, return timeoutLabel
function schedTask = decideLabelFor(curTime,  reqTime, nextLabel, timeoutLabel, recInfo, playInfo, schedTask)
  % removing this cmdDoneID from the remaining ids
  schedTask.remainingCmdIDs(schedTask.remainingCmdIDs == getCmdDoneID(recInfo)) = [];
  schedTask.remainingCmdIDs(schedTask.remainingCmdIDs == getCmdDoneID(playInfo)) = [];
  if isempty(schedTask.remainingCmdIDs)
    % all commands done, go to nextLabel
    schedTask.newLabel = nextLabel;
  elseif curTime > reqTime
    % timeout occured
    schedTask.newLabel = timeoutLabel;
  end
  % else keep waiting
end

function cmdDoneID = getCmdDoneID(info)
  if ~isempty(info)
    cmdDoneID = info.cmdDoneID;
  else
    cmdDoneID = NA;
  end
end