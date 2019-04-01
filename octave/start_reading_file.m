if sourceStruct.src == PLAYREC_SRC && ~structContains(sinkStruct, PLAYREC_SINK)
  % no playrec required, stop playrec
  writeLog('DEBUG', 'Clearing-out unused playrec');
  clear playrec;
endif
sourceStruct.src = FILE_SRC;
source 'init_sourcename_status.m';
restartReading = true;      
