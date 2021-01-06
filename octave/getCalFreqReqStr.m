% calFreqReq must be cell array
function str = getCalFreqReqStr(calFreqReq)
  global CMD_CALFREQS_PREFIX;
  str = getMatrixCellsToCmdStr(calFreqReq, CMD_CALFREQS_PREFIX);
end
  
