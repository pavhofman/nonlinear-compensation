% iterates cmd items, looking for prefixNUM or prefixNUM1+NUM2 (e.g. A0.854 or F4000+4500)
% if found, returns the numeric value (or column of two), otherwise default value and print defaultMsg
function value = findNumInCmd(cmd, prefix, defaultValue = [], defaultMsg = '');
  for id = 1:numel(cmd)
    str = cmd{id};
    value = sscanf(str, [prefix '%f+%f']);
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


%!test
%! cmd = {'CMD', 'whatever', '#A#1.05+2', 'whatever'};
%! result = findNumInCmd(cmd, '#A#', 5);
%! expected = [1.05; 2];
%! assert(expected, result);
% testing default value
%! result = findNumInCmd(cmd, '#SOMETHINGELSE#', 5);
%! expected = 5;
