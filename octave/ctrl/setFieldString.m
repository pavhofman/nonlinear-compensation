function setFieldString(field, newText)
  shownText = get(field, 'string');
  if ~isequal(shownText, newText)
    set(field, 'string', newText);
  endif
endfunction
