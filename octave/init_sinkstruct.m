global sinkStruct = struct();
sinkStruct.file = '';
% default - no sinks
sinkStruct.sinks = sinks;
sinkStruct.names = cell();
% current write position (in secs) in sinkFile (not stored, only in memory)
sinkStruct.filePos = NA;


% init sinkNames
source 'init_sinknames.m';
