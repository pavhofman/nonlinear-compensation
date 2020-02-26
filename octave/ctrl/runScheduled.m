function runScheduled(recInfo, playInfo);
  global schedQueue;
  global fNameToAbort;

  idsToRemove = [];
  cnt = length(schedQueue);
  curTime = time();
  
  
  if ~isempty(fNameToAbort)
    % requested task abortion
    % finding all schedItems related to this task. Keep only runtask item, or one of other items
    % first the runTask items
    runTaskID = getRunTaskItemIDFor(fNameToAbort);
    % add any other task for fNameToAbort, skip the taskIDs
    nonRunTaskIDs = getTaskItemIDs(fNameToAbort, runTaskID);
    taskIDs = [runTaskID, nonRunTaskIDs];
    
    % keep the first one, drop the rest
    if ~isempty(taskIDs)
      toKeepID = taskIDs(1);
      itemToKeep = schedQueue{toKeepID};
      global ABORT;
      % instructing the task fName to abort
      itemToKeep.newLabel = ABORT;
      % pushing back to the queue
      schedQueue{toKeepID} = itemToKeep;
      % removing all the remaning items for fNameToAbort
      schedQueue(taskIDs(2:end)) = [];
    endif
    % resetting fNameToAbort
    fNameToAbort = '';
  endif

  % loop all scheduled items
  for id = 1:cnt
    item = schedQueue{id};
    if isempty(item.newLabel)
      % determine new label for current time and received infos, passing scheduledItem
      item = item.getNextPointer(curTime, recInfo, playInfo, item);
    endif
    newLabel = item.newLabel;
    fName = item.fName;
    
    item.newLabel = [];

    % updating in queue
    schedQueue{id} = item;

    if ~isna(newLabel) && ~isempty(fName)
      % some label returned, executing fName
      writeLog('DEBUG', 'Calling function %s, label %d', fName, newLabel);
      result = feval(fName, newLabel, item);
      if ~isna(result) 
        % result belongs to item calling the item.fName which has the result field
        resultItemID = getRunTaskItemIDFor(fName);
        if ~isempty(resultItemID)
          schedQueue{resultItemID}.result = result;
        endif
      endif

      if ~item.keepInQueue
        % add id of this item for removal
        idsToRemove = [idsToRemove, id];
      endif
    endif
  endfor
  % removing already executed items
  schedQueue(idsToRemove) = [];
endfunction

function foundIDs = getTaskItemIDs(fName, idsToSkip)
  global schedQueue;  
  foundIDs = [];
  for id = 1:length(schedQueue)
    if ~any(idsToSkip == id)
      item = schedQueue{id};
      if strcmp(item.fName, fName)
        foundIDs = [foundIDs, id];
      endif
    endif
  endfor
endfunction