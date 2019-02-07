% adding new status
function addStatus(newStatus)
  global statusStruct;
  if ~isfield(statusStruct, newStatus)
    statusStruct.(newStatus) = struct();
  endif
endfunction
