function setEnabled(items, enable)
  for id = 1:length(items)
    item = items(id);
    isEnabled = strcmp(get(item, 'enable'), 'on');
    if enable ~= isEnabled
      set(item, 'enable', ifelse(enable, 'on', 'off'));
    endif
  endfor
endfunction