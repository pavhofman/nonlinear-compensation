function foundID = getRunTaskIDFor(taskFName)
  global schedTasksQueue;
  foundID = [];
  for id = 1:length(schedTasksQueue)
    item = schedTasksQueue{id};
    if isRunTask(item) && strcmp(item.taskFName, taskFName)
      foundID = id;
      break;
    endif
  endfor
endfunction