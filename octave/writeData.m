% writing to fileaudio
function writeData(buffer, fs, sinkFile, closeFile, keepWriting)
  persistent contents = [];
  persistent currentFile = '';
  
  if closeFile && ~isempty(currentFile) && ~isempty(contents)
    % writing existing data to known file
    audiowrite(currentFile, contents, fs, 'BitsPerSample', 24);
    printf('Written %d samples to %s, closed\n', rows(contents), currentFile);
    % flushing previous values
    currentFile = '';
    contents = [];
  endif
  
  if keepWriting
    currentFile = sinkFile;
    contents = [contents; buffer];
  endif
endfunction
