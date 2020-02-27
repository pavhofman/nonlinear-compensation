function changed = setRadio(rGroup, radio)
  changed = false;
  curRadio = get(rGroup, 'selectedobject');
  if isempty(curRadio) || radio ~= curRadio
    set(rGroup, 'selectedobject', radio);
    changed = true;
  endif
endfunction