% pre-processing samples
if direction == DIR_PLAY
    % only equalizing if non-ones
    if any(find (equalizer ~= 1))
      buffer = buffer .* equalizer;
      buffer = fixClipping(buffer);
    end
end
