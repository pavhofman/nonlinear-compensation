% post-processing samples for current mode - rec side
if direction == DIR_REC
  switch chMode
    case MODE_DUAL
      % only equalizing if non-ones
      if any(find (equalizer ~= 1))
        buffer = buffer .* equalizer;
        buffer = fixClipping(buffer);
      endif

    case MODE_SINGLE
      % both channels same samples
      subtractedChannelID = getTheOtherChannelID(KEEP_CHANNEL_ID);
      buffer(:, subtractedChannelID) = buffer(:, KEEP_CHANNEL_ID);

    case MODE_BAL
      % equalizing, balancing
      % only equalizing if non-ones
      if any(find (equalizer ~= 1))
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
endif