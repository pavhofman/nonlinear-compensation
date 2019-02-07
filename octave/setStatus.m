% setting status
function setStatus(newStatus)
  global statusStruct;
  statusStruct = struct();
  statusStruct.(newStatus) = struct();
endfunction
