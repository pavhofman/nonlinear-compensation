function updateAdapterPanel(title, showContBtn)
  global adapterStruct;
  % updating panel items
  % not checking changed status
  setFieldString(adapterStruct.msgBox, title);

  changed = setChecked(adapterStruct.outCheckbox, adapterStruct.out);

  radio = ifelse(adapterStruct.in, adapterStruct.dutInRadio, adapterStruct.calInRadio);
  changed |= setRadio(adapterStruct.inRGroup, radio);

  radio = ifelse(adapterStruct.calibLPF, adapterStruct.calibLpfRadio, adapterStruct.calibVdRadio);
  changed |= setRadio(adapterStruct.calibVdlpRGroup, radio);

  radio = ifelse(adapterStruct.lpf == 1, adapterStruct.lpf1Radio, adapterStruct.lpf2Radio);
  changed |= setRadio(adapterStruct.lpfRGroup, radio);

  %   reqLevel enabled only when no task running
  global taskFNames;
  % not checking changed status
  setEnabled(adapterStruct.vdLevel, isempty(taskFNames));

  adapterStruct.switchesChanged |= changed;
  % CONTINUE button
  if showContBtn
    if changed
      % some change detected, i.e. manual action required - showing confirmation/continue button
      % enabled if not using relays
      setVisible(adapterStruct.contBtn, ~adapterStruct.hasRelays);
    else
      % no change detected, not showing the CONTINUE button, but sending its click
      adapterStruct.switchesSet = true;
    endif
  endif
endfunction