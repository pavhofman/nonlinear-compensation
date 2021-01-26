% includeMidAmpl - used only for printing the midAmpl in UI, calibration itself ignores the value
% result = calFreqReq contains request for two channels, but filled only analysedChID, the other ch constrains only freq.
function calFreqReq = getConstrainedLevelCalFreqReq(midAmpl, freq, analysedChID, maxAmplDiff, includeMidAmpl = false)

  minAmpl = midAmpl - maxAmplDiff;
  maxAmpl = midAmpl + maxAmplDiff;
  
  freqReqLimitedAmpl = [freq, minAmpl, maxAmpl];
  if includeMidAmpl
    freqReqLimitedAmpl = [freqReqLimitedAmpl, midAmpl];
  end

  freqReqAnyAmpl = [freq, NA, NA];
  
  calFreqReq = {freqReqAnyAmpl, freqReqLimitedAmpl};
  if analysedChID == 1
    calFreqReq = flip(calFreqReq);
  end
end