function result = checkStepper(adapterStruct, recInfo, playInfo)
  % last processed recinfo ID - to avoid comparing levels of the same recInfo
  persistent lastRecInfoID = 0;

  % using stepper for the currently selected voltage divider
  stepperID = adapterStruct.vd;

  result = false;

  % CONTINUE button pressed, checking stepper
  if ~isempty(adapterStruct.reqLevels) % requested specific levels
    if ~isStepperRunning(stepperID) % stepper is not moving (not yet or no more), it makes sense to measure level
      recInfoID = recInfo.id;
      if recInfoID ~= lastRecInfoID
        %remembering for next time
        lastRecInfoID = recInfoID;

        % new recInfo, can check level stability
        global ANALYSED_CH_ID;
        measPeaksCh = recInfo.measuredPeaks{ANALYSED_CH_ID};

        if areLevelsStable(measPeaksCh, stepperID)
          if areReqLevels(adapterStruct.reqLevels, measPeaksCh(:, 2), adapterStruct.maxAmplDiff)
            writeLog('DEBUG', "Stepper [%d] at required position", stepperID);
            resetStepperTries(stepperID);
            result = true;
            return;
          else
            % new stepper attempt to get closer to reqLevel

            % sometimes stepper params are estimated incorrectly, stepper does not converge to the required level and keeps oscillating around
            % if too many stepper., re-initialize stepper to run stepper calibration again
            resetStepperIfNotConverging(stepperID);
            steps = adjustStepper(stepperID, adapterStruct.reqLevels, recInfo, playInfo);
            incStepperTries(stepperID);
            if steps == 0
              writeLog('DEBUG', "Stepper [%d] calculated 0 steps, yet no exactly at position, cannot do better", stepperID);
              resetStepperTries(stepperID);
              result = true;
              return;
            endif % 0 steps
          endif % req levels
        endif % levels stable
      endif % new recTime
    endif % stepper not running
  else % requested levels
    writeLog('DEBUG', "No stepper level adjustment requested");
    result = true;
    return;
  endif % requested levels
endfunction

function result = areLevelsStable(measPeaksCh, stepperID)
  global adapterStruct;
  % const
  persistent PREV_SAME_LEVELS_CNT = 2;
  persistent prevMeasPeaks = cell();

  result = false;

  if adapterStruct.resetPrevMeasPeaks
    writeLog('DEBUG', 'Resetting peaks history was requested');
    prevMeasPeaks = cell();
    % clearing the flag
    adapterStruct.resetPrevMeasPeaks = false;
  endif

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
        endif
      endfor

      % removing oldest item
      prevMeasPeaks(1) = [];
    endif
    % adding new peaks for next round
    prevMeasPeaks{end + 1} = measPeaksCh;
  endif
endfunction

function result = areReqLevels(reqLevels, measLevels, maxAmplDiff)
  % simple difference check, no ratios
  differentAmplIDs = find(abs(reqLevels - measLevels) > maxAmplDiff);
  result =  isempty(differentAmplIDs);
  writeLog('DEBUG', 'req: %f meas: %f, diff: %f, maxDiff %f => result %d',
    reqLevels(1), measLevels(1), abs(reqLevels(1) - measLevels(1)), maxAmplDiff, result);
endfunction

function resetStepperIfNotConverging(stepperID)
  global steppers;
  % maximum stepper attempts to reach one level before resetting stepper calibration/history to allow fresh calibration
  global MAX_STEPPER_ATTEMPTS;

  if steppers{stepperID}.attempts > MAX_STEPPER_ATTEMPTS
    steppers{stepperID} = initStepperStruct(stepperID);
    writeLog('WARNING', 'Stepper [%d] reached max attempts %d, its history was reset', stepperID, MAX_STEPPER_ATTEMPTS);
  endif
endfunction

function resetStepperTries(stepperID)
  global steppers;
  steppers{stepperID}.attempts = 0;
  writeLog('DEBUG', 'Zeroed stepper [%d] attempts', stepperID);
endfunction

function incStepperTries(stepperID)
  global steppers;
  steppers{stepperID}.attempts += 1;
  writeLog('DEBUG', 'Incremented stepper [%d] attempts to %d', stepperID, steppers{stepperID}.attempts);
endfunction