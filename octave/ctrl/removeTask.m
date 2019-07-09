function removeTask(fName, label)
  global taskFNames;
  global taskLabels;
  global taskLabelsBox;

  taskFNames = taskFNames(~strcmp(taskFNames, fName));
  taskLabels = taskLabels(~strcmp(taskLabels, label));
  set(taskLabelsBox, 'string', taskLabels);

  if isempty(taskLabels)
    global abortTasksButton;
    setEnabled(abortTasksButton, false);
  endif
endfunction