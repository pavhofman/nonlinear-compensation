% adding new status
function status = addStatus(status, newStatus)  
   if !any (status == newStatus)
     status = [status, newStatus];
   endif
endfunction
