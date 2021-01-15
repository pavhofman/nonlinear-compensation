% pre-processing samples for current mode
if direction == DIR_PLAY
  switch chMode
    case {MODE_DUAL_SE, MODE_DUAL_BAL}
      % only equalizing if non-ones
      if any(find (equalizer ~= 1))
        buffer = buffer .* equalizer;
        buffer = fixClipping(buffer);
      end

    case MODE_SINGLE
      % zeroing the other of KEEP_CHANNEL_ID
      zeroChannelID = getTheOtherChannelID(KEEP_CHANNEL_ID);
      buffer(:, zeroChannelID) = 0;

    case MODE_VIRT_BAL
      % equalizing, balancing
      % inverted channel
      invChannelID = getTheOtherChannelID(KEEP_CHANNEL_ID);
      % inverting KEEP_CHANNEL samples to invChannelID
      buffer(:, invChannelID) = -1 * buffer(:, KEEP_CHANNEL_ID);
      % only equalizing if non-ones
      if any(find (equalizer ~= 1))
        buffer = buffer .* equalizer;
        buffer = fixClipping(buffer);
      end
  endswitch
else
  % DIR_REC
  switch chMode
    case MODE_SINGLE
      % only equalizing if non-ones
      if any(find (equalizer ~= 1))
        buffer = buffer .* equalizer;
      end
      % KEEP_CHANNEL_ID = equalized KEEP_CHANNEL_ID - equalized the other channel
      subtractedChannelID = getTheOtherChannelID(KEEP_CHANNEL_ID);
      finalSamples = buffer(:, KEEP_CHANNEL_ID) - buffer(:, subtractedChannelID);
      finalSamples = fixClipping(finalSamples);
      buffer(:, KEEP_CHANNEL_ID) = finalSamples;
      % the other channel has zeros - no need to calibrate/compensate
      buffer(:, subtractedChannelID) = 0;
  endswitch
end
