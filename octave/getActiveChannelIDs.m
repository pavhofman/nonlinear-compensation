% generates array of active channel IDs - all channels from 1 to channelCnt, with inactive skipped
function channelIDs = getActiveChannelIDs(chMode, channelCnt)
  global MODE_SINGLE;
  channelIDs = 1:channelCnt;
  if chMode == MODE_SINGLE
    % removing the inactive channel
    global KEEP_CHANNEL_ID;
    channelIDs(getTheOtherChannelID(KEEP_CHANNEL_ID)) = [];
  end
end