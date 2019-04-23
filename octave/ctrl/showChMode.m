function showChMode(bGroup, chMode, dirStruct)
  radio = get(bGroup, 'selectedobject');
  if isempty(radio) || get(radio, 'userdata') != chMode
    % not selected yet
    set(bGroup, 'selectedobject', dirStruct.modeRadios{chMode});
  endif
endfunction