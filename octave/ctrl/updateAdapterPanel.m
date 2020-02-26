function updateAdapterPanel(title, showContBtn)
  global adapterStruct;
  % updating panel items
  setFieldString(adapterStruct.msgBox, title);

  setChecked(adapterStruct.outCheckbox, adapterStruct.out)

  radio = ifelse(adapterStruct.calibrate, adapterStruct.calInRadio, adapterStruct.dutInRadio);
  setRadio(adapterStruct.inRGroup, radio)

  radio = ifelse(adapterStruct.vd, adapterStruct.vdRadio, adapterStruct.lpfRadio);
  setRadio(adapterStruct.vdlpRGroup, radio)

  %   reqLevel enabled only when no task running
  global taskFNames;
  setEnabled(adapterStruct.vdLevel, isempty(taskFNames));

  % CONTINUE button enabled if not using relays
  setVisible(adapterStruct.contBtn, showContBtn && ~adapterStruct.hasRelays);
endfunction
