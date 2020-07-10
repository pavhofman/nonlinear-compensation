function updateAdapterPanel(init = false)
  global adapterStruct;
  global taskFNames;

  noTasksRunning = isempty(taskFNames);

  % updating panel items
  % not checking changed status
  newLabelShown = setFieldString(adapterStruct.msgBox, adapterStruct.label) && ~isempty(adapterStruct.label);

  switchesChanged = setChecked(adapterStruct.outCheckbox, adapterStruct.out);
  % OUT can be manually enabled at any time

  radio = ifelse(adapterStruct.in, adapterStruct.dutInRadio, adapterStruct.calInRadio);
  switchesChanged |= setRadio(adapterStruct.inRGroup, radio);
  setEnabled([adapterStruct.dutInRadio, adapterStruct.calInRadio], noTasksRunning && adapterStruct.hasRelays);


  radio = ifelse(adapterStruct.calibLPF, adapterStruct.calibLpfRadio, adapterStruct.calibVdRadio);
  switchesChanged |= setRadio(adapterStruct.calibVdlpRGroup, radio);
  % calibration VD/LPF - enabled when no tasks and switched to calibration
  setEnabled([adapterStruct.calibLpfRadio, adapterStruct.calibVdRadio], noTasksRunning && ~adapterStruct.in && adapterStruct.hasRelays);

  if adapterStruct.has2LPFs
    radio = ifelse(adapterStruct.lpf == 1, adapterStruct.lpf1Radio, adapterStruct.lpf2Radio);
    switchesChanged |= setRadio(adapterStruct.lpfRGroup, radio);
    % LPF1/2 - enabled when no tasks
    setEnabled([adapterStruct.lpf1Radio, adapterStruct.lpf2Radio], adapterStruct.hasRelays && noTasksRunning);
  endif

  %   reqLevel enabled only when no task running
  % not checking changed status
  setEnabled(adapterStruct.vdLevel, noTasksRunning);


  if adapterStruct.has2VDs
    radio = ifelse(adapterStruct.vd == 1, adapterStruct.vd1Radio, adapterStruct.vd2Radio);
    switchesChanged |= setRadio(adapterStruct.vdRGroup, radio);
    % VD1/2 - enabled when no tasks
    setEnabled([adapterStruct.vd1Radio, adapterStruct.vd2Radio], adapterStruct.hasRelays && noTasksRunning);
  endif

  adapterStruct.switchesChanged |= ~init && switchesChanged;
  % CONTINUE button
  if adapterStruct.hasContButton
    % showing confirmation/continue button if some switch change detected (incl. changed nonempty label), i.e. manual action required
    setVisible(adapterStruct.contBtn, ~init && (switchesChanged  || newLabelShown));
  endif
endfunction