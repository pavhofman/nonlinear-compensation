function addTask(taskFName, label)
  global taskFNames;
  global taskLabels;
  global taskLabelsBox;
  global abortTasksBtn;

  if isempty(taskFNames)
    % new task series
    clearOutBox();
  end
  
  taskFNames(end + 1) = taskFName;
  taskLabels(end + 1) = label;
  set(taskLabelsBox, 'string', taskLabels);

  % showing ABORT btn
  setVisible(abortTasksBtn, true);
end