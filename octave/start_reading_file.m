if sourceStruct.src == PLAYREC_SRC && ~structContains(sinkStruct, PLAYREC_SINK)
  % no playrec required, stop playrec
  writeLog('DEBUG', 'Clearing-out unused playrec');
  clear playrec;
end
sourceStruct.src = FILE_SRC;
source 'restart_chain.m';
source 'init_sourcename_status.m';