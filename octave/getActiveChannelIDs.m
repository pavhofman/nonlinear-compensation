% generates array of active channel IDs - all channels from 1 to channelCnt
% no longer skipping inactive channels
function channelIDs = getActiveChannelIDs(chMode, channelCnt)
  channelIDs = 1:channelCnt;
end