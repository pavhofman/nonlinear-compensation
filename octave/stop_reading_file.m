sourceFile = NA;
if exist('playRecConfig', 'var')
  fromSource = PLAYREC_SRC;  
else
  fromSource = NA;
endif

source 'restart_chain.m';
source 'init_sourcename_status.m';

