% Upon finishing, callingFName is called with nextLabel param - feval(fname, nextlabel)
function waitForAdapterAdjust(title, adapterStruct, nextLabel, abortLabel, errorLabel, callingFName)
  adapterStruct.execFunc(title, adapterStruct);

  global schedQueue;
  getLabel = @(curTime, recInfo, playInfo, schedItem) adapterStruct.checkFunc(adapterStruct, recInfo, playInfo, nextLabel, abortLabel, errorLabel, schedItem);
  schedQueue{end + 1} =  createSchedItem(callingFName, getLabel);
endfunction;