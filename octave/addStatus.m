% adding new status
function addStatus(newStatus)
  global status;
  if !any (status == newStatus)
   status = [status, newStatus];
  endif
endfunction
