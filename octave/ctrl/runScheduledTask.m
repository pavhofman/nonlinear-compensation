function runScheduledTask(recInfo, playInfo);
  global schedTasksQueue;
  global taskFNameToAbort;

  idsToRemove = [];
  cnt = length(schedTasksQueue);
  curTime = time();
  
  
  if ~isempty(taskFNameToAbort)
    % requested task abortion
    % finding all schedTasks related to this task. Keep only runtask task, or one of other tasks
    % first the runTasks
    runTaskID = getRunTaskIDFor(taskFNameToAbort);
    % add any other task for taskFNameToAbort, skip the taskIDs
    nonRunTaskIDs = getTaskIDs(taskFNameToAbort, runTaskID);
    taskIDs = [runTaskID, nonRunTaskIDs];
    
    % keep the first one, drop the rest
    if ~isempty(taskIDs)
      toKeepID = taskIDs(1);
      taskToKeep = schedTasksQueue{toKeepID};
      global ABORT;
      % instructing the task taskFName to abort
      taskToKeep.newLabel = ABORT;
      % pushing back to the queue
      schedTasksQueue{toKeepID} = taskToKeep;
      % removing all the remaning tasks for taskFNameToAbort
      schedTasksQueue(taskIDs(2:end)) = [];
    endif
    % resetting flag taskFNameToAbort
    taskFNameToAbort = '';
  endif

  % loop all scheduled tasks
  for id = 1:cnt
    task = schedTasksQueue{id};
    if isempty(task.newLabel)
      % determine new label for current time and received infos, passing scheduledItem
      task = task.getNextPointer(curTime, recInfo, playInfo, task);
    endif
    newLabel = task.newLabel;
    taskFName = task.taskFName;
    
    task.newLabel = [];

    % updating in queue
    schedTasksQueue{id} = task;

    if ~isna(newLabel) && ~isempty(taskFName)
      % some label returned, executing taskFName
      writeLog('DEBUG', 'Calling function %s, label %d', taskFName, newLabel);
      result = feval(taskFName, newLabel, task);
      if ~isna(result) 
        % result belongs to task calling the task.taskFName which has the result field
        resultItemID = getRunTaskIDFor(taskFName);
        if ~isempty(resultItemID)
          schedTasksQueue{resultItemID}.result = result;
        endif
      endif

      if ~task.keepInQueue
        % add id of this task for removal
        idsToRemove = [idsToRemove, id];
      endif
    endif
  endfor
  % removing already executed tasks
  schedTasksQueue(idsToRemove) = [];
endfunction

function foundIDs = getTaskIDs(taskFName, idsToSkip)
  global schedTasksQueue;
  foundIDs = [];
  for id = 1:length(schedTasksQueue)
    if ~any(idsToSkip == id)
      task = schedTasksQueue{id};
      if strcmp(task.taskFName, taskFName)
        foundIDs = [foundIDs, id];
      endif
    endif
  endfor
endfunction