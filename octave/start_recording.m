% start/restart recodring samples to memory
% start recording
sinkStruct.sinks = addItemToRow(sinkStruct.sinks, MEMORY_SINK);
% flush old recorded data
recordedData = [];

source 'init_sinknames.m';