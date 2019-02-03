% scheduled pause for timeout. 
% Upon expiration, fname is called with nextLabel param - feval(fname, nextlabel)
function schedPause(timeout, nextLabel, fname)
  global schedQueue;
  reqTime = time() + timeout;
  getLabel = @(curTime, recInfo, playInfo) nextLabelWhen(curTime,  reqTime, nextLabel);
  schedQueue{end + 1} =  createSchedItem(getLabel, fname);
endfunction

% determine label with respect to current time vs. required time
function newLabel = nextLabelWhen(curTime, reqTime, nextLabel)
  %printf('checkTime: %f, %f, %s\n', curTime, reqTime, nextLabel);
  if curTime > reqTime
    newLabel = nextLabel;
  else
    % keep waiting, no label
    newLabel = NA;
  endif
endfunction