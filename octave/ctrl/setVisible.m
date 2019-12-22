function setVisible(items, visible)
  for id = 1:length(items)
    item = items(id);
    isVisible = strcmp(get(item, 'visible'), 'on');
    if visible ~= isVisible
      if visible
        set(item, 'visible', 'on');
      else
        set(item, 'visible', 'off');
      endif
    endif
  endfor
endfunction