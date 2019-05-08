function printStr(str)
  global outBox;
  contents = get(outBox, 'string');
  if (rows(contents) == 0)
    contents = {};
  endif
  contents(end + 1) = str;
  set(outBox, 'string', contents);
endfunction
