function changed = setFieldString(field, newText)
  changed = false;
  shownText = get(field, 'string');
  if ~isequal(shownText, newText)
    set(field, 'string', newText);
    changed = true;
  end
end
