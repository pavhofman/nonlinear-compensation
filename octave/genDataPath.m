function path = genDataPath(filename)
  global dataDir;
  path = [dataDir filesep() filename];
endfunction