function result = isRunTask(schedTask)
  if isfield(schedTask, 'runFunc')
    result = true;    
  else
    result = false;
  end
end