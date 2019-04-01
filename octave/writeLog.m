% writing to global logPath levels >= global MIN_LOG_LEVEL.
% logPath - either string with path, or integer with stdout/stderr file descriptor
function writeLog(level, msg, varargin)
  persistent LEVELS = {'ERROR', 'WARN', 'INFO', 'DEBUG'};  
  persistent TO_SECS = 3600*24;
  
  global MIN_LOG_LEVEL;
  global logPath;
  
  %tic();
  if find(strcmp(LEVELS, MIN_LOG_LEVEL), 1) >= find(strcmp(LEVELS, level), 1)
    % will log
    if nargin() > 2
      % formatting message
      msg = sprintf(msg, varargin{:});
    end
    
    stack = dbstack(1)(1);
    % Returns a formatted iso8601 datetime without timezone
    line = sprintf('%s %f [%s:%d] %s', level, now() * TO_SECS, stack.name, stack.line, msg);
    if isnumeric(logPath)
      fid = logPath;      
    else
      fid = fopen(logPath, 'a');
    endif
    
    fdisp(fid, line);
    
    if ~isnumeric(logPath)
      fclose(fid);
    end
  endif
  %toc()
endfunction
