global sourceStruct = struct();
sourceStruct.file = '';
% default - no source
sourceStruct.src = src;
sourceStruct.name = '';
% current read position (secs) in the file if sourced from file
sourceStruct.filePos = NA;
% source file length (if applicable)
sourceStruct.fileLength = NA;

% init sourcenames and status
source 'init_sourcename_status.m';
