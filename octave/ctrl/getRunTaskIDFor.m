function foundID = getRunTaskIDFor(fName)
  global schedTasksQueue;
  foundID = [];
  for id = 1:length(schedTasksQueue)
    item = schedTasksQueue{id};
    if isRunTask(item) && strcmp(item.fName, fName)
      foundID = id;
      break;
    endif
  endfor
endfunction