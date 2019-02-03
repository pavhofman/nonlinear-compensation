function runScheduled(recInfo, playInfo);
  global schedQueue;
  idsToRemove = [];
  cnt = length(schedQueue);
  curTime = time();
  % loop all scheduled items
  for id = 1:cnt    
    s = schedQueue{id};
    % determine new label for current time and received infos
    newLabel = s.getLabel(curTime, recInfo, playInfo);
    if ~isna(newLabel)
      % some label returned, executing fname
      feval(s.fname, newLabel);
      
      % add id of this item for removal
      idsToRemove = [idsToRemove, id];
    endif
  endfor
  % removing already executed items
  schedQueue(idsToRemove) = [];
endfunction