function result = statusContains(testedStatus)
  global info;
  result = any(info.status == testedStatus);
endfunction
