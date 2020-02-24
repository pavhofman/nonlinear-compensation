function schedItem = checkAdapterPanel(adapterStruct, nextLabel, abortLabel, errorLabel, schedItem)
  global adapterContinue;
  if adapterContinue
    schedItem.newLabel = nextLabel;
    % resetting
    adapterContinue = false;
  endif
endfunction