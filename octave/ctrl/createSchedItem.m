% creates new scheduler item to be added into schedQueue
function s = createSchedItem(fname, getNextPointerFunc)
  s = struct();
  s.getNextPointer = getNextPointerFunc;  
  s.keepInQueue = false;
  s.newLabel = NA;
  s.fName = fname;
endfunction