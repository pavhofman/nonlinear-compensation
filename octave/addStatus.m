% adding new status
function addStatus(newStatus)
  global info;
  status = info.status;
  if !any (status == newStatus)
   status = [status, newStatus];
  endif
  info.status = status;   
endfunction
