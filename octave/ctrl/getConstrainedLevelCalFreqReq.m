function calFreqReq = getConstrainedLevelCalFreqReq(midAmpl, freq, analysedChID, calTolerance, includeMidAmpl = false)

  minAmpl = midAmpl/calTolerance;
  maxAmpl = midAmpl*calTolerance;
  
  freqReqLimitedAmpl = [freq, minAmpl, maxAmpl];
  if includeMidAmpl
    freqReqLimitedAmpl = [freqReqLimitedAmpl, midAmpl];
   else
    freqReqLimitedAmpl = [freqReqLimitedAmpl];
  endif

  freqReqAnyAmpl = [freq, NA, NA];
  
  calFreqReq = {freqReqAnyAmpl, freqReqLimitedAmpl};
  if analysedChID == 1
    calFreqReq = flip(calFreqReq);
  endif
endfunction