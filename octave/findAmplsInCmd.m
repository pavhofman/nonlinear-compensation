% iterates cmd items starting from second (the first is command string), looking for CH[1000,0.85;2000,0.85]
% if found, returns the levels array, otherwise default value and print defaultMsg
function ampls = findAmplsInCmd(cmd, prefix, defaultValue = [], defaultMsg = '');
  ampls = [];
  
  % only one item, both channels same
  for id = 2:numel(cmd)
    str = cmd{id};
    amplStr = sscanf(str, [prefix '%s']);
    if ~isempty(amplStr)
      ampls = eval(amplStr);
    endif
  endfor
  
  if isempty(ampls)
    % did not find any
    ampls = defaultValue;
    if ~isempty(defaultMsg)
      writeLog('DEBUG', defaultMsg);
    endif
  endif
endfunction


%!test
%! cmd = {'distort', 'AMPL[0.1,NA,0.5]'};
%! levels = findAmplsInCmd(cmd, 'AMPL');
%! expected = [0.1, NA, 0.5];
%! assert(expected, levels);