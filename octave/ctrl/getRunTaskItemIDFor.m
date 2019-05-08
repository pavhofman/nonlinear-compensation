function foundID = getRunTaskItemIDFor(fName)
  global schedQueue;  
  foundID = [];
  for id = 1:length(schedQueue)
    item = schedQueue{id};
    if isRunTaskItem(item) && strcmp(item.fName, fName)
      foundID = id;
      break;
    endif
  endfor
endfunction