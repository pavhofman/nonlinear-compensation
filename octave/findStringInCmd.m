% iterates cmd items starting from second (the first is command string), looking for prefixSTRING (e.g. AEfilter)
% if found, returns the STRING value, otherwise default value and print defaultMsg
function value = findStringInCmd(cmd, prefix, defaultValue = '', defaultMsg = '');
  for id = 2:numel(cmd)
    str = cmd{id};
    value = sscanf(str, [prefix '%s']);
    if ~isempty(value)
      return;
    end
  end
  % did not find any
  value = defaultValue;
  if ~isempty(defaultMsg)
    writeLog('DEBUG', defaultMsg);
  end
end