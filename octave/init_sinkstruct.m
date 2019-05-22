global sinkStruct;
sinkStruct = struct();
if exist('sink', 'var')
  sinkStruct = addFieldToStruct(sinkStruct, sink);
endif
% init sinkNames
source 'init_sinknames.m';
