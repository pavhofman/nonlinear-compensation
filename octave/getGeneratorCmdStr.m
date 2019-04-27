function cmdStr = getGeneratorCmdStr(genFunds)
  global GENERATE;
  global CMD_CHANNEL_FUND_PREFIX;
  
  cmdStr = [GENERATE ' ' getMatrixCellsToCmdStr(genFunds, CMD_CHANNEL_FUND_PREFIX)];
endfunction

%!test
%! global GENERATE;
%! GENERATE = 'gen';
%! global CMD_CHANNEL_FUND_PREFIX;
%! CMD_CHANNEL_FUND_PREFIX = 'CH';

%! genFunds = {[1000,0.85;2000,0.85], [3000,-0.85]};
%! str = getGeneratorCmdStr(genFunds);
%! expected = 'gen CH[1000,0.85;2000,0.85] CH[3000,-0.85]';
%! assert(str, expected);