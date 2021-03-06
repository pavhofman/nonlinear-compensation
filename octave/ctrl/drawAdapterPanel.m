function drawAdapterPanel(fig, x, y, width, height)
  global adapterStruct;
  global ardStruct;

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


  CLEARANCE = 0.01;
  OUT_CHCKBX_WIDTH = 0.12;
  adapterStruct.outCheckbox = uicontrol (ctrlPanel,
                             'style', 'checkbox',
                             'units', 'normalized',
                             'string', 'OUT DUT',
                             'value', 0,
                             'verticalalignment', 'middle',
                             'enable', ifelse(isempty(ardStruct.outPin), 'off', 'on'),
                             'callback', @clbkSetOut,
                             'position', [0, 0, OUT_CHCKBX_WIDTH, 1]);


  IN_RGROUP_WIDTH = 0.21;
  inRGroupX = OUT_CHCKBX_WIDTH + CLEARANCE;
  adapterStruct.inRGroup = uibuttongroup (ctrlPanel ,
                               'units', 'normalized',
                               'selectionchangedfcn', @clbkSetIn,
                               'position', [inRGroupX, 0, IN_RGROUP_WIDTH, 1]);

  adapterStruct.dutInRadio = uicontrol (adapterStruct.inRGroup,
            'style', 'radiobutton',
            'string', 'IN DUT',
            'units', 'normalized',
            'enable', ifelse(isempty(ardStruct.inPin), 'off', 'on'),
            'Position', [0, 0, 0.5, 1]);


  adapterStruct.calInRadio = uicontrol (adapterStruct.inRGroup,
            'style', 'radiobutton',
            'string', 'IN Calib',
            'units', 'normalized',
            'enable', ifelse(isempty(ardStruct.inPin), 'off', 'on'),
            'Position', [0.5, 0, 0.5, 1]);


  CALIB_VDLP_RGROUP_WIDTH = 0.15;
  calibVdlpRGroupX = inRGroupX + IN_RGROUP_WIDTH + CLEARANCE;
  adapterStruct.calibVdlpRGroup = uibuttongroup (ctrlPanel ,
                               'units', 'normalized',
                               'selectionchangedfcn', @clbkSetVdlp,
                               'position', [calibVdlpRGroupX, 0, CALIB_VDLP_RGROUP_WIDTH, 1]);

  adapterStruct.vdLpfRadio = uicontrol (adapterStruct.calibVdlpRGroup,
            'style', 'radiobutton',
            'string', 'LPF',
            'units', 'normalized',
            'enable', ifelse(isempty(ardStruct.vdLpfPin), 'off', 'on'),
            'Position', [0, 0, 0.5, 1]);

  adapterStruct.calibVdRadio = uicontrol (adapterStruct.calibVdlpRGroup,
            'style', 'radiobutton',
            'string', 'VD',
            'units', 'normalized',
            'enable', ifelse(isempty(ardStruct.vdLpfPin), 'off', 'on'),
            'Position', [0.5, 0, 0.5, 1]);


  VD_LEVEL_WIDTH = 0.09;
  vdLevelX = calibVdlpRGroupX + CALIB_VDLP_RGROUP_WIDTH + CLEARANCE/5;
  adapterStruct.vdLevel = uicontrol(ctrlPanel,
      'style', 'edit',
      'backgroundcolor', 'white',
      'units', 'normalized',
      'verticalalignment', 'middle',
      'tooltipstring', 'Enter required VD level in dB < 0',
      'visible', ifelse(adapterStruct.hasStepper, 'on', 'off'),
      'callback', ifelse(adapterStruct.isSE, @clbkSetVDLevel, @clbkSetBalVDLevels),
      'position', [vdLevelX, 0, VD_LEVEL_WIDTH, 0.95]);



  LPF_RGROUP_WIDTH = 0.15;
  lpfRGroupX = vdLevelX + VD_LEVEL_WIDTH + CLEARANCE;
  adapterStruct.lpfRGroup = uibuttongroup (ctrlPanel ,
                               'units', 'normalized',
                               'selectionchangedfcn', @clbkSetLpf,
                               'visible', ifelse(adapterStruct.has2LPFs, 'on', 'off'),
                               'position', [lpfRGroupX, 0, LPF_RGROUP_WIDTH, 1]);

  adapterStruct.lpf1Radio = uicontrol (adapterStruct.lpfRGroup,
            'style', 'radiobutton',
            'string', 'LPF1',
            'units', 'normalized',
            'visible', ifelse(adapterStruct.has2LPFs, 'on', 'off'),
            'enable', ifelse(isempty(ardStruct.lpfPin), 'off', 'on'),
            'Position', [0, 0, 0.5, 1]);

  adapterStruct.lpf2Radio = uicontrol (adapterStruct.lpfRGroup,
            'style', 'radiobutton',
            'string', 'LPF2',
            'units', 'normalized',
            'visible', ifelse(adapterStruct.has2LPFs, 'on', 'off'),
            'enable', ifelse(isempty(ardStruct.lpfPin), 'off', 'on'),
            'Position', [0.5, 0, 0.5, 1]);

  VD_RGROUP_WIDTH = 0.15;
  vdRGroupX = lpfRGroupX + LPF_RGROUP_WIDTH + CLEARANCE;
  adapterStruct.vdRGroup = uibuttongroup (ctrlPanel ,
                               'units', 'normalized',
                               'selectionchangedfcn', @clbkSetVd,
                               'visible', ifelse(adapterStruct.has2VDs && adapterStruct.isSE, 'on', 'off'),
                               'position', [vdRGroupX, 0, VD_RGROUP_WIDTH, 1]);

  adapterStruct.vd1Radio = uicontrol (adapterStruct.vdRGroup,
            'style', 'radiobutton',
            'string', 'VD1',
            'units', 'normalized',
            'visible', ifelse(adapterStruct.has2VDs && adapterStruct.isSE, 'on', 'off'),
            'enable', ifelse(isempty(ardStruct.vdPin), 'off', 'on'),
            'Position', [0, 0, 0.5, 1]);

  adapterStruct.vd2Radio = uicontrol (adapterStruct.vdRGroup,
            'style', 'radiobutton',
            'string', 'VD2',
            'units', 'normalized',
            'visible', ifelse(adapterStruct.has2VDs && adapterStruct.isSE, 'on', 'off'),
            'enable', ifelse(isempty(ardStruct.vdPin), 'off', 'on'),
            'Position', [0.5, 0, 0.5, 1]);


  adapterStruct.gndPMGroup = uibuttongroup (ctrlPanel ,
                               'units', 'normalized',
                               'visible', ifelse(adapterStruct.isSE, 'off', 'on'),
                               'position', [vdRGroupX, 0, VD_RGROUP_WIDTH, 1]);

  adapterStruct.gndPlusCheckbox = uicontrol (adapterStruct.gndPMGroup,
            'style', 'checkbox',
            'string', 'G+',
            'value', 0,
            'units', 'normalized',
            'visible', ifelse(adapterStruct.isSE, 'off', 'on'),
            'enable', ifelse(isempty(ardStruct.gndPlusPin), 'off', 'on'),
            'callback', @clbkSetGndPlus,
            'Position', [0, 0, 0.5, 1]);

  adapterStruct.gndMinusCheckbox = uicontrol (adapterStruct.gndPMGroup,
            'style', 'checkbox',
            'string', 'G-',
            'value', 0,
            'units', 'normalized',
            'visible', ifelse(adapterStruct.isSE, 'off', 'on'),
            'enable', ifelse(isempty(ardStruct.gndMinusPin), 'off', 'on'),
            'callback', @clbkSetGndMinus,
            'Position', [0.5, 0, 0.5, 1]);

  BTN_WIDTH = 0.05;
  btnX = vdRGroupX + VD_RGROUP_WIDTH + CLEARANCE;
  adapterStruct.contBtn = uicontrol (ctrlPanel ,
                                'style', 'pushbutton',
                                'units', 'normalized',
                                'string', 'Set',
                                'verticalalignment', 'middle',
                                'visible', 'off',
                                'callback', @clbkAdapterContinue,
                                'position', [btnX,  0.1, BTN_WIDTH, 0.9]);

  % setting initial values - in INIT mode
  updateAdapterPanel(true);
  adapterStruct.adapterPanelDrawn = true;

end

function clbkSetOut(src, data)
  global adapterStruct;
  adapterStruct.out = get(src, 'value');
  % this control is enabled only when having relays
  updateRelays();
end

function clbkSetGndPlus(src, data)
  global adapterStruct;
  adapterStruct.gndPlus = get(src, 'value');
  % this control is enabled only when having relays
  updateRelays();
end

function clbkSetGndMinus(src, data)
  global adapterStruct;
  adapterStruct.gndMinus = get(src, 'value');
  % this control is enabled only when having relays
  updateRelays();
end

function clbkSetVdlp(src, data)
  global adapterStruct;
  radio = get(src, 'selectedobject');
  adapterStruct.vdLpf = radio == adapterStruct.vdLpfRadio;
  % this control is enabled only when having relays
  updateRelays();
end

function clbkSetLpf(src, data)
  global adapterStruct;
  radio = get(src, 'selectedobject');
  adapterStruct.lpf = ifelse(radio == adapterStruct.lpf1Radio, 1, 2);
  % this control is enabled only when having relays
  updateRelays();
end

function clbkSetVd(src, data)
  global adapterStruct;
  radio = get(src, 'selectedobject');
  adapterStruct.vd = ifelse(radio == adapterStruct.vd1Radio, 1, 2);
  % this control is enabled only when having relays
  updateRelays();
end

function clbkSetIn(src, data)
  global adapterStruct;
  radio = get(src, 'selectedobject');
  adapterStruct.in = radio == adapterStruct.dutInRadio;
  % this control is enabled only when having relays
  updateRelays();
end

function clbkAdapterContinue(src, data)
  global adapterStruct;
  adapterStruct.switchesSet = true;
  % hiding contButton
  % clearing msgBox
  adapterStruct.label = '';
  updateAdapterPanel();
end

% return: if OK: value = number, if error: value = NA
function value = parseSingleNumber(str)
  value = str2double(str);
  if isnan(value)
      set(src, 'String',' 0.');
      warndlg('VD level must be numerical in dB');
      value = NA;
  elseif value > 0
    warndlg('VD level must be < 0dB');
    value = NA;
  end
end

function clbkSetVDLevel(src, data)
  % checks
  str = strtrim(get(src, 'String'));
  value = parseSingleNumber(str);
  if isna(value)
    % error
    return;
  end

  global adapterStruct;
  adapterStruct.reqVDLevel = db2mag(value);
  adapterStruct.switchesSet = true;
  % just in case
  updateAdapterPanel();
  % adjusting the stepper
  setVDLevelSched();
end

function clbkSetBalVDLevels(src, data)
  % checks
  str = strtrim(get(src, 'String'));
  strs = strsplit(str, {' ', ','});
  if length(strs) < 1 || length(strs) > 2
    % error
    warndlg('VD levels must be one or two numbers, separated by comma, in dB');
    return;
  else
    % correct count
    value1 = parseSingleNumber(strs{1});
    if isna(value1)
      return;
    end
    % first number OK
    dbValue1 = db2mag(value1);

    global adapterStruct;
    if length(strs) == 1
      % one number, same for both + and -
      adapterStruct.reqBalVDLevels = [dbValue1, dbValue1];
    else
      % 2 numbers
      value2 = parseSingleNumber(strs{2});
      if isna(value2)
        return;
      end
      % both OK, using both
      adapterStruct.reqBalVDLevels = [dbValue1, db2mag(value2)];
    end
  end

  adapterStruct.switchesSet = true;
  % just in case
  updateAdapterPanel();
  % adjusting the steppers
  setBalVDLevelsSched();
end