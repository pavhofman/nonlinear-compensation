% creates new scheduler item to be added into schedQueue
function s = createSchedItem(getLabelFunc, fname)
  s = struct();
  s.fname = fname;
  s.getLabel = getLabelFunc;
endfunction