% remove from status
function status = removeFromStatus(statusToRemove)
  global statusStruct;
  if isfield(statusStruct, statusToRemove)
    statusStruct = rmfield(statusStruct, statusToRemove);
  endif
endfunction
