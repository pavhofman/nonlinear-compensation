sinkStruct.file = '';
% removing from sinks
sinkStruct.sinks(sinkStruct.sinks == MEMORY_SINK) = [];
recordedData = [];
sinkStruct.recLength = 0;
source 'init_sinknames.m';

