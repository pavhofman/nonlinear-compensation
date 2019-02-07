% remove from status
function status = removeFromStatus(statusToRemove)
  global statusStruct;
  statusStruct = rmfield(statusStruct, statusToRemove);
endfunction
