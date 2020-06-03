% Returns path to file with file with stored variable mainDevID for the given direction
% The file is communicating current main device ID to the other side.
function filename = getDevIDFilepath(direction)
  global commDir;
  global DIR_PLAY;

  if direction == DIR_PLAY
    filename = getFilePath('play_main_dev_id.dat', commDir);
  else
    filename = getFilePath('rec_main_dev_id.dat', commDir);
  endif
endfunction