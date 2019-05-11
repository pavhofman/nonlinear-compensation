function abortLastTask()
  global fNameToAbort;
  global taskFNames;
  
  if ~isempty(taskFNames)
    fNameToAbort = taskFNames{end};
  endif
endfunction

