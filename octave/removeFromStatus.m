% remove from status
function status = removeFromStatus(statusToRemove)
  global status;
  id = find(status == statusToRemove);
  status(id) = [];
endfunction
