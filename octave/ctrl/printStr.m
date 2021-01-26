function printStr(msg, varargin)
  global outBox;
  contents = get(outBox, 'string');
  if (rows(contents) == 0)
    contents = {};
  end
  if nargin() > 1
    % formatting message
    msg = sprintf(msg, varargin{:});
  end
  writeLog('DEBUG', 'OutBox message: %s', msg);
  % prepending at the beginning to avoid having to scroll to end manually
  contents = [msg; contents];
  set(outBox, 'string', contents);
end
