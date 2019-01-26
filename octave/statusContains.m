function result = statusContains(testedStatus)
  global status;
  result = any(status == testedStatus);
endfunction
