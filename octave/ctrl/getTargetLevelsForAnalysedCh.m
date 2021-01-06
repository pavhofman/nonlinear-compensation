function targetLevels = getTargetLevelsForAnalysedCh(analysedAmpl, analysedChID)
  % the other CH is always NA - we do not care about zooming/plotting the auxiliary channel during split-calibration
  targetLevels = [NA, analysedAmpl];
  if analysedChID == 1
    targetLevels = flip(targetLevels);
  end
end
