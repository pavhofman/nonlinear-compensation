% creates new scheduler item to be added into schedTasksQueue. Function abortFunc empty by default
function s = createSchedTask(fname, getNextPointerFunc, abortFunc = @() [])
  s = struct();
  s.getNextPointer = getNextPointerFunc;  
  s.keepInQueue = false;
  s.newLabel = NA;
  s.taskFName = fname;
  s.abortFunc = abortFunc;
endfunction