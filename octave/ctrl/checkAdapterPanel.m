function schedTask = checkAdapterPanel(adapterStruct, nextLabel, abortLabel, errorLabel, schedTask)
  global adapterContinue;
  if adapterContinue
    % resetting flag
    adapterContinue = false;
    % and continuing
    schedTask.newLabel = nextLabel;
  endif
endfunction