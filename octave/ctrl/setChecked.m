function changed = setChecked(chbox, value)
  changed = false;
  curValue = get(chbox, 'value');
  if value ~= curValue
    % change
    set(chbox, 'value', value);
    changed = true;
  endif
endfunction