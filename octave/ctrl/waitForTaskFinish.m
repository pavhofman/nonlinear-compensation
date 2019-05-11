% scheduler-eanbled wait starting another function fNameToRun, with labels if fNameToRun returns OK (true) of FAil (false)
% 
function waitForTaskFinish(fNameToRun, okLabel, failLabel, callingFName);
  global schedQueue;
  getLabel = @(curTime, recInfo, playInfo, schedItem) decideLabel(fNameToRun, callingFName, okLabel, failLabel, schedItem);
  schedItem = createSchedItem(fNameToRun, getLabel);
  schedItem.runFunc = true;
  schedItem.result = NA;
  schedQueue{end + 1} = schedItem;
endfunction

% determine label
function schedItem = decideLabel(fNameToRun, callingFName, okLabel, failLabel, schedItem)
  if schedItem.runFunc
    % start fNameToRun
    schedItem.runFunc = false;
    % start at 1
    schedItem.newLabel = 1;
    schedItem.fName = fNameToRun;
    % keep this item in schedQueue - is used for returning to callingFName
    schedItem.keepInQueue = true;
  elseif ~isna(schedItem.result)
    % fNameToRun function has finished, returning back to the calling function
    schedItem.fName = callingFName;
    % can drop the item from schedQueue
    schedItem.keepInQueue = false;
    % with result:
    if schedItem.result
      schedItem.newLabel = okLabel;
    else
      schedItem.newLabel = failLabel;
    endif
  else
    % keep waiting, no label
    schedItem.newLabel = NA;
    % keeping fNameToRun so that result can be passed to this item in runScheduled()
    schedItem.fName = fNameToRun;
  endif
endfunction
