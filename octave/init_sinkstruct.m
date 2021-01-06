global sinkStruct;
sinkStruct = struct();
if exist('sink', 'var')
  sinkStruct = addFieldToStruct(sinkStruct, sink);
end
% init sinkNames
source 'init_sinknames.m';
