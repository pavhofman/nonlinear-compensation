% post-processing samples - rec side
if direction == DIR_REC
    % only equalizing if non-ones
    if any(find (equalizer ~= 1))
      buffer = buffer .* equalizer;
      buffer = fixClipping(buffer);
    end
end