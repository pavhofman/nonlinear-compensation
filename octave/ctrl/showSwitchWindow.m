function showSwitchWindow(label, adapterStruct)
  persistent prevSwStruct = initAdapterStruct();
  % default - result OK
  result = true;

  global functionAborted;
  if isequaln(adapterStruct, prevSwStruct)
    % no reason to display/do anything
    functionAborted = false;
    return;
  else
    prevSwStruct = adapterStruct;
  endif


  persistent WIDTH = 800;
  persistent HEIGHT = 400;

  global POS_X;
  global POS_Y;

  functionAborted = NA;
  
  fig = figure('position', [POS_X + 10, POS_Y + 10, WIDTH, HEIGHT]);
  set(fig, 'menubar', 'none');
  set(fig, "toolbar", "none");
  set(fig, 'DeleteFcn', @(h, e) closeSwWindow(fig, true));

  uicontrol(fig, 'style', 'text',
    'string', label,
    'backgroundcolor', 'white',
    'units', 'normalized',
    'position', [0.05 0.90 0.95 0.1]);

  panel = uipanel(fig,  
    'backgroundcolor', 'white',
    'position', [0, 0.1, 1, 0.7]);
    
  % adapterStruct.calibrate = false;
  % adapterStruct.vd = true;

  % addSwitch(panel, x, title, offLabel, onLabel, value)
  addSwitch(panel, 0.0, 'Out Switch', 'DUT', 'Calibration', adapterStruct.calibrate);
  addSwitch(panel, 0.40, 'VD/LPF', 'LPF', 'Voltage Divider', adapterStruct.vd);
  addSwitch(panel, 0.80, 'Input Switch', 'DUT', 'Calibration', adapterStruct.calibrate);
  
  uicontrol(fig, 'style', 'pushbutton',
    'string', 'Switches set, continue',
    'units', 'normalized',
    'position', [0.3 0.01 0.4 0.06],
    'callback', @(h, e) closeSwWindow(fig, false));
endfunction

function closeSwWindow(fig, aborted)
  if exist('fig', 'var') && isfigure(fig)
    % pass info calling methods
    writeLog('DEBUG', 'Figure closed, aborted %d', aborted);
    global functionAborted;
    % this method is called from DeleteFcn callback which is hooked to close(fig) call. 
    % therefore when called upon pushing the button, the method is called twice.
    % using aborted value only for the first call
    if isna(functionAborted)
      % the global value is not set yet, first setting
      functionAborted = aborted;
    endif
    close(fig);
  endif
endfunction