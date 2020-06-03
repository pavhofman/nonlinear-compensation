% killing process PLAY or REC
function clbkKillProcess(src, data, direction)
  global DIR_PLAY;

  if direction == DIR_PLAY
    global playInfo;
    pid = playInfo.pid;
  else
    global recInfo;
    pid = recInfo.pid;
  endif
  % TERM signal
  kill(pid, 15);
endfunction
