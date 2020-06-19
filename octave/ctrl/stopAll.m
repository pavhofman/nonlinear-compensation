% stopping all cleansine processes started from the start.sh script
function stopAll()
  % only when started with 'all' arg
  if any(strcmp(argv(), 'all'))
    % killing the parent process
    kill(getppid(), 15)
  endif
endfunction
