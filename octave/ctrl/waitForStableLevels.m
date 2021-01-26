% scheduler-enabled wait for stable levels on rec side/ANALYSED_CH_ID with timeout
 % If timeout reached, return timeoutLabel
function waitForStableLevels(nextLabel, timeout, timeoutLabel, callingFName)
  global adapterStruct;
  % flag for areLevelsStable
  adapterStruct.resetPrevMeasPeaks = true;

  reqTime = time() + timeout;
  fGetLabel = @(curTime, recInfo, playInfo, schedTask) decideLabelFor(curTime,  reqTime, nextLabel, timeoutLabel, recInfo, schedTask);
  schedTask = createSchedTask(callingFName, fGetLabel);

  global schedTasksQueue;
  schedTasksQueue{end + 1} = schedTask;
end

% determine label: if measured levels in analyzed channel in recInfo are stable, return nextLabel. If timout reached, return timeoutLabel
function schedTask = decideLabelFor(curTime, reqTime, nextLabel, timeoutLabel, recInfo, schedTask)
  global ANALYSED_CH_ID;
  measPeaksCh = recInfo.measuredPeaks{ANALYSED_CH_ID};
  if areLevelsStable(measPeaksCh)
    % all commands done, go to nextLabel
    schedTask.newLabel = nextLabel;
  elseif curTime > reqTime
    % timeout occured
    writeLog('WARN', 'Task timed out');
    schedTask.newLabel = timeoutLabel;
  end
  % else keep waiting
end

