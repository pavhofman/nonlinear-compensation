function updateAdapterPanel(title, adapterStruct, showContBtn)
  persistent LEVEL_FORMAT = '%6.4f';
  % updating panel items
  setFieldString(adapterStruct.msgBox, title);

  setChecked(adapterStruct.outCheckbox, adapterStruct.out)

  radio = merge(adapterStruct.calibrate, adapterStruct.calInRadio, adapterStruct.dutInRadio);
  setRadio(adapterStruct.inRGroup, radio)

  radio = merge(adapterStruct.vd, adapterStruct.vdRadio, adapterStruct.lpfRadio);
  setRadio(adapterStruct.vdlpRGroup, radio)

  if ~isempty(adapterStruct.reqLevels)
    % just the first item
    setFieldString(adapterStruct.vdLevel, num2str(adapterStruct.reqLevels(1), LEVEL_FORMAT));
  endif

  % CONTINUE button enabled if not using relays
  setVisible(adapterStruct.contBtn, showContBtn && ~adapterStruct.hasRelays);
endfunction
