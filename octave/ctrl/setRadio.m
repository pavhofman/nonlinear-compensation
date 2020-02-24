function setRadio(rGroup, radio)
  curRadio = get(rGroup, 'selectedobject');
  if isempty(curRadio) || radio ~= curRadio
    set(rGroup, 'selectedobject', radio);
  endif
endfunction