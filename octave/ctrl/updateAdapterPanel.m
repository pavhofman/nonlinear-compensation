function updateAdapterPanel()
  global adapterStruct;
  global taskFNames;

  noTasksRunning = isempty(taskFNames);

  % updating panel items
  % not checking changed status
  setFieldString(adapterStruct.msgBox, adapterStruct.label);

  changed = setChecked(adapterStruct.outCheckbox, adapterStruct.out);
  % OUT can be manually enabled at any time

  radio = ifelse(adapterStruct.in, adapterStruct.dutInRadio, adapterStruct.calInRadio);
  changed |= setRadio(adapterStruct.inRGroup, radio);
  setEnabled([adapterStruct.dutInRadio, adapterStruct.calInRadio], noTasksRunning);


  radio = ifelse(adapterStruct.calibLPF, adapterStruct.calibLpfRadio, adapterStruct.calibVdRadio);
  changed |= setRadio(adapterStruct.calibVdlpRGroup, radio);
  % calibration VD/LPF - enabled when no tasks and switched to calibration
  setEnabled([adapterStruct.calibLpfRadio, adapterStruct.calibVdRadio], noTasksRunning && ~adapterStruct.in);

  radio = ifelse(adapterStruct.lpf == 1, adapterStruct.lpf1Radio, adapterStruct.lpf2Radio);
  changed |= setRadio(adapterStruct.lpfRGroup, radio);
  % LPF1/2 - enabled when no tasks, switched to calibration and LPF
  setEnabled([adapterStruct.lpf1Radio, adapterStruct.lpf2Radio], noTasksRunning && ~adapterStruct.in && adapterStruct.calibLPF);

  %   reqLevel enabled only when no task running
  % not checking changed status
  setEnabled(adapterStruct.vdLevel, noTasksRunning);

  adapterStruct.switchesChanged |= changed;
  % CONTINUE button
  if adapterStruct.showContinueBtn
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