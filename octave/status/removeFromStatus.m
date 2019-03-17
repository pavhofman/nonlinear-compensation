% remove from status
function removeFromStatus(statusToRemove)
  global statusStruct;
  statusStruct = removeFromStruct(statusStruct, statusToRemove);
endfunction
