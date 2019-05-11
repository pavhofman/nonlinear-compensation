% scheduled pause for timeout. 
% Upon expiration, fName is called with nextLabel param - feval(fname, nextlabel)
function schedPause(timeout, nextLabel, callingFName)
  global schedQueue;
  reqTime = time() + timeout;
  getLabel = @(curTime, recInfo, playInfo, schedItem) nextLabelWhen(curTime,  reqTime, nextLabel, schedItem);
  schedQueue{end + 1} =  createSchedItem(callingFName, getLabel);
endfunction

% determine label with respect to current time vs. required time
function schedItem = nextLabelWhen(curTime,  reqTime, nextLabel, schedItem)
  if curTime > reqTime
    schedItem.newLabel = nextLabel;
  endif
endfunction