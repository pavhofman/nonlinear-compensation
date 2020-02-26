% scheduled pause for timeout. 
% Upon expiration, fName is called with nextLabel param - feval(fname, nextlabel)
function schedPause(timeout, nextLabel, callingFName)
  global schedTasksQueue;
  reqTime = time() + timeout;
  fGetLabel = @(curTime, recInfo, playInfo, schedTask) nextLabelWhen(curTime,  reqTime, nextLabel, schedTask);
  schedTasksQueue{end + 1} =  createSchedTask(callingFName, fGetLabel);
endfunction

% determine label with respect to current time vs. required time
function schedTask = nextLabelWhen(curTime,  reqTime, nextLabel, schedTask)
  if curTime > reqTime
    schedTask.newLabel = nextLabel;
  endif
endfunction