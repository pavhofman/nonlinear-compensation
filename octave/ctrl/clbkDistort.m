function clbkDistort(src, data, title, cmdFile)
  persistent HARMS = 9;
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
      end
      cmd = [DISTORT ' ' harmLevelsStr];
      % sending command      
      writeCmd(cmd, cmdFile, true);
    end
  catch err
    warndlg(err.message);
  end
end

function prompt = getPrompt(harmCnt)
  prompt = cell();
  for harmID = 1:harmCnt
    prompt{end + 1} = ['Harmonics ' num2str(harmID + 1) ' Level (dB, none = empty)'];
  end
  prompt{end + 1} = 'Command String: e.g. #AMPL#[1e-06,NA,1e-07]';
end

function rowscols = getRowscols(harmCnt)
  persistent FIELD_LENGTH = 10;
  rowscols = [];
  for harmID = 1:harmCnt
    rowscols = [rowscols; 1, FIELD_LENGTH];
  end
  rowscols = [rowscols; 1, 40];
end

function defaults = getDefaults(harmCnt)
  defaults = cell();
  for harmID = 1:harmCnt
    % only first two values are filled
    if harmID > 2
      defaultValue = '';
    else
      defaultValue = '-120';
    end
    defaults{end + 1} = defaultValue;
  end
  defaults{end + 1} = '';
end