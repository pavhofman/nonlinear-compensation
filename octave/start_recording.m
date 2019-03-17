% start/restart recodring samples to memory
% start recording
sinkStruct = addFieldToStruct(sinkStruct, MEMORY_SINK);
% flush old recorded data
recordedData = [];

source 'init_sinknames.m';