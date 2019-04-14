% calFreqReq must be cell array - see the test
function str = getCalFreqReqStr(calFreqReq)
  global CMD_CALFREQS_PREFIX;
  
  str = '';
  for channelID = 1:length(calFreqReq)
    calFreqReqCh = calFreqReq{channelID};
    str = [str ' ' CMD_CALFREQS_PREFIX '['];
    if rows(calFreqReqCh) > 0
      
      for id = 1: rows(calFreqReqCh)
        freqRow = calFreqReqCh(id, :);
        str = [str num2str(freqRow(1)) ',' num2str(freqRow(2)) ',' num2str(freqRow(3)) ';'];
      endfor
    endif
    str = [str ']'];
  endfor
endfunction

%!test
%! global CMD_CALFREQS_PREFIX;
%! CMD_CALFREQS_PREFIX = '#CHCF#';

%! calFreqReq = {[1000, 0.8, 0.9; 2000, 0.7, 0.8], [1000, NA, NA; 2000, NA, NA]};
%! expected = ' #CHCF#[1000,0.8,0.9;2000,0.7,0.8;] #CHCF#[1000,NA,NA;2000,NA,NA;]';
%! assert (expected, getCalFreqReqStr(calFreqReq));

%! calFreqReq = {[1000, 0.8, 0.9; 2000, 0.7, 0.8]};
%! expected = ' #CHCF#[1000,0.8,0.9;2000,0.7,0.8;]';
%! assert (expected, getCalFreqReqStr(calFreqReq));

%! assert ('', getCalFreqReqStr({}));