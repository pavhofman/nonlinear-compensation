function addTaskName(name)
  global taskNames;
  global taskNamesBox;
  
  taskNames(end + 1) = name;
  set(taskNamesBox, 'string', taskNames);  
endfunction