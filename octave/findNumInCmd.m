% iterates cmd items starting from second (the first is command string), looking for prefixNUM or prefixNUM1+NUM2 (e.g. A0.854 or F4000+4500)
% if found, returns the numeric value (or column of two), otherwise default value and print defaultMsg
function value = findNumInCmd(cmd, prefix, defaultValue = [], defaultMsg = '');
  for id = 2:numel(cmd)
    str = cmd{id};
    value = sscanf(str, [prefix '%f+%f']);
    if ~isempty(value)
      return;
    endif
  endfor
  % did not find any
  value = defaultValue;
  if ~isempty(defaultMsg)
    printf(defaultMsg);
  endif
endfunction