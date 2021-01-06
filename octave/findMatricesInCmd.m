% iterates cmd items starting from second (the first is command string), looking for CH[1000,0.85;2000,0.85]
% if found, returns the fudament values, otherwise default value and print defaultMsg
function funds = findMatricesInCmd(cmd, prefix, defaultValue = cell(), defaultMsg = '');
  funds = cell();
  
  for id = 2:numel(cmd)
    str = cmd{id};
    fundStr = sscanf(str, [prefix '%s']);
    if ~isempty(fundStr)
      fundCh = eval(fundStr);
      funds{end + 1} = fundCh;
    end
  end
  
  if isempty(funds)
    % did not find any
    funds = defaultValue;
    if ~isempty(defaultMsg)
      writeLog('DEBUG', defaultMsg);
    end
  end
end


%!test
%! cmd = {'gen', 'CH[1000,0.85;2000,0.85]', 'CH[3000,-0.85]'};
%! funds = findMatricesInCmd(cmd, 'CH');
%! result = {[1000,0.85;2000,0.85], [3000,-0.85]};
%! assert(result, funds);