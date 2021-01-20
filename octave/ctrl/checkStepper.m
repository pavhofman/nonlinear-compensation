function result = checkStepper(adapterStruct, recInfo, playInfo)
  % last processed recinfo ID - to avoid comparing levels of the same recInfo
  persistent lastRecInfoID = 0;

  % using stepper for the currently selected voltage divider
  if ~isempty(adapterStruct.stepperToMove)
    stepperID = adapterStruct.stepperToMove;
  else
    stepperID = adapterStruct.vd;
  end

  result = false;

  % CONTINUE button pressed, checking stepper
  if ~isempty(adapterStruct.reqVDLevel) % requested specific levels
    if ~isStepperRunning(stepperID) % stepper is not moving (not yet or no more), it makes sense to measure level
      recInfoID = recInfo.id;
      if recInfoID ~= lastRecInfoID
        %remembering for next time
        lastRecInfoID = recInfoID;

        % new recInfo, can check level stability
        global ANALYSED_CH_ID;
        measPeaksCh = recInfo.measuredPeaks{ANALYSED_CH_ID};

        if areLevelsStable(measPeaksCh, stepperID)
          if isReqLevel(adapterStruct.reqVDLevel, measPeaksCh(1, 2), adapterStruct.maxAmplDiff)
            writeLog('DEBUG', "Stepper [%d] at required position", stepperID);
            resetStepperTries(stepperID);
            result = true;
            return;
          else
            % new stepper attempt to get closer to reqLevel

            % sometimes stepper params are estimated incorrectly, stepper does not converge to the required level and keeps oscillating around
            % if too many stepper., re-initialize stepper to run stepper calibration again
            resetStepperIfNotConverging(stepperID);
            steps = adjustStepper(stepperID, adapterStruct.reqVDLevel, recInfo, playInfo);
            incStepperTries(stepperID);
            if steps == 0
              writeLog('DEBUG', "Stepper [%d] calculated 0 steps, yet no exactly at position, cannot do better", stepperID);
              resetStepperTries(stepperID);
              result = true;
              return;
            end % 0 steps
          end % req levels
        end % levels stable
      end % new recTime
    end % stepper not running
  else % requested levels
    writeLog('DEBUG', "No stepper level adjustment requested");
    result = true;
    return;
  end % requested levels
end

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

function result = isReqLevel(reqLevel, measLevel, maxAmplDiff)
  % simple difference check, no ratios
  result =  abs(reqLevel - measLevel) < maxAmplDiff;
  writeLog('DEBUG', 'req: %f meas: %f, diff: %f, maxDiff %f => result %d',
    reqLevel, measLevel, abs(reqLevel - measLevel), maxAmplDiff, result);
end

function resetStepperIfNotConverging(stepperID)
  global steppers;
  % maximum stepper attempts to reach one level before resetting stepper calibration/history to allow fresh calibration
  global MAX_STEPPER_ATTEMPTS;

  if steppers{stepperID}.attempts > MAX_STEPPER_ATTEMPTS
    steppers{stepperID} = initStepperStruct(stepperID);
    writeLog('WARNING', 'Stepper [%d] reached max attempts %d, its history was reset', stepperID, MAX_STEPPER_ATTEMPTS);
  end
end

function resetStepperTries(stepperID)
  global steppers;
  steppers{stepperID}.attempts = 0;
  writeLog('DEBUG', 'Zeroed stepper [%d] attempts', stepperID);
end

function incStepperTries(stepperID)
  global steppers;
  steppers{stepperID}.attempts += 1;
  writeLog('DEBUG', 'Incremented stepper [%d] attempts to %d', stepperID, steppers{stepperID}.attempts);
end