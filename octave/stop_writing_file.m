sinkStruct.file = '';
% removing from sinks
sinkStruct.sinks(sinkStruct.sinks == FILE_SINK) = [];

closeSinkFile = true;

source 'init_sinknames.m';

