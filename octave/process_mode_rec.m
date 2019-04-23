% processing samples for current mode - rec side
switch chMode
  case MODE_DUAL
    % only equalizing if non-ones
    if any(find (equalizer != 1))
      buffer = buffer .* equalizer;
      buffer = fixClipping(buffer);
    endif
    
  case MODE_SINGLE
    % only equalizing if non-ones
    if any(find (equalizer != 1))
      buffer = buffer .* equalizer;
    endif
    % KEEP_CHANNEL_ID = equalized KEEP_CHANNEL_ID - equalized the other channel, distributed to both channels    
    subtractedChannelID = getTheOtherChannelID(KEEP_CHANNEL_ID);
    finalSamples = buffer(:, KEEP_CHANNEL_ID) - buffer(:, subtractedChannelID);
    finalSamples = fixClipping(finalSamples);
    % both channels have final samples
    buffer = repmat(finalSamples, 1, 2);

  case MODE_BAL
    % equalizing, balancing
    % only equalizing if non-ones
    if any(find (equalizer != 1))
      buffer = buffer .* equalizer;
    endif        
    % inverted channel
    invChannelID = getTheOtherChannelID(KEEP_CHANNEL_ID);
    % should not clip, but if equalizer too aggressive...
    finalSamples = (buffer(:, KEEP_CHANNEL_ID) - buffer(:, invChannelID))/2;
    finalSamples = fixClipping(finalSamples);
    % both channels have final samples
    buffer = repmat(finalSamples, 1, 2);
    
endswitch