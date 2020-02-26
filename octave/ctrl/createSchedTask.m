% creates new scheduler item to be added into schedTasksQueue
function s = createSchedTask(fname, getNextPointerFunc)
  s = struct();
  s.getNextPointer = getNextPointerFunc;  
  s.keepInQueue = false;
  s.newLabel = NA;
  s.taskFName = fname;
endfunction