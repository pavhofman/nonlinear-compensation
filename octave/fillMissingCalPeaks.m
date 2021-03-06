% fill all missing (NA) distortion peaks
% values between are interpolated. All NA values in sequence from highest level downward are replaced with zero
function calPeaks = fillMissingCalPeaks(calPeaks)
  % calPeaks: time, fundPhaseDiff1, fundPhaseDiff2, playAmpl1, playAmpl2, fundAmpl1, fundAmpl2, f1, f2, f3...... where f1, f2,... are distortion freqs in the same order as freqs
  global AMPL_IDX;  % = index of fundAmpl1
  global PEAKS_START_IDX;
 
  % levels = AMPL_IDX column
  levels = calPeaks(:, AMPL_IDX);
  
  % search whole calPeaks
  missingPeaksIDs = isnan(calPeaks);
  % but skip all NAs before distortion peaks - these are not interpolated
  missingPeaksIDs(:, 1: PEAKS_START_IDX - 1) = 0;
  
  % interpolate for each frequency with missing values
  % indices of columns with MISSING value
  colIDs = find(any(missingPeaksIDs));
  for colID = colIDs
    missingPeaksIDsInCol = missingPeaksIDs(:, colID);
    % all NAs from highest levels - replace with zero to avoid compensating with nonsense
    for rowID = flip(1:rows(calPeaks))
      if missingPeaksIDsInCol(rowID) == 1
        % replacing with zero
        calPeaks(rowID, colID) = 0;
      else
        % the sequence is broken
        break;
      end
    end
    % all rows above rowID are already fixed
    % now interpolation of the remaining lower rows - limiting up to rowID
    missingPeaksIDsInCol = missingPeaksIDsInCol(1:rowID);
    knownLevels = levels(~missingPeaksIDsInCol);
    missingLevels = levels(missingPeaksIDsInCol);
    knownPeaks = calPeaks(~missingPeaksIDsInCol, colID);
    peaksAtLevels = interp1(knownLevels, knownPeaks, missingLevels, 'linear', 'extrap');
    % insert interpolated values into complAllPeaks
    calPeaks(find(missingPeaksIDsInCol), colID) = peaksAtLevels;
  end
end

%!test
%! calPeaks = [1 0 0 0.1 1 1;...
%!             1 0 0 0.2 NA 2;...
%!             3 0 0 0.3 NA NA;...
%!             4 0 0 0.4 4  NA;...
%!             5 0 0 0.5 NA 5;...
%!             5 0 0 1.0 NA 10];
%! result = fillMissingCalPeaks(calPeaks);
%! expected = [1 0 0 0.1 1 1;...
%!             1 0 0 0.2 2 2;...
%!             3 0 0 0.3 3 3;...
%!             4 0 0 0.4 4 4;...
%!             5 0 0 0.5 0 5;...
%!             5 0 0 1.0 0 10];
%! assert(expected, result, 1e-10);


