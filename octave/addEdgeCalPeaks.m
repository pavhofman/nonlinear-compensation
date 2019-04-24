function calPeaks = addEdgeCalPeaks(calPeaks)
  global AMPL_IDX;  % = index of fundAmpl1
  global PEAKS_START_IDX;
  
  % calPeaks must be are sorted by fundAmpl!

  % get peaks only
  allDPeaksC = calPeaks(:, PEAKS_START_IDX:end);

  % add first row - zero ampl peaks for <0, minLevel> extrapolation
  % each peak has aplitude -> zero and phase same as minLevel (i.e. first row)
  
  % finding existing peaks from minimum. If value at first row missing, use 0
  dPeaksC = getEdgePeaks(allDPeaksC, 1, 0);
  % phase must be preserved, therefore ampl cannot not be 0 => 1e-15 is almost zero
  zeroPeaks = 1e-15 * exp(i * angle(dPeaksC));

  zeroAmpls= [0, 0];
  complZeroPeaks = [calPeaks(1, 1 : AMPL_IDX - 1), zeroAmpls, zeroPeaks];

  % max level - same phase as maxLevel (last row), amplitude = scaled to fundAmpl = 1
  % If value at last row missing, use NA
  dPeaksC = getEdgePeaks(allDPeaksC, rows(calPeaks), NA);
  ampls = abs(dPeaksC);
  phases = angle(dPeaksC);
  fundAmpl1 = calPeaks(end, AMPL_IDX);
  scaleToOne = 1/fundAmpl1;
  onePeaks =  scaleToOne * ampls .* exp(i * phases);
  fundAmpl2 = calPeaks(end, AMPL_IDX + 1);
  oneAmpls= [1, fundAmpl2/fundAmpl1];
  complOnePeaks = [calPeaks(end, 1 : AMPL_IDX - 1), oneAmpls, onePeaks];
  
  calPeaks = [complZeroPeaks; calPeaks; complOnePeaks];  
endfunction

% create row of edge dPeaksC, for each distortFreq, check value at rowID (used for finding minimum as well as maximum)
function dPeaksC = getEdgePeaks(allDPeaksC, rowID, valueForNA)
  dPeaksC = [];
  % for each distortfreq
  for colID = 1:columns(allDPeaksC)
    thisPeak = allDPeaksC(rowID, colID);
    if ~isna(thisPeak)
      % found
      peak = thisPeak;
    else
      % did not find, using valueForNA
      peak = valueForNA;
    endif
    % adding
    dPeaksC = [dPeaksC, peak];
  endfor
endfunction


%!test
% calPeaks = addEdgeCalPeaks(calPeaks)
%! distValue1 = 0.1 + 0.1i;
%! distValue2 = 0.2 + 0.2i;
%! calPeaksRow1 = [5, 0, 0, 0.3, 0.2, distValue1];
%! calPeaksRow2 = [6, 0, 0, 0.4, 0.3, distValue2];
%! calPeaks = [calPeaksRow1; calPeaksRow2];
%! result = addEdgeCalPeaks(calPeaks);

%! zeroRow = [5, 0, 0, 0, 0, 1e-15 * exp(i * angle(distValue1))];

%! ampls = abs(distValue2);
%! phases = angle(distValue2);
%! fundAmpl1 = calPeaksRow2(4);
%! scaleToOne = 1/fundAmpl1;
%! onePeaks =  scaleToOne * ampls .* exp(i * phases);

%! onesRow = [6, 0, 0, 1, 0.3/0.4, onePeaks];
%! expected = [zeroRow; calPeaksRow1; calPeaksRow2; onesRow];
% tolerance 1e-10
%! assert(expected, result, 1e-10);
