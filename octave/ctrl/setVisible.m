function setVisible(item, visible)
  isVisible = strcmp(get(item, 'visible'), 'on');
  if visible != isVisible
    if visible
      set(item, 'visible', 'on');
    else
      set(item, 'visible', 'off');
    endif
  endif
endfunction