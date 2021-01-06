function filename = getBasename(filePath)
  [dir, name, ext] = fileparts(filePath);
  filename = [name ext];
end