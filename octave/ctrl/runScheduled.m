function runScheduled(recInfo, playInfo);
  global schedQueue;
  idsToRemove = [];
  cnt = length(schedQueue);
  curTime = time();
  % loop all scheduled items
  for id = 1:cnt
    item = schedQueue{id};
    % determine new label for current time and received infos, passing scheduledItem
    item = item.getNextPointer(curTime, recInfo, playInfo, item);
    % updating in queue
    schedQueue{id} = item;
    
    if ~isna(item.newLabel) && ~isempty(item.fName)
      % some label returned, executing fName
      writeLog('DEBUG', 'Calling function %s, label %d', item.fName, item.newLabel);
      result = feval(item.fName, item.newLabel, item);
      if ~isna(result) 
        % result belongs to item calling the item.fName which has the result field
        resultItemID = getRunTaskItemIDFor(item.fName);
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
