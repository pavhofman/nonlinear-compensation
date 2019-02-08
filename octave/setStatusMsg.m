% setting message to status in statusStruct
function setStatusMsg(status, msg)
  global statusStruct;
  statusStruct.(status).msg = msg;
endfunction
