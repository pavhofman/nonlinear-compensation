function removeTask(fName, label)
  global taskFNames;
  global taskLabels;
  global taskLabelsBox;

  taskFNames = taskFNames(~strcmp(taskFNames, fName));
  taskLabels = taskLabels(~strcmp(taskLabels, label));
  set(taskLabelsBox, 'string', taskLabels);

  if isempty(taskLabels)
    updateAdapterPanel('', false);
    % hiding ABORT btn
    global abortTasksBtn;
    setVisible(abortTasksBtn, false);
  endif
endfunction