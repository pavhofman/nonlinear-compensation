function setFieldColor(field, newColor)
  shownColor = get(field, 'foregroundcolor');
  if ~isequal(shownColor, newColor)
    set(field, 'foregroundcolor', newColor);
  endif
endfunction