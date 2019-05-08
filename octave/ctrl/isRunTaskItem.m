function result = isRunTaskItem(schedItem)
  if isfield(schedItem, 'runFunc')
    result = true;    
  else
    result = false;
  endif
endfunction