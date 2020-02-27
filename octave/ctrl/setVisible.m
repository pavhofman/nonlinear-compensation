function changed = setVisible(items, visible)
  changed = false;
  for id = 1:length(items)
    item = items(id);
    isVisible = strcmp(get(item, 'visible'), 'on');
    if visible ~= isVisible
      set(item, 'visible', ifelse(visible, 'on', 'off'));
      changed = true;
    endif
  endfor
endfunction