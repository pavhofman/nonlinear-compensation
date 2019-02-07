% setting result to status in statusStruct
function setStatusResult(status, result)
  global statusStruct;
  statusStruct.(status).result = result;
endfunction
