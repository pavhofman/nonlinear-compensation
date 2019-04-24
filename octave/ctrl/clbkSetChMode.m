% sending SET MODE command from radio group
function clbkSetChMode(src, data, cmdFile)
  global SET_MODE;
  global CMD_MODE_PREFIX;
  
  % newly selected radio
  radio = data.NewValue;
  % mode value is stored in userdata property
  newMode = get(radio, 'userdata');

  writeCmd([SET_MODE ' ' CMD_MODE_PREFIX num2str(newMode)], cmdFile);
endfunction