% adding new status
function addStatus(newStatus)
  global statusStruct;
  statusStruct = addFieldToStruct(statusStruct, newStatus);
endfunction
