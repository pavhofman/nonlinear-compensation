function runScheduledTask(recInfo, playInfo);
  global schedTasksQueue;
  global taskFNameToAbort;

  idsToRemove = [];
  cnt = length(schedTasksQueue);
  curTime = time();
  
  
  if ~isempty(taskFNameToAbort)
    % requested task abortion
    % finding all schedTasks related to this task. Keep only runtask item, or one of other items
    % first the runTask items
    runTaskID = getRunTaskIDFor(taskFNameToAbort);
    % add any other task for taskFNameToAbort, skip the taskIDs
    nonRunTaskIDs = getTaskItemIDs(taskFNameToAbort, runTaskID);
    taskIDs = [runTaskID, nonRunTaskIDs];
    
    % keep the first one, drop the rest
    if ~isempty(taskIDs)
      toKeepID = taskIDs(1);
      itemToKeep = schedTasksQueue{toKeepID};
      global ABORT;
      % instructing the task taskFName to abort
      itemToKeep.newLabel = ABORT;
      % pushing back to the queue
      schedTasksQueue{toKeepID} = itemToKeep;
      % removing all the remaning items for taskFNameToAbort
      schedTasksQueue(taskIDs(2:end)) = [];
    endif
    % resetting flag taskFNameToAbort
    taskFNameToAbort = '';
  endif

  % loop all scheduled items
  for id = 1:cnt
    item = schedTasksQueue{id};
    if isempty(item.newLabel)
      % determine new label for current time and received infos, passing scheduledItem
      item = item.getNextPointer(curTime, recInfo, playInfo, item);
    endif
    newLabel = item.newLabel;
    taskFName = item.taskFName;
    
    item.newLabel = [];

    % updating in queue
    schedTasksQueue{id} = item;

    if ~isna(newLabel) && ~isempty(taskFName)
      % some label returned, executing taskFName
      writeLog('DEBUG', 'Calling function %s, label %d', taskFName, newLabel);
      result = feval(taskFName, newLabel, item);
      if ~isna(result) 
        % result belongs to item calling the item.taskFName which has the result field
        resultItemID = getRunTaskIDFor(taskFName);
        if ~isempty(resultItemID)
          schedTasksQueue{resultItemID}.result = result;
        endif
      endif

      if ~item.keepInQueue
        % add id of this item for removal
        idsToRemove = [idsToRemove, id];
      endif
    endif
  endfor
  % removing already executed items
  schedTasksQueue(idsToRemove) = [];
endfunction

function foundIDs = getTaskItemIDs(taskFName, idsToSkip)
  global schedTasksQueue;
  foundIDs = [];
  for id = 1:length(schedTasksQueue)
    if ~any(idsToSkip == id)
      item = schedTasksQueue{id};
      if strcmp(item.taskFName, taskFName)
        foundIDs = [foundIDs, id];
      endif
    endif
  endfor
endfunction