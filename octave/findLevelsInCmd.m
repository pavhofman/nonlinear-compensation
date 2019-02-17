% iterates cmd items starting from second (the first is command string), looking for CH[1000,0.85;2000,0.85]
% if found, returns the levels array, otherwise default value and print defaultMsg
function levels = findLevelsInCmd(cmd, prefix, defaultValue = [], defaultMsg = '');
  levels = [];
  
  % only one item, both channels same
  for id = 2:numel(cmd)
    str = cmd{id};
    levelStr = sscanf(str, [prefix '%s']);
    if ~isempty(levelStr)
      levels = eval(levelStr);
    endif
  endfor
  
  if isempty(levels)
    % did not find any
    levels = defaultValue;
    if ~isempty(defaultMsg)
      printf(defaultMsg);
    endif
  endif
endfunction


%!test
%! cmd = {'distort', 'HL[-140,NA,-120]'};
%! levels = findLevelsInCmd(cmd, 'HL');
%! expected = [-140, NA, -120];
%! assert(expected, levels);