function schedTask = checkAdapterPanel(adapterStruct, nextLabel, abortLabel, errorLabel, schedTask)
  if adapterStruct.switchesSet
    % switches set, user confirned with CONTINUE button
    % resetting flag
    adapterStruct.switchesSet = false;
    % and continuing
    schedTask.newLabel = nextLabel;
  endif
endfunction