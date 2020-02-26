function schedItem = checkAdapterPanel(adapterStruct, nextLabel, abortLabel, errorLabel, schedItem)
  global adapterContinue;
  if adapterContinue
    % resetting flag
    adapterContinue = false;
    % and continuing
    schedItem.newLabel = nextLabel;
  endif
endfunction