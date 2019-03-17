% setting status
function setStatus(newStatus)
  global statusStruct;
  statusStruct = struct();
  statusStruct = addFieldToStruct(statusStruct, newStatus);
endfunction
