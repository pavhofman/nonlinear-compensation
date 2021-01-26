function result = areLevelsStable(measPeaksCh)
  global adapterStruct;
  % const
  persistent PREV_SAME_LEVELS_CNT = 4;
  persistent prevMeasPeaks = cell();

  result = false;

  if adapterStruct.resetPrevMeasPeaks
    writeLog('DEBUG', 'Resetting peaks history was requested');
    prevMeasPeaks = cell();
    % clearing the flag
    adapterStruct.resetPrevMeasPeaks = false;
  end

  if isempty(measPeaksCh)
    % no measured peaks, restarting history
    prevMeasPeaks = cell();
  else
    if numel(prevMeasPeaks) >= PREV_SAME_LEVELS_CNT
      % already collected correct count of prev. levels
      % checking levels
      global MAX_AMPL_DIFF_INTEGER;

      result = true;
      % checking all previous peaks
      for idx = 1:numel(prevMeasPeaks)
        prevPeaksCh = prevMeasPeaks{idx};
        result &= areSameLevels(measPeaksCh, prevPeaksCh, MAX_AMPL_DIFF_INTEGER);
        writeLog('DEBUG', 'IDX %d: meas: %f prev: %f, result %d', idx, measPeaksCh(1, 2), prevPeaksCh(1, 2), result);
        if ~result
          % no reason to continue
          break;
        end
      end
      % removing oldest item
      prevMeasPeaks(1) = [];
    end
    % adding new peaks for next round
    prevMeasPeaks{end + 1} = measPeaksCh;
  end
end