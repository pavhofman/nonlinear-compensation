function addTask(fName, label)
  global taskFNames;
  global taskLabels;
  global taskLabelsBox;
  global abortTasksButton;
  
  taskFNames(end + 1) = fName;
  taskLabels(end + 1) = label;
  set(taskLabelsBox, 'string', taskLabels);

  setEnabled(abortTasksButton, true);
endfunction