function abortLastTask()
  global taskFNameToAbort;
  global taskFNames;
  
  if ~isempty(taskFNames)
    taskFNameToAbort = taskFNames{end};
  end
end

