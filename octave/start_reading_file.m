if sourceStruct.src == PLAYREC_SRC && ~any(sinkStruct.sinks == PLAYREC_SINK)
  % no playrec required, stop playrec
  printf('Clearing not used playrec\n');
  clear playrec;
endif
sourceStruct.src = FILE_SRC;
source 'init_sourcename_status.m';
restartReading = true;      