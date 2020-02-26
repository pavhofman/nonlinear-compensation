% scheduler-enabled wait starting another function fNameToRun, with labels if fNameToRun returns OK (true) of Fail (false)
% 
function waitForTaskFinish(fNameToRun, okLabel, failLabel, callingFName);
  global schedTasksQueue;
  fGetLabel = @(curTime, recInfo, playInfo, schedTask) decideLabel(fNameToRun, callingFName, okLabel, failLabel, schedTask);
  schedTask = createSchedTask(fNameToRun, fGetLabel);
  schedTask.runFunc = true;
  schedTask.result = NA;
  schedTasksQueue{end + 1} = schedTask;
endfunction

% determine label
function schedTask = decideLabel(fNameToRun, callingFName, okLabel, failLabel, schedTask)
  if schedTask.runFunc
    % start fNameToRun
    schedTask.runFunc = false;
    % start at 1
    schedTask.newLabel = 1;
    schedTask.fName = fNameToRun;
    % keep this item in schedTasksQueue - is used for returning to callingFName
    schedTask.keepInQueue = true;
  elseif ~isna(schedTask.result)
    % fNameToRun function has finished, returning back to the calling function
    schedTask.fName = callingFName;
    % can drop the item from schedTasksQueue
    schedTask.keepInQueue = false;
    % with result:
    if schedTask.result
      schedTask.newLabel = okLabel;
    else
      schedTask.newLabel = failLabel;
    endif
  else
    % keep waiting, no label
    schedTask.newLabel = NA;
    % keeping fNameToRun so that result can be passed to this task in runScheduledTask()
    schedTask.fName = fNameToRun;
  endif
endfunction
