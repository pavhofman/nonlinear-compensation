% limits samples to <-1, 1>, each clipped sample increments global counter clippedCnt
function samples = fixClipping(samples)
  global clippedCnt;
  
  % positive
  clippedIDs = find(samples > 1);
  if any(clippedIDs)
    cnt = numel(clippedIDs);
    clippedCnt += cnt;
    writeLog('DEBUG', 'Clipped %d positive samples', cnt);
    samples(clippedIDs) = 1;
  end

  % negative
  clippedIDs = find(samples < -1);
  if any(clippedIDs)
    cnt = numel(clippedIDs);
    clippedCnt += cnt;
    writeLog('DEBUG', 'Clipped %d negative samples', cnt);
    samples(clippedIDs) = -1;
  end
end
    
  