function printStr(msg, varargin)
  global outBox;
  contents = get(outBox, 'string');
  if (rows(contents) == 0)
    contents = {};
  endif
  if nargin() > 1
    % formatting message
    msg = sprintf(msg, varargin{:});
  end

  contents(end + 1) = msg;
  set(outBox, 'string', contents);
endfunction
