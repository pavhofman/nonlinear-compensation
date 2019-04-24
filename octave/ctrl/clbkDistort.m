function clbkDistort(src, data, title, cmdFile)
  persistent HARMS = 3;
  global DISTORT;
  
  try
    values = inputdlg(getPrompt(HARMS), title, getRowscols(HARMS), getDefaults(HARMS));
    
    % processing values
    if ~isempty(values)
      % pressed OK
      % pre-formatted cmd string (last in values) overrides all
      if ~isempty(values{end})
        harmLevelsStr = values{end};
      else
        harmLevelsStr = buildHarmAmplsStr(values, HARMS);
      endif
      cmd = [DISTORT ' ' harmLevelsStr];
      % sending command      
      writeCmd(cmd, cmdFile, true);
    endif
  catch err
    warndlg(err.message);
  end_try_catch
endfunction

function prompt = getPrompt(harmCnt)
  prompt = cell();
  for harmID = 1:harmCnt
    prompt{end + 1} = ['Harmonics ' num2str(harmID + 1) ' Level (dB, none = empty)'];
  endfor
  prompt{end + 1} = 'Command String: e.g. #HL#[-120,NA,-140]';
endfunction

function rowscols = getRowscols(harmCnt)
  persistent FIELD_LENGTH = 10;
  rowscols = [];
  for harmID = 1:harmCnt
    rowscols = [rowscols; 1, FIELD_LENGTH];
  endfor
  rowscols = [rowscols; 1, 40];
endfunction

function defaults = getDefaults(harmCnt)
  defaults = cell();
  for harmID = 1:harmCnt
    % only first two values are filled
    if harmID > 2
      defaultValue = '';
    else
      defaultValue = '-120';
    endif
    defaults{end + 1} = defaultValue;
  endfor
  defaults{end + 1} = '';
endfunction