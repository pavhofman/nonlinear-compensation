% processing samples for current mode - playback side
switch chMode
  case MODE_DUAL
    % only equalizing if non-ones
    if any(find (equalizer != 1))
      buffer = buffer .* equalizer;
      buffer = fixClipping(buffer);
    endif
    
  case MODE_SINGLE
    % zeroing the other of KEEP_CHANNEL_ID
    zeroChannelID = getTheOtherChannelID(KEEP_CHANNEL_ID);
    buffer(:, zeroChannelID) = 0;

  case MODE_BAL
    % equalizing, balancing
    % inverted channel
    invChannelID = getTheOtherChannelID(KEEP_CHANNEL_ID);
    % inverting KEEP_CHANNEL samples to invChannelID
    buffer(:, invChannelID) = -1 * buffer(:, KEEP_CHANNEL_ID);
    % only equalizing if non-ones
    if any(find (equalizer != 1))
      buffer = buffer .* equalizer;
      buffer = fixClipping(buffer);      
    endif

endswitch