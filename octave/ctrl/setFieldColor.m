function changed = setFieldColor(field, newColor)
  changed = false;
  shownColor = get(field, 'foregroundcolor');
  if ~isequal(shownColor, newColor)
    set(field, 'foregroundcolor', newColor);
    changed = true;
  endif
endfunction