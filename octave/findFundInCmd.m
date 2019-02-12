% iterates cmd items starting from second (the first is command string), looking for CH[1000,0.85;2000,0.85]
% if found, returns the fudament values, otherwise default value and print defaultMsg
function funds = findFundInCmd(cmd, prefix, defaultValue = cell(), defaultMsg = '');
  funds = cell();
  
  for id = 2:numel(cmd)
    str = cmd{id};
    fundStr = sscanf(str, [prefix '%s']);
    if ~isempty(fundStr)
      fundCh = eval(fundStr);
      funds{end + 1} = fundCh;
    endif
  endfor
  
  if isempty(funds)
    % did not find any
    funds = defaultValue;
    if ~isempty(defaultMsg)
      printf(defaultMsg);
    endif
  endif
endfunction


%!test
%! cmd = {'gen', 'CH[1000,0.85;2000,0.85]', 'CH[3000,-0.85]'};
%! funds = findFundInCmd(cmd, 'CH');
%! result = {[1000,0.85;2000,0.85], [3000,-0.85]};
%! assert(result, funds);