% converting vector of ampls to string without commas
function str = mat2strForCmd(mat)
  str = '[';
  for rowID = 1:rows(mat);
    if rowID > 1
      str = [str ';'];
    end
    row = mat(rowID, :);
    for colID = 1:columns(row)
      if colID > 1
        str = [str ','];
      end
      item = row(colID);
      % 10 decimal places precision
      itemStr = num2str(item, 10);
      str = [str itemStr];
    end
  end
  str = [str ']'];
end

%!test
%! mat = [1, 2; 3, 4 + 5i];
%! expected = '[1,2;3,4+5i]';
%! assert(mat2strForCmd(mat), expected);