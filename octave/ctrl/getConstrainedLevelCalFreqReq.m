function calFreqReq = getConstrainedLevelCalFreqReq(midAmpl, freq, analysedChID, calTolerance)

  minAmpl = midAmpl/calTolerance;
  maxAmpl = midAmpl*calTolerance;
  
  freqReqLimitedAmpl = [freq, minAmpl, maxAmpl];
  freqReqAnyAmpl = [freq, NA, NA];
  
  calFreqReq = {freqReqAnyAmpl, freqReqLimitedAmpl};
  if analysedChID == 1
    calFreqReq = flip(calFreqReq);
  endif
endfunction

