% updating phase columns of calPeaks with avgPhaseDiffs at addedRowIDs
function calPeaks = updatePhaseDiffsInPeaks(calPeaks, avgPhaseDiffs, addedRowIDs)
  if length(avgPhaseDiffs) == 1
    % aligning to two values
    avgPhaseDiffs = [avgPhaseDiffs, 0];
  end  
  
  for rowID = addedRowIDs
    calPeaks(rowID, [2 3]) = avgPhaseDiffs;
  endfor
endfunction


%!test
%! calPeaks = [1 0 0 0; 2 0 0 0.3; 3 0 0 0.6; 4 0 0 1]; 
%! avgPhaseDiffs = 0.1;
%! addedRowIDs = [1 2];
%! result = updatePhaseDiffsInPeaks(calPeaks, avgPhaseDiffs, addedRowIDs);
%! expected = [1 0.1 0 0; 2 0.1 0 0.3; 3 0 0 0.6; 4 0 0 1]; 
%! assert(expected, result);

%! avgPhaseDiffs = [0.1 0.1];
%! addedRowIDs = [3 4];
%! result = updatePhaseDiffsInPeaks(calPeaks, avgPhaseDiffs, addedRowIDs);
%! expected = [1 0 0 0; 2 0 0 0.3; 3 0.1 0.1 0.6; 4 0.1 0.1 1]; 
%! assert(expected, result);