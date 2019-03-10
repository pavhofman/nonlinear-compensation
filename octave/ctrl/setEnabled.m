function setEnabled(item, enable)
  isEnabled = strcmp(get(item, 'enable'), 'on');
  if enable != isEnabled
    if enable
      set(item, 'enable', 'on');
    else
      set(item, 'enable', 'off');
    endif
  endif
endfunction