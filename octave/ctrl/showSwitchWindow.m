function showSwitchWindow(label, swStruct)
  persistent WIDTH = 800;
  persistent HEIGHT = 400;
  
  global POS_X;
  global POS_Y;
  
  fig = figure('position', [POS_X + 10, POS_Y + 10, WIDTH, HEIGHT]);
  set(fig, 'menubar', 'none');
  set(fig, "toolbar", "none");
  set(fig, 'DeleteFcn', @(h, e) closeSwWindow(fig));

  uicontrol(fig, 'style', 'text',
    'string', label,
    'backgroundcolor', 'white',
    'units', 'normalized',
    'position', [0.05 0.90 0.95 0.1]);

  panel = uipanel(fig,  
    'backgroundcolor', 'white',
    'position', [0, 0.1, 1, 0.7]);
    
  % swStruct.calibrate = false;
  % swStruct.inputR = true;
  % swStruct.vd = true;
  %swStruct.directL = true;

  % addSwitch(panel, x, title, offLabel, onLabel, value)
  addSwitch(panel, 0.0, 'Out Switch', 'DUT', 'Calibration', swStruct.calibrate);
  addSwitch(panel, 0.20, 'Calib Out Ch', 'LEFT', 'RIGHT', swStruct.inputR);
  addSwitch(panel, 0.40, 'VD/LPF', 'LPF', 'Voltage Divider', swStruct.vd);
  addSwitch(panel, 0.60, 'Direct In Ch', 'RIGHT', 'LEFT', swStruct.directL);
  addSwitch(panel, 0.80, 'Input Switch', 'DUT', 'Calibration', swStruct.calibrate);
  
  uicontrol(fig, 'style', 'pushbutton',
    'string', 'Switches set, continue',
    'units', 'normalized',
    'position', [0.3 0.01 0.4 0.05],
    'callback', 'close (gcf)');
  
  waitfor(fig);
endfunction

function closeSwWindow(fig)
  if exist('fig', 'var') && isfigure(fig)
    close(fig);
  endif
endfunction