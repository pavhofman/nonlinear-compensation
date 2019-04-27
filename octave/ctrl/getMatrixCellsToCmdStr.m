% calFreqReq must be cell array - see the test
function str = getMatrixCellsToCmdStr(matCells, cmdPrefix)
  str = '';
  for channelID = 1:length(matCells)
    mat = matCells{channelID};
    matStr = mat2strForCmd(mat);
    str = [str ' ' cmdPrefix matStr];
  endfor
  str = strtrim(str);
endfunction

%!test
%! global CMD_CALFREQS_PREFIX;
%! CMD_CALFREQS_PREFIX = '#CHCF#';

%! calFreqReq = {[1000, 0.8, 0.9; 2000, 0.7, 0.8], [1000, NA, NA; 2000, NA, NA]};
%! expected = '#CHCF#[1000,0.8,0.9;2000,0.7,0.8] #CHCF#[1000,NA,NA;2000,NA,NA]';
%! assert (expected, getMatrixCellsToCmdStr(calFreqReq, '#CHCF#'));

%! calFreqReq = {[1000, 0.8, 0.9; 2000, 0.7, 0.8]};
%! expected = '#CHCF#[1000,0.8,0.9;2000,0.7,0.8]';
%! assert (expected, getMatrixCellsToCmdStr(calFreqReq, '#CHCF#'));

%! assert ('', getMatrixCellsToCmdStr({}));