% scheduler-enabled wait starting another function taskFNameToRun, with labels if taskFNameToRun returns OK (true) of Fail (false)
% 
function waitForTaskFinish(taskFNameToRun, okLabel, failLabel, callingFName);
  global schedTasksQueue;
  fGetLabel = @(curTime, recInfo, playInfo, schedTask) decideLabel(taskFNameToRun, callingFName, okLabel, failLabel, schedTask);
  schedTask = createSchedTask(taskFNameToRun, fGetLabel);
  schedTask.runFunc = true;
  schedTask.result = NA;
  schedTasksQueue{end + 1} = schedTask;
end

% determine label
function schedTask = decideLabel(taskFNameToRun, callingFName, okLabel, failLabel, schedTask)
  if schedTask.runFunc
    % start taskFNameToRun
    schedTask.runFunc = false;
    % start at 1
    schedTask.newLabel = 1;
    schedTask.taskFName = taskFNameToRun;
    % keep this item in schedTasksQueue - is used for returning to callingFName
    schedTask.keepInQueue = true;
  elseif ~isna(schedTask.result)
    % taskFNameToRun function has finished, returning back to the calling function
    schedTask.taskFName = callingFName;
    % can drop the item from schedTasksQueue
    schedTask.keepInQueue = false;
    % with result:
    if schedTask.result
      schedTask.newLabel = okLabel;
    else
      schedTask.newLabel = failLabel;
    end
  else
    % keep waiting, no label
    schedTask.newLabel = NA;
    % keeping taskFNameToRun so that result can be passed to this task in runScheduledTask()
    schedTask.taskFName = taskFNameToRun;
  end
end
