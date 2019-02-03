% iterates cmd items starting from second (the first is command string), looking for prefixNUM (e.g. A0.854 or F4500)
% if found, returns the numeric value, otherwise empty value
function value = findNumInCmd(cmd, prefix)
  for id = 2:numel(cmd)
    str = cmd{id};
    value = sscanf(str, [prefix '%f']);
    if ~isempty(value)
      return;
    endif
  endfor
  % did not find any
  value = [];
endfunction