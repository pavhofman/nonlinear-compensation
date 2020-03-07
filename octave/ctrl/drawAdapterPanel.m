function drawAdapterPanel(fig, x, y, height)
  persistent MSG_HEIGHT = 0.5;
  global adapterStruct;

  panel = uipanel(fig,
              'title', 'Adapter',
              'position', [x, y, 1, height]);

  MSG_Y = 1- MSG_HEIGHT;
  adapterStruct.msgBox =   uicontrol(panel,
                             'style', 'text',
                             'units', 'normalized',
                             'verticalalignment', 'bottom',
                             'horizontalalignment', 'left',
                             % no relays = manual switches => instructions => red
                             'foregroundcolor', ifelse(adapterStruct.hasRelays, 'black', 'red'),
                             'position', [0, MSG_Y, 0.95, MSG_HEIGHT - 0.1]);

  % panel for control elements
  ctrlPanel = uipanel(panel,
              'bordertype', 'none',
              'position', [0, 0, 1, MSG_Y]);


  adapterStruct.outCheckbox = uicontrol (ctrlPanel ,
                             'style', 'checkbox',
                             'units', 'normalized',
                             'string', 'OUT DUT',
                             'value', 0,
                             'verticalalignment', 'middle',
                             'enable', ifelse(adapterStruct.hasRelays, 'on', 'off'),
                             'callback', @clbkSetOut,
                             'position', [0, 0, 0.2, 1]);

  adapterStruct.inRGroup = uibuttongroup (ctrlPanel ,
                               'units', 'normalized',
                               'selectionchangedfcn', @clbkSetIn,
                               'position', [0.2, 0, 0.15, 1]);

  adapterStruct.dutInRadio = uicontrol (adapterStruct.inRGroup,
            'style', 'radiobutton',
            'string', 'IN DUT',
            'units', 'normalized',
            'enable', ifelse(adapterStruct.hasRelays, 'on', 'off'),
            'Position', [0, 0, 0.5, 1]);


  adapterStruct.calInRadio = uicontrol (adapterStruct.inRGroup,
            'style', 'radiobutton',
            'string', 'IN Calib',
            'units', 'normalized',
            'enable', ifelse(adapterStruct.hasRelays, 'on', 'off'),
            'Position', [0.5, 0, 0.5, 1]);


  adapterStruct.vdlpRGroup = uibuttongroup (ctrlPanel ,
                               'units', 'normalized',
                               'selectionchangedfcn', @clbkSetVdlp,
                               'position', [0.4, 0, 0.15, 1]);

  adapterStruct.lpfRadio = uicontrol (adapterStruct.vdlpRGroup,
            'style', 'radiobutton',
            'string', 'LPF',
            'units', 'normalized',
            'enable', ifelse(adapterStruct.hasRelays, 'on', 'off'),
            'Position', [0, 0, 0.5, 1]);

  adapterStruct.vdRadio = uicontrol (adapterStruct.vdlpRGroup,
            'style', 'radiobutton',
            'string', 'VD',
            'units', 'normalized',
            'enable', ifelse(adapterStruct.hasRelays, 'on', 'off'),
            'Position', [0.4, 0, 0.5, 1]);


  adapterStruct.vdLevel = uicontrol(ctrlPanel,
      'style', 'edit',
      'backgroundcolor', 'white',
      'units', 'normalized',
      'tooltipstring', 'Enter required VD level in dB < 0',
      'visible', ifelse(adapterStruct.hasStepper, 'on', 'off'),
      'callback', @clbkSetVDLevel,
      'position', [0.55, 0, 0.07, 0.95]);


  adapterStruct.contBtn = uicontrol (ctrlPanel ,
                                'style', 'pushbutton',
                                'units', 'normalized',
                                'string', 'Set, continue',
                                'verticalalignment', 'middle',
                                'visible', 'off',
                                'callback', @clbkAdapterContinue,
                                'position', [0.68,  0.1, 0.1, 0.9]);

endfunction

function clbkSetOut(src, data)
  global adapterStruct;
  adapterStruct.out = get(src, 'value');
  % this control is enabled only when having relays
  updateRelays();
endfunction

function clbkSetVdlp(src, data)
  global adapterStruct;
  radio = get(src, 'selectedobject');
  adapterStruct.lpf = radio == adapterStruct.lpfRadio;
  % this control is enabled only when having relays
  updateRelays();
endfunction

function clbkSetIn(src, data)
  global adapterStruct;
  radio = get(src, 'selectedobject');
  adapterStruct.in = radio == adapterStruct.dutInRadio;
  % this control is enabled only when having relays
  updateRelays();
endfunction

function clbkAdapterContinue(src, data)
  global adapterStruct;
  adapterStruct.switchesSet = true;
  % again hiding
  setVisible(adapterStruct.contBtn, false);

  % clearing msgBox
  setFieldString(adapterStruct.msgBox, {});
endfunction

function clbkSetVDLevel(src, data)
  % checks
  str = get(src, 'String');
  value = str2double(str);
  if isnan(value)
      set(src, 'String',' 0.');
      warndlg('VD level must be numerical in dB');
      return;
  elseif value > 0
    warndlg('VD level must be < 0dB');
    return;
  endif

  global adapterStruct;
  adapterStruct.reqLevels = db2mag(value);
  adapterStruct.switchesSet = true;
  % adjusting the stepper
  setVDLevelSched();
endfunction