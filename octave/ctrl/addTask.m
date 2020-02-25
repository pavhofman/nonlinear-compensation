function addTask(fName, label)
  global taskFNames;
  global taskLabels;
  global taskLabelsBox;
  global abortTasksBtn;

  if isempty(taskFNames)
    % new task series
    clearOutBox();
  endif
  
  taskFNames(end + 1) = fName;
  taskLabels(end + 1) = label;
  set(taskLabelsBox, 'string', taskLabels);

  % showing ABORT btn
  setVisible(abortTasksBtn, true);
endfunction