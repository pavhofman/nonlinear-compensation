function removeTaskName(name)
  global taskNames;
  global taskNamesBox;
  
  taskNames = taskNames(~strcmp(taskNames, name));
  set(taskNamesBox, 'string', taskNames);    
endfunction