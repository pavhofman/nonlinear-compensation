function changed = setFieldTitle(field, newText)
  changed = false;
  shownText = get(field, 'title');
  if ~isequal(shownText, newText)
    set(field, 'title', newText);
    changed = true;
  endif
endfunction
