function adapterStruct = drawAdapterPanel(fig, y, height)
  persistent MSG_HEIGHT = 0.5;
  adapterStruct = initAdapterStruct();

  panel = uipanel(fig,
              'title', 'Adapter',
              'position', [0, y, 1, height]);

  MSG_Y = 1- MSG_HEIGHT;
  adapterStruct.msgBox =   uicontrol(panel,
                             'style', 'text',
                             'units', 'normalized',
                             'verticalalignment', 'bottom',
                             'horizontalalignment', 'left',
                             'foregroundcolor', 'red',
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
                             'enable', merge(adapterStruct.hasRelays, 'on', 'off'),
                             'callback', @clbkSetOut,
                             'position', [0, 0, 0.3, 1]);

  adapterStruct.inRGroup = uibuttongroup (ctrlPanel ,
                               'units', 'normalized',
                               'selectionchangedfcn', @clbkSetIn,
                               'position', [0.2, 0, 0.2, 1]);

  adapterStruct.dutInRadio = uicontrol (adapterStruct.inRGroup,
            'style', 'radiobutton',
            'string', 'IN DUT',
            'units', 'normalized',
            'enable', merge(adapterStruct.hasRelays, 'on', 'off'),
            'Position', [0, 0, 0.5, 1]);


  adapterStruct.calInRadio = uicontrol (adapterStruct.inRGroup,
            'style', 'radiobutton',
            'string', 'IN Calib',
            'units', 'normalized',
            'enable', merge(adapterStruct.hasRelays, 'on', 'off'),
            'Position', [0.5, 0, 0.5, 1]);


  adapterStruct.vdlpRGroup = uibuttongroup (ctrlPanel ,
                               'units', 'normalized',
                               'selectionchangedfcn', @clbkSetVdlp,
                               'position', [0.5, 0, 0.15, 1]);

  adapterStruct.lpfRadio = uicontrol (adapterStruct.vdlpRGroup,
            'style', 'radiobutton',
            'string', 'LPF',
            'units', 'normalized',
            'enable', merge(adapterStruct.hasRelays, 'on', 'off'),
            'Position', [0, 0, 0.5, 1]);

  adapterStruct.vdRadio = uicontrol (adapterStruct.vdlpRGroup,
            'style', 'radiobutton',
            'string', 'VD',
            'units', 'normalized',
            'enable', merge(adapterStruct.hasRelays, 'on', 'off'),
            'Position', [0.4, 0, 0.5, 1]);


  adapterStruct.vdLevel = uicontrol(ctrlPanel,
      'style', 'edit',
      'backgroundcolor', 'white',
      'units', 'normalized',
      'tooltipstring', 'Enter required VD level (<0, 1>)',
      'visible', merge(adapterStruct.hasStepper, 'on', 'off'),
      'callback', @clbkSetVDLevel,
      'position', [0.65, 0, 0.07, 0.95]);


  adapterStruct.contBtn = uicontrol (ctrlPanel ,
                                'style', 'pushbutton',
                                'units', 'normalized',
                                'string', 'Set, continue',
                                'verticalalignment', 'middle',
                                'visible', 'off',
                                'callback', @clbkAdapterContinue,
                                'position', [0.8,  0.1, 0.1, 0.9]);

  % setting initial values, not enabling CONTINUE button
  updateAdapterPanel('', adapterStruct, false);
endfunction

function clbkSetOut(src, data)
  global adapterStruct;
  adapterStruct.out = get(src, 'value');
endfunction

function clbkSetVdlp(src, data)
  global adapterStruct;
  radio = get(src, 'selectedobject');
  adapterStruct.vd = radio == adapterStruct.vdRadio;
endfunction

function clbkSetIn(src, data)
  global adapterStruct;
  radio = get(src, 'selectedobject');
  adapterStruct.calibrate = radio == adapterStruct.calInRadio;
endfunction

function clbkAdapterContinue(src, data)
  global adapterContinue;
  adapterContinue = true;
  global adapterStruct;
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
      warndlg('VD level must be numerical');
  elseif value < 0 || value >= 1
    warndlg('VD level must be between 0 and 1');
  endif

  global adapterStruct;
  adapterStruct.reqLevels = value;
  % TODO - starting the stepper
endfunction


