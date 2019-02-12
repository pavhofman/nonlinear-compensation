function cmdStr = getGeneratorCmdStr(genFunds)
  global GENERATE;
  global CMD_CHANNEL_FUND_PREFIX;
  
  cmdStr = GENERATE;
  for channelID = 1:length(genFunds)
    fundChStr = getFundStr(genFunds{channelID});
    cmdStr = [cmdStr ' ' CMD_CHANNEL_FUND_PREFIX fundChStr];
  endfor
endfunction

function str = getFundStr(fundsCh)
  str = '[';
  for id = 1: rows(fundsCh)
    fund = fundsCh(id, :);
    str = [str num2str(fund(1)) ',' num2str(fund(2)) ';'];
  endfor
  str = [str ']'];
endfunction



%!test
%! genFunds = {[1000,0.85;2000,0.85], [3000,-0.85]};
%! str = getGeneratorCmdStr(genFunds);
%! expected = 'gen CH[1000,0.85;2000,0.85;] CH[3000,-0.85;]';
%! assert(str, expected);