function addSwitch(panel, x, title, offLabel, onLabel, value)
  persistent WIDTH = 0.2;

  swPanel = uipanel(panel,  
    'title', title,
    'backgroundcolor', 'white',
    'position', [x, 0.1, WIDTH, 0.9]);
  
  upperTxt = uicontrol(swPanel, 'style', 'text',
    'string', offLabel,
    'backgroundcolor', 'white',
    'units', 'normalized',
    'fontweight', getTxtWeight(value == false),
    'position', [0.05 0.7 0.9 0.2]);

  lowerTxt = uicontrol(swPanel, 'style', 'text',
    'string', onLabel,
    'backgroundcolor', 'white',
    'units', 'normalized',
    'fontweight', getTxtWeight(value == true),
    'position', [0.05 0.05 0.9 0.2]);
  

  slider = uicontrol (swPanel, 'style', 'slider',
    'units', 'normalized',
    'string', 'slider',
    'value', value,
    'enable', 'off',
    'position', [0.4 0.2 0.2 0.5]);
                
endfunction

function weight = getTxtWeight(selected)
  if selected
    weight = 'demi';
  else
    weight = 'normal';
  endif
endfunction