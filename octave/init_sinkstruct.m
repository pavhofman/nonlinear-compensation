global sinkStruct = struct();
sinkStruct.file = '';
% default - no sinks
sinkStruct.sinks = sinks;
sinkStruct.names = cell();
% current length or recorded data (in secs)
sinkStruct.recLength = NA;


% init sinkNames
source 'init_sinknames.m';
