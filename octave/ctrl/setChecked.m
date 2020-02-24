function setChecked(chbox, value)
  curValue = get(chbox, 'value');
  if value ~= curValue
    % change
    set(chbox, 'value', value);
  endif
endfunction