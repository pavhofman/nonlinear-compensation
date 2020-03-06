function calFreqReq = getConstrainedLevelCalFreqReq(midAmpl, freq, analysedChID, maxAmplDiff, includeMidAmpl = false)

  minAmpl = midAmpl - maxAmplDiff;
  maxAmpl = midAmpl + maxAmplDiff;
  
  freqReqLimitedAmpl = [freq, minAmpl, maxAmpl];
  if includeMidAmpl
    freqReqLimitedAmpl = [freqReqLimitedAmpl, midAmpl];
  endif

  freqReqAnyAmpl = [freq, NA, NA];
  
  calFreqReq = {freqReqAnyAmpl, freqReqLimitedAmpl};
  if analysedChID == 1
    calFreqReq = flip(calFreqReq);
  endif
endfunction