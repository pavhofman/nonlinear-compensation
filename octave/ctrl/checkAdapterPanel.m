function schedTask = checkAdapterPanel(adapterStruct, nextLabel, abortLabel, errorLabel, schedTask)
  global switchesSet;
  if switchesSet
    % switches set, user confirned with CONTINUE button
    % resetting flag
    switchesSet = false;
    % and continuing
    schedTask.newLabel = nextLabel;
  endif
endfunction