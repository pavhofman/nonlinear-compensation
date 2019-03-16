sourceStruct.file = NA;
if exist('playRecConfig', 'var')
  sourceStruct.src = PLAYREC_SRC;  
else
  sourceStruct.src = NA;
endif

source 'restart_chain.m';
source 'init_sourcename_status.m';

