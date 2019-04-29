function runScheduled(recInfo, playInfo);
  global schedQueue;
  idsToRemove = [];
  cnt = length(schedQueue);
  curTime = time();
  % loop all scheduled items
  for id = 1:cnt    
    item = schedQueue{id};
    % determine new label for current time and received infos, passing scheduledItem
    newLabel = item.getLabel(curTime, recInfo, playInfo, item);
    if ~isna(newLabel)
      % some label returned, executing fname
      feval(item.fname, newLabel);
      
      % add id of this item for removal
      idsToRemove = [idsToRemove, id];
    endif
  endfor
  % removing already executed items
  schedQueue(idsToRemove) = [];
endfunction