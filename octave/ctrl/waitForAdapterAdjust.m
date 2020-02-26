% Upon finishing, callingFName is called with nextLabel param - feval(fname, nextlabel)
function waitForAdapterAdjust(title, adapterStruct, nextLabel, abortLabel, errorLabel, callingFName)
  adapterStruct.execFunc(title, adapterStruct);

  global schedTasksQueue;
  fGetLabel = @(curTime, recInfo, playInfo, schedTask) adapterStruct.checkFunc(adapterStruct, recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedTask);
  schedTasksQueue{end + 1} =  createSchedTask(callingFName, fGetLabel, adapterStruct.abortFunc);
endfunction;