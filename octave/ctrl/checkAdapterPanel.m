function schedTask = checkAdapterPanel(nextLabel, abortLabel, errorLabel, schedTask)
  global adapterStruct;
  if adapterStruct.switchesSet
    % switches set, user confirned with CONTINUE button
    % resetting flag
    adapterStruct.switchesSet = false;
    % and continuing
    schedTask.newLabel = nextLabel;
  endif
endfunction