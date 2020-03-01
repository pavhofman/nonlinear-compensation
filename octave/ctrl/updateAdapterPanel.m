function updateAdapterPanel(title, showContBtn)
  global adapterStruct;
  % updating panel items
  % not checking changed status
  setFieldString(adapterStruct.msgBox, title);

  changed = setChecked(adapterStruct.outCheckbox, adapterStruct.out);

  radio = ifelse(adapterStruct.in, adapterStruct.dutInRadio, adapterStruct.calInRadio);
  changed |= setRadio(adapterStruct.inRGroup, radio);

  radio = ifelse(adapterStruct.lpf, adapterStruct.lpfRadio, adapterStruct.vdRadio);
  changed |= setRadio(adapterStruct.vdlpRGroup, radio);

  %   reqLevel enabled only when no task running
  global taskFNames;
  % not checking changed status
  setEnabled(adapterStruct.vdLevel, isempty(taskFNames));

  % CONTINUE button
  if showContBtn
    if changed
      % some change detected, i.e. manual action required - showing confirmation/continue button
      % enabled if not using relays
      setVisible(adapterStruct.contBtn, ~adapterStruct.hasRelays);
    else
      % no change detected, not showing the CONTINUE button, but sending its click
      global adapterContinue;
      adapterContinue = true;
    endif
  endif
endfunction