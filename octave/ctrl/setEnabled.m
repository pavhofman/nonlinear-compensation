function setEnabled(items, enable)
  for id = 1:length(items)
    item = items(id);
    isEnabled = strcmp(get(item, 'enable'), 'on');
    if enable != isEnabled
      if enable
        set(item, 'enable', 'on');
      else
        set(item, 'enable', 'off');
      endif
    endif
  endfor
endfunction