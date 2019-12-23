function schedItem = checkSwitchWindow(adapterStruct, nextLabel, abortLabel, errorLabel, schedItem)
  global functionAborted;
  if ~isna(functionAborted)
    if functionAborted
      schedItem.newLabel = abortLabel;
    else
      schedItem.newLabel = nextLabel;
    endif
  endif
endfunction