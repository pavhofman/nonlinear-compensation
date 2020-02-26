function schedTask = checkAdapterPanelWithStepper(adapterStruct, recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask)
  % TODO - for now fixed
  persistent STEPPER_ID = 1;
  % last processed recinfo time
  persistent lastRecTime = 0;
  global adapterContinue;

  % first checking continue status
  if adapterContinue
    % CONTINUE button pressed, checking stepper
    if ~isempty(adapterStruct.reqLevels) % requested specific levels
      if ~isStepperRunning(STEPPER_ID) % stepper is not moving (not yet or no more), it makes sense to measure level
        recTime = recInfo.time;
        if recTime ~= lastRecTime
          %remembering for next time
          lastRecTime = recTime;

          % new recInfo, can check level stability
          global ANALYSED_CH_ID;
          measPeaksCh = recInfo.measuredPeaks{ANALYSED_CH_ID};

          if areLevelsStable(measPeaksCh, STEPPER_ID)
            if areReqLevels(adapterStruct.reqLevels, adapterStruct.maxAmplDiff, measPeaksCh)
              writeLog('DEBUG', "Stepper at required position, task is done");
              % resetting flag
              adapterContinue = false;
              schedTask.newLabel = nextLabel;
              return;
            else
              % new stepper run to get closer to reqLevel
              steps = adjustStepper(STEPPER_ID, adapterStruct.reqLevels, recInfo, playInfo);
              if steps == 0
                writeLog('DEBUG', "Stepper calculated 0 steps, yet no exactly at position, cannot do better, task is done");
                % resetting flag
                adapterContinue = false;
                schedTask.newLabel = nextLabel;
                return;
              endif % 0 steps
            endif % req levels
          endif % levels stable
        endif % new recTime
      endif % stepper not running
    else % requested levels
      writeLog('DEBUG', "Adapter continue flagged, but no level adjustment requested, task is done");
      % resetting flag
      adapterContinue = false;
      schedTask.newLabel = nextLabel;
      return;
    endif
  endif % window closed
endfunction

function result = areLevelsStable(measPeaksCh, stepperID)
  % const
  persistent PREV_SAME_LEVELS_CNT = 2;
  persistent prevMeasPeaks = cell();

  result = false;

  global steppers;
  if steppers{stepperID}.stepperMoved
    writeLog('DEBUG', 'Stepper [%d] has moved, resetting history', stepperID);
    prevMeasPeaks = cell();
    steppers{stepperID}.stepperMoved = false;
    return;
  endif

  if isempty(measPeaksCh)
    % no measured peaks, restarting history
    prevMeasPeaks = cell();
  else
    if numel(prevMeasPeaks) >= PREV_SAME_LEVELS_CNT
      % already collected correct count of prev. levels
      % checking levels
      global MAX_AMPL_DIFF_INTEGER;
      maxAmplDiff = MAX_AMPL_DIFF_INTEGER;

      result = true;
      % checking all previous peaks
      for idx = 1:numel(prevMeasPeaks)
        prevPeaksCh = prevMeasPeaks{idx};
        result &= areSameLevels(measPeaksCh, prevPeaksCh, maxAmplDiff);
        writeLog('DEBUG', 'areLevelsStable: IDX %d: meas: %f prev: %f, result %d', idx, measPeaksCh(1, 2), prevPeaksCh(1, 2), result);
        if ~result
          % no reason to continue
          break;
        endif
      endfor

      % removing oldest item
      prevMeasPeaks(1) = [];
    endif
    % adding new peaks for next round
    prevMeasPeaks{end + 1} = measPeaksCh;
  endif
endfunction

function result = areReqLevels(reqLevels, maxAmplDiff, measPeaksCh)
  % areSameLevels requires [freq, ampl] format
  levelsForCheck = [measPeaksCh(:, 1), reqLevels];
  result = areSameLevels(levelsForCheck, measPeaksCh, maxAmplDiff);
  writeLog('DEBUG', 'areReqLevels: req: %f meas: %f, , maxAmplDiff %f => result %d', reqLevels(1), measPeaksCh(1, 2), maxAmplDiff, result);
endfunction

