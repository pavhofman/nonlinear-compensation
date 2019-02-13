% converting values from generator dialog to genFunds cell array
function genFunds = buildGenFunds(values, channelCnt, freqCnt)
  %genFunds = {[1000,0.85;2000,0.85], [3000,-0.85]};
  genFunds = cell();
  id = 0;
  for channelID = 1:channelCnt
    fundsCh = [];
    for freqID = 1:freqCnt
      ++id;
      freq = sscanf(values{id}, '%d');
      ++id;
      ampl = sscanf(values{id}, '%f');
      if ~isempty(freq) &&  ~isempty(ampl)
        fundsCh = [fundsCh; freq, ampl];
      endif
    endfor
    if ~isempty(fundsCh)
      genFunds{end + 1} = fundsCh;
    endif
  endfor
endfunction

%!test
%! channelCnt = 2;
%! freqCnt = 2;
%! values = {'1000', '0.4', '2000', '0.3', '3000', '-0.4', '5000', '-0.4'};
%! expected = {[1000,0.4;2000,0.3], [3000,-0.4;5000,-0.4]};
%! genFunds = buildGenFunds(values, channelCnt, freqCnt);
%! assert(expected, genFunds);
%! values = {'1000', '0.4', '2000', '0.3', '', '-0.4', '5000', '-0.4'};
%! expected = {[1000,0.4;2000,0.3], [5000,-0.4]};
%! genFunds = buildGenFunds(values, channelCnt, freqCnt);
%! assert(expected, genFunds);
%! values = {'1000', '0.4', '2000', '0.3', '', '-0.4', '5000', 'whatever'};
%! expected = {[1000,0.4;2000,0.3]};
%! genFunds = buildGenFunds(values, channelCnt, freqCnt);
%! assert(expected, genFunds);
