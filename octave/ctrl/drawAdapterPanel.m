function drawAdapterPanel(fig, x, y, width, height)
  global adapterStruct;

  panel = uipanel(fig,
              'title', 'Adapter',
              'position', [x, y, width, height]);

  MSG_HEIGHT = 0.5;
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


  CLEARANCE = 0.03;
  OUT_CHCKBX_WIDTH = 0.14;
  adapterStruct.outCheckbox = uicontrol (ctrlPanel,
                             'style', 'checkbox',
                             'units', 'normalized',
                             'string', 'OUT DUT',
                             'value', 0,
                             'verticalalignment', 'middle',
                             'enable', ifelse(adapterStruct.hasRelays, 'on', 'off'),
                             'callback', @clbkSetOut,
                             'position', [0, 0, OUT_CHCKBX_WIDTH, 1]);


  IN_RGROUP_WIDTH = 0.25;
  inRGroupX = OUT_CHCKBX_WIDTH + CLEARANCE;
  adapterStruct.inRGroup = uibuttongroup (ctrlPanel ,
                               'units', 'normalized',
                               'selectionchangedfcn', @clbkSetIn,
                               'position', [inRGroupX, 0, IN_RGROUP_WIDTH, 1]);

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


  VDLP_RGROUP_WIDTH = 0.18;
  vdlpRGroupX = inRGroupX + IN_RGROUP_WIDTH + CLEARANCE;
  adapterStruct.vdlpRGroup = uibuttongroup (ctrlPanel ,
                               'units', 'normalized',
                               'selectionchangedfcn', @clbkSetVdlp,
                               'position', [vdlpRGroupX, 0, VDLP_RGROUP_WIDTH, 1]);

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
            'Position', [0.5, 0, 0.5, 1]);


  VD_LEVEL_WIDTH = 0.1;
  vdLevelX = vdlpRGroupX + VDLP_RGROUP_WIDTH + CLEARANCE/5;
  adapterStruct.vdLevel = uicontrol(ctrlPanel,
      'style', 'edit',
      'backgroundcolor', 'white',
      'units', 'normalized',
      'verticalalignment', 'middle',
      'tooltipstring', 'Enter required VD level in dB < 0',
      'visible', ifelse(adapterStruct.hasStepper, 'on', 'off'),
      'callback', @clbkSetVDLevel,
      'position', [vdLevelX, 0, VD_LEVEL_WIDTH, 0.95]);


  BTN_WIDTH = 0.2;
  btnX = vdLevelX + VD_LEVEL_WIDTH + CLEARANCE;
  adapterStruct.contBtn = uicontrol (ctrlPanel ,
                                'style', 'pushbutton',
                                'units', 'normalized',
                                'string', 'Set, continue',
                                'verticalalignment', 'middle',
                                'visible', 'off',
                                'callback', @clbkAdapterContinue,
                                'position', [btnX,  0.1, BTN_WIDTH, 0.9]);

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