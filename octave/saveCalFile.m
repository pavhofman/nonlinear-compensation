% fundPeaksCh have at least one freq (row), distortPeaksCh can be empty (clean signal or single-sine fundament > fs/4 (i.e. no higher harmonics)
function calFileStruct = saveCalFile(fundPeaksCh, distortPeaksCh, fs, calFile, playAmplsCh, timestamp, doSave = true)
  % remove zero freq rows from distortPeaksCh
  if ~isempty(distortPeaksCh)
    rowIDs = distortPeaksCh(:, 1) == 0;
    distortPeaksCh(rowIDs, :) = [];
  end
  
  %% calFile line contains exactly 2 fundpeaks, therefore fundPeaksCh must contain so many rows!!
  fundPeaksCh = padWithZeros(fundPeaksCh, 2);
  
  if exist(calFile, 'file')
    load(calFile);
    calPeaks = calRec.peaks;
    distortFreqs = calRec.distortFreqs;
    [calPeaks, distortFreqs, addedRowIDs] = addRowToCalPeaks(fundPeaksCh, distortPeaksCh, calPeaks, distortFreqs, playAmplsCh, timestamp);    
  else
    if isempty(distortPeaksCh)
      % no distortions, only fund  peaks
      distortFreqs = [];
      dPeaksC = [];
    else
      distortFreqs = transpose(distortPeaksCh(:, 1));
      % build new/first complPeak line - convert peaks to complex numbers and transpose
      dPeaksC = transpose(distortPeaksCh(:, 2) .* exp(i * distortPeaksCh(:, 3)));
    end
    calPeaks = buildCalPeakRow(timestamp, fundPeaksCh, dPeaksC, playAmplsCh);
    % new calfile, always 1 row
    addedRowIDs = 1;
  end

  calRec.fundFreqs = transpose(fundPeaksCh(:, 1));
  calRec.distortFreqs = distortFreqs;
  calRec.peaks = calPeaks;
  writeLog('DEBUG', 'Updated calRec for calfile %s', calFile);
  writeLog('TRACE', '%s', disp(calRec));
  
  calFileStruct = struct();
  calFileStruct.fileName = calFile;
  calFileStruct.calRec = calRec;
  calFileStruct.addedRowIDs = addedRowIDs;
  
  if doSave
    save(calFile, 'calRec');
    writeLog('INFO', 'Stored calRec into calfile %s', calFile);
  end
end


% pad peaksCh with zero rows up to rowsCnt
function peaksCh = padWithZeros(peaksCh, rowsCnt)
  peaksCh = [peaksCh; zeros(rowsCnt - rows(peaksCh), 3)];
end