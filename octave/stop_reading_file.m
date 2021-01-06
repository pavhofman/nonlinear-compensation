sourceStruct.file = NA;
if exist('playRecConfig', 'var')
  % playrec configured, reading from soundcard
  sourceStruct.src = PLAYREC_SRC;
else
  % no reading
  sourceStruct.src = NA;
end

sourceStruct.filePos = NA;
sourceStruct.fileLength = NA;

source 'restart_chain.m';
source 'init_sourcename_status.m';

